import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  cols, userDoc, Timestamp, FieldValue,
} from "../lib/admin";
import {debitWallet, refundPending, clearPending} from "../lib/wallet";
import {requireAuth, requireAdmin, rateLimit} from "../lib/security";
import {sendUserNotification, notifyAdmins} from "../lib/notify";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

/**
 * Submits a redemption. Atomically validates the reward, holds the coins
 * (moving them to pendingCoins) and creates a `pending` redemption doc. The hold
 * is what prevents a user from spending the same coins twice while a request is
 * under review.
 */
export const requestRedemption = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const rewardId = String(req.data?.rewardId ?? "");
  const deliveryTarget = String(req.data?.deliveryTarget ?? "").trim();
  if (!rewardId || !deliveryTarget) {
    throw new HttpsError("invalid-argument", "Missing reward or delivery target.");
  }
  await rateLimit(uid, "redeem", 10, 3600);

  const rewardSnap = await cols.rewards.doc(rewardId).get();
  if (!rewardSnap.exists) throw new HttpsError("not-found", "Reward not found.");
  const reward = rewardSnap.data()!;
  if (reward.isActive === false) {
    throw new HttpsError("failed-precondition", "Reward is unavailable.");
  }
  const coinCost = (reward.coinCost as number) ?? 0;

  // Stock check + decrement (unlimited when stock is -1/absent).
  const stock = (reward.stock as number | undefined);
  if (typeof stock === "number" && stock === 0) {
    throw new HttpsError("failed-precondition", "Reward is out of stock.");
  }

  const uSnap = await userDoc(uid).get();
  const user = uSnap.data() ?? {};
  const minVip = (reward.minVipLevel as number) ?? 0;
  const vipRank = ["none", "bronze", "silver", "gold", "diamond"]
    .indexOf(String(user.vipLevel ?? "none"));
  if (vipRank < minVip) {
    throw new HttpsError("permission-denied", "Requires a higher VIP level.");
  }

  // Hold the coins.
  await debitWallet({
    uid,
    amount: coinCost,
    type: "redemption",
    title: `Redeem: ${reward.title ?? "Reward"}`,
    referenceId: rewardId,
    toPending: true,
  });

  const redemptionRef = cols.redemptions.doc();
  await redemptionRef.set({
    uid,
    rewardId,
    kind: reward.kind ?? "robux",
    title: reward.title ?? "",
    coinCost,
    faceValue: reward.faceValue ?? 0,
    currency: reward.currency ?? "USD",
    provider: reward.provider ?? "manual",
    status: "pending",
    deliveryTarget,
    deliveredCode: "",
    rejectionReason: "",
    createdAt: Timestamp.now(),
    processedAt: null,
    processedBy: "",
  });

  if (typeof stock === "number" && stock > 0) {
    await cols.rewards.doc(rewardId).update({stock: FieldValue.increment(-1)});
  }

  await sendUserNotification(uid, {
    type: "redemption",
    title: "Redemption received",
    body: `Your request for ${reward.title} is under review.`,
    deeplink: "/redemptions",
  });

  await notifyAdmins(
    `New redemption request: ${reward.title}`,
    `A new redemption request needs fulfilment.\n\n` +
    `Reward: ${reward.title}\n` +
    `Cost: ${coinCost} coins\n` +
    `Delivery email: ${deliveryTarget}\n` +
    `Redemption ID: ${redemptionRef.id}\n\n` +
    `Open the Robux Box app → Admin → Withdraw Requests to approve it and ` +
    `deliver the gift-card code (in the app, or by replying to the user's ` +
    `email above).`,
  );

  return {redemptionId: redemptionRef.id};
});

/** Lets a user cancel their own still-pending redemption; refunds the hold. */
export const cancelRedemption = onCall(opts, async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.redemptionId ?? "");
  const ref = cols.redemptions.doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Redemption not found.");
  const r = snap.data()!;
  if (r.uid !== uid) throw new HttpsError("permission-denied", "Not your redemption.");
  if (r.status !== "pending") {
    throw new HttpsError("failed-precondition", "Only pending redemptions can be cancelled.");
  }
  await ref.update({
    status: "cancelled",
    processedAt: Timestamp.now(),
    processedBy: uid,
  });
  await refundPending(uid, (r.coinCost as number) ?? 0, id);
  return {ok: true};
});

/**
 * Admin action to approve/reject/mark-paid a redemption. Rejection refunds the
 * hold; paying clears it and stores the delivered code.
 */
export const processRedemption = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const id = String(req.data?.redemptionId ?? "");
  const action = String(req.data?.action ?? ""); // approve | reject | paid
  const code = String(req.data?.code ?? "");
  const reason = String(req.data?.reason ?? "");

  const ref = cols.redemptions.doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Redemption not found.");
  const r = snap.data()!;
  const uid = r.uid as string;
  const cost = (r.coinCost as number) ?? 0;

  switch (action) {
    case "approve":
      await ref.update({
        status: "approved", processedAt: Timestamp.now(), processedBy: adminUid,
      });
      await sendUserNotification(uid, {
        type: "redemption", title: "Redemption approved",
        body: `${r.title} is being delivered.`, deeplink: "/redemptions",
      });
      break;
    case "paid":
      await ref.update({
        status: "paid", deliveredCode: code,
        processedAt: Timestamp.now(), processedBy: adminUid,
      });
      await clearPending(uid, cost);
      await sendUserNotification(uid, {
        type: "redemption", title: "Reward delivered 🎉",
        body: `Your ${r.title} is ready. Tap to view.`, deeplink: "/redemptions",
      });
      break;
    case "reject":
      await ref.update({
        status: "rejected", rejectionReason: reason || "Rejected",
        processedAt: Timestamp.now(), processedBy: adminUid,
      });
      await refundPending(uid, cost, id);
      await sendUserNotification(uid, {
        type: "redemption", title: "Redemption declined",
        body: reason || "Your coins have been refunded.", deeplink: "/redemptions",
      });
      break;
    default:
      throw new HttpsError("invalid-argument", "Unknown action.");
  }
  await cols.auditLogs.add({
    actor: adminUid, action: `redemption_${action}`, target: id,
    createdAt: Timestamp.now(),
  });
  return {ok: true};
});
