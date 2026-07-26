import {onCall, HttpsError} from "firebase-functions/v2/https";
import {auth, db, cols, userDoc, Timestamp} from "../lib/admin";
import {requireAdmin, requireAuth} from "../lib/security";
import {creditWallet, debitWallet} from "../lib/wallet";
import {sendTopic, sendUserNotification} from "../lib/notify";
import {computeAnalytics} from "../lib/analytics";

const opts = {enforceAppCheck: true, region: "us-central1"} as const;

/**
 * Grants/revokes the admin custom claim. Bootstrapping: the very first admin
 * must be set manually (e.g. via a one-off script or the
 * `ADMIN_BOOTSTRAP_EMAIL` env allow-list below), after which existing admins can
 * promote others.
 */
export const setAdminClaim = onCall(opts, async (req) => {
  const callerUid = requireAuth(req);
  const targetEmail = String(req.data?.email ?? "");
  const makeAdmin = req.data?.admin !== false;

  const bootstrap = (process.env.ADMIN_BOOTSTRAP_EMAIL ?? "")
    .split(",").map((e) => e.trim().toLowerCase()).filter(Boolean);
  const callerRecord = await auth.getUser(callerUid);
  const isBootstrap = bootstrap.includes((callerRecord.email ?? "").toLowerCase());

  if (!isBootstrap && req.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admin privileges required.");
  }
  if (!targetEmail) throw new HttpsError("invalid-argument", "Email required.");

  const target = await auth.getUserByEmail(targetEmail);
  await auth.setCustomUserClaims(target.uid, {admin: makeAdmin});
  // Mirror to an `admins` collection so the dashboard can list current admins
  // (custom claims aren't queryable).
  await db.doc(`admins/${target.uid}`).set({
    email: target.email ?? targetEmail,
    displayName: target.displayName ?? "",
    active: makeAdmin,
    grantedBy: callerUid,
    updatedAt: Timestamp.now(),
  }, {merge: true});
  await cols.auditLogs.add({
    actor: callerUid, action: makeAdmin ? "grant_admin" : "revoke_admin",
    target: target.uid, createdAt: Timestamp.now(),
  });
  return {ok: true, uid: target.uid};
});

/** Admin-triggered analytics refresh (also runs hourly on a schedule). */
export const refreshAnalytics = onCall(opts, async (req) => {
  requireAdmin(req);
  const summary = await computeAnalytics();
  return summary;
});

/** Admin credit/debit adjustment with an audit trail. */
export const adjustCoins = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const uid = String(req.data?.uid ?? "");
  const amount = Number(req.data?.amount ?? 0);
  const reason = String(req.data?.reason ?? "Adjustment");
  if (!uid || !Number.isFinite(amount) || amount === 0) {
    throw new HttpsError("invalid-argument", "uid and non-zero amount required.");
  }

  const result = amount > 0 ?
    await creditWallet({
      uid, amount, type: "adjustment", title: reason, referenceId: adminUid,
    }) :
    {newBalance: await debitWallet({
      uid, amount: -amount, type: "adjustment", title: reason,
      referenceId: adminUid,
    })};

  await cols.auditLogs.add({
    actor: adminUid, action: "adjust_coins", target: uid,
    details: {amount, reason}, createdAt: Timestamp.now(),
  });
  return {ok: true, result};
});

/** Sets a user's account moderation status (active/restricted/banned). */
export const setAccountStatus = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const uid = String(req.data?.uid ?? "");
  const status = String(req.data?.status ?? "active");
  if (!["active", "restricted", "banned"].includes(status)) {
    throw new HttpsError("invalid-argument", "Invalid status.");
  }
  await userDoc(uid).set({status}, {merge: true});
  if (status === "banned") {
    await auth.updateUser(uid, {disabled: true}).catch(() => undefined);
  } else {
    await auth.updateUser(uid, {disabled: false}).catch(() => undefined);
  }
  await cols.auditLogs.add({
    actor: adminUid, action: "set_status", target: uid,
    details: {status}, createdAt: Timestamp.now(),
  });
  return {ok: true};
});

/** Sets/updates a user's VIP level (e.g. after a validated store purchase). */
export const setVipLevel = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const uid = String(req.data?.uid ?? "");
  const level = String(req.data?.level ?? "none");
  if (!["none", "bronze", "silver", "gold", "diamond"].includes(level)) {
    throw new HttpsError("invalid-argument", "Invalid VIP level.");
  }
  await userDoc(uid).set({vipLevel: level}, {merge: true});
  await sendUserNotification(uid, {
    type: "vip", title: "VIP updated ⭐",
    body: `You are now ${level.toUpperCase()} VIP.`, deeplink: "/vip",
  });
  await cols.auditLogs.add({
    actor: adminUid, action: "set_vip", target: uid,
    details: {level}, createdAt: Timestamp.now(),
  });
  return {ok: true};
});

/** Creates/updates a promo code from the admin dashboard. */
export const upsertPromocode = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const code = String(req.data?.code ?? "").trim().toUpperCase();
  if (!code) throw new HttpsError("invalid-argument", "Code required.");
  await cols.promocodes.doc(code).set({
    rewardCoins: Number(req.data?.rewardCoins ?? 0),
    maxRedemptions: Number(req.data?.maxRedemptions ?? -1),
    perUserLimit: Number(req.data?.perUserLimit ?? 1),
    isActive: req.data?.isActive !== false,
    expiresAt: req.data?.expiresAt ?
      Timestamp.fromMillis(Number(req.data.expiresAt)) : null,
    updatedBy: adminUid,
    updatedAt: Timestamp.now(),
  }, {merge: true});
  return {ok: true};
});

/** Broadcasts a push + optional in-app notification to a topic. */
export const broadcastNotification = onCall(opts, async (req) => {
  const adminUid = requireAdmin(req);
  const title = String(req.data?.title ?? "");
  const body = String(req.data?.body ?? "");
  const topic = String(req.data?.topic ?? "all");
  const deeplink = String(req.data?.deeplink ?? "");
  if (!title || !body) throw new HttpsError("invalid-argument", "Title and body required.");
  await sendTopic(topic, title, body, deeplink);
  await cols.auditLogs.add({
    actor: adminUid, action: "broadcast", details: {title, topic},
    createdAt: Timestamp.now(),
  });
  return {ok: true};
});
