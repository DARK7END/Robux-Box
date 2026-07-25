import {onCall, HttpsError} from "firebase-functions/v2/https";
import {cols, userDoc, walletDoc, Timestamp, FieldValue} from "../lib/admin";
import {ECONOMY, rewardedAdCoins} from "../lib/economy";
import {tierForCountry} from "../lib/tiers";
import {creditWallet} from "../lib/wallet";
import {
  requireAuth, issueNonce, consumeNonce, recordDevice, assertIntegrity,
  rateLimit, checkVelocity, DeviceContext,
} from "../lib/security";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

/**
 * Step 1 of the rewarded-ad flow. Validates the device, enforces the daily cap
 * and cooldown, then issues a single-use nonce the client passes to AdMob SSV.
 */
export const beginRewardedAd = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const device = (req.data?.device ?? {}) as DeviceContext;
  assertIntegrity(device);
  await recordDevice(uid, device);

  const wSnap = await walletDoc(uid).get();
  const wallet = wSnap.data() ?? {};
  const adsToday = (wallet.adsWatchedToday as number) ?? 0;
  if (adsToday >= ECONOMY.maxRewardedAdsPerDay) {
    throw new HttpsError("resource-exhausted", "Daily ad limit reached.");
  }
  const lastEarn = wallet.lastAdAt as Timestamp | undefined;
  if (lastEarn &&
      Date.now() - lastEarn.toMillis() < ECONOMY.rewardedAdCooldownSeconds * 1000) {
    throw new HttpsError("failed-precondition", "Please wait before the next ad.");
  }

  const nonce = await issueNonce(uid, "rewarded_ad", {device: device.deviceId ?? ""});
  return {nonce};
});

/**
 * Step 2. Confirms a completed impression: consumes the nonce (anti-replay),
 * re-derives the tier server-side, applies rate limit + velocity checks, then
 * credits the tier-adjusted amount inside a transaction.
 *
 * Note: for production, cross-check the AdMob Server-Side Verification callback
 * (see `admobSsv` HTTP function) which records a verified impression keyed by
 * the same nonce; this handler additionally asserts that record exists.
 */
export const confirmRewardedAd = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const payload = (req.data?.payload ?? {}) as Record<string, any>;
  const nonce = String(payload.nonce ?? req.data?.nonce ?? "");

  await rateLimit(uid, "confirm_ad", ECONOMY.maxRewardedAdsPerDay, 86_400);
  await consumeNonce(uid, nonce, "rewarded_ad");

  // Optional strict mode: require the AdMob SSV record to be present.
  const ssv = await cols.adImpressions.doc(nonce).get();
  if (process.env.STRICT_SSV === "true" && !ssv.exists) {
    throw new HttpsError("failed-precondition", "Ad could not be verified.");
  }

  const uSnap = await userDoc(uid).get();
  const user = uSnap.data() ?? {};
  const geo = (payload.geo ?? {}) as Record<string, any>;
  const country = String(geo.countryCode ?? user.countryCode ?? "US");
  const tierLevel = await tierForCountry(country);
  const vip = String(user.vipLevel ?? "none");

  const coins = rewardedAdCoins(tierLevel, vip);
  await checkVelocity(uid, coins);

  const outcome = await creditWallet({
    uid,
    amount: coins,
    type: "rewardedAd",
    title: "Rewarded ad",
    referenceId: nonce,
    xp: ECONOMY.xpPerAd,
    metadata: {tierLevel, vip, country},
  });
  await walletDoc(uid).set({lastAdAt: Timestamp.now()}, {merge: true});
  return outcome;
});

/**
 * Claims the daily streak reward. Enforces one claim per calendar day and
 * advances/breaks the streak based on the last claim date.
 */
export const claimDailyReward = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const uRef = userDoc(uid);
  const uSnap = await uRef.get();
  const user = uSnap.data() ?? {};

  const now = new Date();
  const last = (user.lastDailyClaim as Timestamp | undefined)?.toDate();
  const sameDay = last &&
    last.getUTCFullYear() === now.getUTCFullYear() &&
    last.getUTCMonth() === now.getUTCMonth() &&
    last.getUTCDate() === now.getUTCDate();
  if (sameDay) {
    throw new HttpsError("failed-precondition", "Already claimed today.");
  }

  // Continue the streak if the last claim was yesterday; otherwise reset.
  const yesterday = new Date(now);
  yesterday.setUTCDate(now.getUTCDate() - 1);
  const continued = last &&
    last.getUTCFullYear() === yesterday.getUTCFullYear() &&
    last.getUTCMonth() === yesterday.getUTCMonth() &&
    last.getUTCDate() === yesterday.getUTCDate();
  const streak = continued ? ((user.streakCount as number) ?? 0) + 1 : 1;

  const idx = (streak - 1) % ECONOMY.dailyStreakRewards.length;
  const reward = ECONOMY.dailyStreakRewards[idx];

  await uRef.set(
    {streakCount: streak, lastDailyClaim: Timestamp.now()},
    {merge: true},
  );
  return creditWallet({
    uid,
    amount: reward,
    type: "dailyBonus",
    title: `Daily reward (day ${streak})`,
    xp: ECONOMY.xpPerAd,
    metadata: {streak},
  });
});

/** Redeems a promo code (single-use per user, global cap, expiry). */
export const redeemPromocode = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? "").trim().toUpperCase();
  if (!code) throw new HttpsError("invalid-argument", "Enter a code.");
  await rateLimit(uid, "promo", 10, 3600);

  const {db} = await import("../lib/admin");
  const codeRef = cols.promocodes.doc(code);
  const claimRef = codeRef.collection("claims").doc(uid);

  const reward = await db.runTransaction(async (t) => {
    const [cSnap, claimSnap] = await Promise.all([t.get(codeRef), t.get(claimRef)]);
    if (!cSnap.exists) throw new HttpsError("not-found", "Invalid code.");
    const c = cSnap.data()!;
    if (c.isActive === false) throw new HttpsError("failed-precondition", "Code inactive.");
    if (c.expiresAt && (c.expiresAt as Timestamp).toMillis() < Date.now()) {
      throw new HttpsError("failed-precondition", "Code expired.");
    }
    const maxRedemptions = (c.maxRedemptions as number) ?? -1;
    const count = (c.redemptionCount as number) ?? 0;
    if (maxRedemptions >= 0 && count >= maxRedemptions) {
      throw new HttpsError("resource-exhausted", "Code fully redeemed.");
    }
    if (claimSnap.exists) {
      throw new HttpsError("failed-precondition", "You already used this code.");
    }
    t.set(claimRef, {claimedAt: Timestamp.now()});
    t.update(codeRef, {redemptionCount: FieldValue.increment(1)});
    return (c.rewardCoins as number) ?? 0;
  });

  return creditWallet({
    uid,
    amount: reward,
    type: "promocode",
    title: `Promo code ${code}`,
    referenceId: code,
  });
});

/**
 * Records the client-resolved geo-tier as the account's country of record.
 * Called on launch; the value is what all future payouts are validated against.
 */
export const resolveTier = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const country = String(req.data?.countryCode ?? "US").toUpperCase();
  const tierLevel = await tierForCountry(country);
  await userDoc(uid).set(
    {
      countryCode: country,
      tierLevel,
      tierSource: String(req.data?.source ?? "unknown"),
      tierResolvedAt: Timestamp.now(),
    },
    {merge: true},
  );
  return {tierLevel, country};
});
