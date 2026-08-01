import {onCall, HttpsError} from "firebase-functions/v2/https";
import {cols, userDoc, Timestamp} from "../lib/admin";
import {ECONOMY, effectiveVipLevel} from "../lib/economy";
import {debitWallet} from "../lib/wallet";
import {requireAuth} from "../lib/security";
import {sendUserNotification} from "../lib/notify";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

const COIN_PURCHASABLE_LEVELS = ["bronze", "silver"];
const VIP_LEVELS = ["bronze", "silver", "gold", "diamond"];

function label(level: string): string {
  return level.charAt(0).toUpperCase() + level.slice(1);
}

/** New `vipExpiresAt`: extends from the current one if still active on the
 * same tier, otherwise starts a fresh `vipDurationDays` window from now. */
function nextExpiry(
  currentLevel: string,
  currentExpiryMs: number | undefined,
  newLevel: string,
): Timestamp {
  const stillActiveSameTier = currentLevel === newLevel &&
    currentExpiryMs !== undefined && currentExpiryMs > Date.now();
  const base = stillActiveSameTier ? (currentExpiryMs as number) : Date.now();
  return Timestamp.fromMillis(base + ECONOMY.vipDurationDays * 86_400_000);
}

/**
 * Buys or renews Bronze/Silver VIP with coins. Gold and Diamond are
 * real-money-only (see `verifyVipPurchase`) and are rejected here.
 */
export const purchaseVipWithCoins = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const level = String(req.data?.level ?? "");
  const price = ECONOMY.vipCoinPrices[level];
  if (!COIN_PURCHASABLE_LEVELS.includes(level) || !price) {
    throw new HttpsError(
      "invalid-argument",
      "Only Bronze and Silver can be purchased with coins.",
    );
  }

  const uSnap = await userDoc(uid).get();
  const user = uSnap.data() ?? {};
  const currentExpiryMs = (user.vipExpiresAt as Timestamp | undefined)?.toMillis();
  const newExpiry = nextExpiry(effectiveVipLevel(user), currentExpiryMs, level);

  // Debit first: if the user can't afford it, nothing else happens. The
  // small window between this succeeding and the profile write below matches
  // the same non-atomic-but-debit-first pattern requestRedemption uses.
  await debitWallet({
    uid,
    amount: price,
    type: "vipPurchase",
    title: `${label(level)} VIP (${ECONOMY.vipDurationDays} days)`,
    referenceId: level,
  });

  await userDoc(uid).set({vipLevel: level, vipExpiresAt: newExpiry}, {merge: true});
  await sendUserNotification(uid, {
    type: "vip",
    title: "VIP activated ⭐",
    body: `You're now ${level.toUpperCase()} VIP for ${ECONOMY.vipDurationDays} days.`,
    deeplink: "/vip",
  });

  return {ok: true, level, vipExpiresAt: newExpiry.toMillis()};
});

/**
 * Credits VIP after a real-money store purchase (Google Play Billing /
 * StoreKit). This is the ONLY path for Gold/Diamond, and an alternative to
 * `purchaseVipWithCoins` for Bronze/Silver.
 *
 * IMPORTANT: `verifyStorePurchase` below is a stub — see its doc comment.
 * Real verification needs store server credentials this repo does not (and
 * cannot) ship; until they're configured this function safely refuses to
 * credit VIP rather than trusting an unverified client-supplied token. See
 * "VIP subscriptions" in docs/DEPLOYMENT.md for the exact setup steps.
 */
export const verifyVipPurchase = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const level = String(req.data?.level ?? "");
  const platform = String(req.data?.platform ?? ""); // "android" | "ios"
  const productId = String(req.data?.productId ?? "");
  const purchaseToken = String(req.data?.purchaseToken ?? "");
  if (!VIP_LEVELS.includes(level) || !platform || !productId || !purchaseToken) {
    throw new HttpsError("invalid-argument", "Missing purchase details.");
  }

  // Idempotency: a given purchase token can only ever credit VIP once, so a
  // client retry (or a re-delivered purchase-update event) never double-pays.
  const receiptRef = cols.vipPurchases.doc(purchaseToken);
  const already = await receiptRef.get();
  if (already.exists) {
    const data = already.data()!;
    return {
      ok: true,
      level: data.level,
      vipExpiresAt: (data.vipExpiresAt as Timestamp).toMillis(),
      alreadyProcessed: true,
    };
  }

  await verifyStorePurchase({platform, productId, purchaseToken});

  const uSnap = await userDoc(uid).get();
  const user = uSnap.data() ?? {};
  const currentExpiryMs = (user.vipExpiresAt as Timestamp | undefined)?.toMillis();
  const newExpiry = nextExpiry(effectiveVipLevel(user), currentExpiryMs, level);

  await receiptRef.set({
    uid, level, platform, productId,
    vipExpiresAt: newExpiry,
    verifiedAt: Timestamp.now(),
  });
  await userDoc(uid).set({vipLevel: level, vipExpiresAt: newExpiry}, {merge: true});
  await sendUserNotification(uid, {
    type: "vip",
    title: "VIP activated ⭐",
    body: `You're now ${level.toUpperCase()} VIP for ${ECONOMY.vipDurationDays} days.`,
    deeplink: "/vip",
  });

  return {ok: true, level, vipExpiresAt: newExpiry.toMillis()};
});

/**
 * Verifies a purchase token/receipt against the store's own server API.
 *
 * TODO(prod) — this must be implemented before real-money VIP purchases can
 * be trusted:
 *   - Android: call the Google Play Developer API
 *     `purchases.subscriptions.get` (package `googleapis`, scope
 *     `androidpublisher`) using a Play Console service-account key, confirm
 *     the subscription is active and `productId` matches, then acknowledge
 *     it (`purchases.subscriptions.acknowledge`) so Google doesn't refund it.
 *   - iOS: call the App Store Server API
 *     (`GET /inApps/v1/subscriptions/{transactionId}`, or verifyReceipt) with
 *     the app's shared secret, and confirm the receipt's `product_id` and
 *     `expires_date`.
 * Both need credentials that live outside this repo (see docs/DEPLOYMENT.md).
 * Until then, this intentionally throws instead of trusting the client.
 */
async function verifyStorePurchase(receipt: {
  platform: string;
  productId: string;
  purchaseToken: string;
}): Promise<void> {
  throw new HttpsError(
    "unimplemented",
    `Store purchase verification isn't configured yet (${receipt.platform} ` +
    `product ${receipt.productId}) — please contact support.`,
  );
}
