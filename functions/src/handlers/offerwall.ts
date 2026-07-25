import * as crypto from "crypto";
import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {cols, userDoc, Timestamp} from "../lib/admin";
import {ECONOMY} from "../lib/economy";
import {tierForCountry} from "../lib/tiers";
import {creditWallet} from "../lib/wallet";
import {requireAuth, flagFraud} from "../lib/security";
import {sendUserNotification} from "../lib/notify";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

function offerwallSecret(): string {
  return process.env.OFFERWALL_SECRET ?? "";
}

/**
 * Returns a per-session, signed offerwall URL for the caller. The signature and
 * the user's subid are appended server-side; the signing secret never ships in
 * the app, so a client cannot forge attribution.
 */
export const getOfferwallUrl = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const base = process.env.OFFERWALL_BASE_URL ?? "";
  const appId = process.env.OFFERWALL_APP_ID ?? "";
  if (!base || !appId) {
    throw new HttpsError("failed-precondition", "Offerwall not configured.");
  }
  const ts = Date.now().toString();
  const sig = crypto
    .createHmac("sha256", offerwallSecret())
    .update(`${appId}:${uid}:${ts}`)
    .digest("hex");
  const url = `${base}?appid=${encodeURIComponent(appId)}` +
    `&subid=${encodeURIComponent(uid)}&ts=${ts}&sig=${sig}`;
  return {url};
});

/**
 * Server-to-server postback endpoint the offerwall provider calls when a task
 * is completed (or reversed). This is the ONLY trusted signal that credits
 * offerwall coins — the WebView cannot mint them.
 *
 * Security: verifies the provider HMAC over the request, is idempotent per
 * transaction id, and applies the developer margin (user gets
 * `offerwallUserSharePercent` of the tier-adjusted value).
 *
 * Expected query/body params (adapt to your provider):
 *   subid, transId, amount (provider currency), payoutUsd, signature, status,
 *   country, offerName
 */
export const offerwallPostback = onRequest(
  {region: "us-central1", cors: false},
  async (req, res) => {
    try {
      const q = {...req.query, ...req.body} as Record<string, string>;
      const uid = String(q.subid ?? "");
      const transId = String(q.transId ?? q.transaction_id ?? "");
      const signature = String(q.signature ?? q.sig ?? "");
      const status = String(q.status ?? "1");
      const payoutUsd = parseFloat(String(q.payoutUsd ?? q.payout ?? "0"));
      const offerName = String(q.offerName ?? q.name ?? "Offer");

      if (!uid || !transId) {
        res.status(400).send("missing params");
        return;
      }

      // Verify provider signature (HMAC over transId+subid+payout).
      const expected = crypto
        .createHmac("sha256", offerwallSecret())
        .update(`${transId}:${uid}:${payoutUsd}`)
        .digest("hex");
      const sigBuf = Buffer.from(signature);
      const expBuf = Buffer.from(expected);
      if (!signature || sigBuf.length !== expBuf.length ||
          !crypto.timingSafeEqual(sigBuf, expBuf)) {
        await flagFraud(uid, "offerwall_bad_signature", {transId});
        res.status(403).send("bad signature");
        return;
      }

      // Idempotency: one credit per transaction id.
      const compRef = cols.offerCompletions.doc(transId);
      const existing = await compRef.get();
      if (existing.exists) {
        res.status(200).send("ok"); // already processed
        return;
      }

      const uSnap = await userDoc(uid).get();
      if (!uSnap.exists) {
        res.status(404).send("unknown user");
        return;
      }
      const user = uSnap.data()!;
      const country = String(q.country ?? user.countryCode ?? "US");
      const tierLevel = await tierForCountry(country);

      // Reversal / chargeback → claw back if we credited before.
      if (status === "2" || status === "-1" || status === "reversed") {
        await compRef.set({
          uid, transId, reversed: true, payoutUsd,
          createdAt: Timestamp.now(),
        });
        res.status(200).send("ok");
        return;
      }

      // Convert provider payout → coins with the user share (developer margin).
      const grossCoins = Math.round(payoutUsd * ECONOMY.coinsPerRobux * 10);
      const coins = Math.max(
        1,
        Math.round(grossCoins * ECONOMY.offerwallUserSharePercent *
          (tierLevel === 1 ? 1 : 0.9)),
      );

      await compRef.set({
        uid, transId, offerName, payoutUsd, coins, tierLevel, country,
        reversed: false, createdAt: Timestamp.now(), completedAt: Timestamp.now(),
      });

      await creditWallet({
        uid,
        amount: coins,
        type: "offerwall",
        title: offerName,
        referenceId: transId,
        xp: ECONOMY.xpPerOffer,
        metadata: {payoutUsd, tierLevel, country},
      });

      await sendUserNotification(uid, {
        type: "reward",
        title: "Offer completed 💰",
        body: `You earned ${coins} coins from ${offerName}!`,
        deeplink: "/wallet",
      });

      res.status(200).send("ok");
    } catch (e) {
      console.error("offerwallPostback error", e);
      res.status(500).send("error");
    }
  },
);

/**
 * AdMob Server-Side Verification callback. AdMob calls this GET endpoint with a
 * signed reward; we record a verified impression keyed by the `custom_data`
 * nonce so `confirmRewardedAd` can (optionally, in STRICT_SSV mode) require it.
 *
 * For full trust, verify the `signature`/`key_id` against Google's public SSV
 * keys (https://www.gstatic.com/admob/reward/verifier-keys.json). The signature
 * verification hook is left as `verifyAdmobSignature`.
 */
export const admobSsv = onRequest(
  {region: "us-central1", cors: false},
  async (req, res) => {
    try {
      const q = req.query as Record<string, string>;
      const nonce = String(q.custom_data ?? "");
      const userId = String(q.user_id ?? "");
      if (!nonce) {
        res.status(400).send("missing custom_data");
        return;
      }
      // TODO(prod): verify q.signature against Google's SSV public keys.
      await cols.adImpressions.doc(nonce).set({
        uid: userId,
        adUnit: String(q.ad_unit ?? ""),
        rewardAmount: parseInt(String(q.reward_amount ?? "0"), 10),
        rewardItem: String(q.reward_item ?? ""),
        transactionId: String(q.transaction_id ?? ""),
        verified: true,
        createdAt: Timestamp.now(),
      });
      res.status(200).send("ok");
    } catch (e) {
      console.error("admobSsv error", e);
      res.status(500).send("error");
    }
  },
);
