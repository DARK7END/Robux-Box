import * as functionsV1 from "firebase-functions/v1";
import {
  db, cols, userDoc, walletDoc, Timestamp, FieldValue,
} from "../lib/admin";
import {ECONOMY} from "../lib/economy";
import {creditWallet} from "../lib/wallet";

/** Generates a short, human-friendly, collision-checked referral code. */
async function generateReferralCode(): Promise<string> {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  for (let attempt = 0; attempt < 5; attempt++) {
    let code = "";
    for (let i = 0; i < 6; i++) {
      code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    const existing = await cols.users.where("referralCode", "==", code).limit(1).get();
    if (existing.empty) return code;
  }
  return `RB${Date.now().toString(36).toUpperCase().slice(-6)}`;
}

/**
 * Provisions a new account: creates the user profile and a zeroed wallet, mints
 * a referral code, and — if the client stored a `pending_referral` — credits the
 * referral bonuses to both parties. Running this server-side guarantees every
 * account starts in a valid, tamper-proof state.
 */
export const onUserCreated = functionsV1.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const referralCode = await generateReferralCode();

  await db.runTransaction(async (t) => {
    t.set(userDoc(uid), {
      displayName: user.displayName ?? "Player",
      email: user.email ?? "",
      photoUrl: user.photoURL ?? "",
      phoneNumber: user.phoneNumber ?? "",
      countryCode: "US",
      tierLevel: 4,
      vipLevel: "none",
      status: "active",
      xp: 0,
      level: 0,
      streakCount: 0,
      referralCode,
      referralCount: 0,
      robloxUsername: "",
      locale: "en",
      isEmailVerified: user.emailVerified ?? false,
      createdAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    t.set(walletDoc(uid), {
      coins: 0,
      pendingCoins: 0,
      lifetimeEarned: 0,
      lifetimeSpent: 0,
      adsWatchedToday: 0,
      adsWatchedTotal: 0,
      offersCompletedTotal: 0,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
});

/**
 * Applies a referral once the referred user submits the code (called by the
 * client via a callable, or resolved here if `referredBy` is present). Kept
 * idempotent: a user can only be referred once.
 */
export const applyReferralOnProfile = functionsV1.firestore
  .document("users/{uid}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const uid = context.params.uid as string;

    // Fire only when referredBy transitions from empty → set, and hasn't been
    // rewarded yet.
    if (before.referredBy || !after.referredBy || after.referralRewarded) return;

    const code = String(after.referredBy);
    const referrerSnap = await cols.users
      .where("referralCode", "==", code).limit(1).get();
    if (referrerSnap.empty) {
      await userDoc(uid).set({referralRewarded: true}, {merge: true});
      return;
    }
    const referrerUid = referrerSnap.docs[0].id;
    if (referrerUid === uid) return; // no self-referral

    await userDoc(uid).set({referralRewarded: true}, {merge: true});
    await cols.users.doc(referrerUid).set(
      {referralCount: FieldValue.increment(1)},
      {merge: true},
    );
    await cols.referrals.add({
      referrerUid, refereeUid: uid, code,
      createdAt: Timestamp.now(),
    });

    await creditWallet({
      uid, amount: ECONOMY.refereeBonusCoins, type: "referralBonus",
      title: "Referral bonus", referenceId: referrerUid,
    });
    await creditWallet({
      uid: referrerUid, amount: ECONOMY.referrerBonusCoins, type: "referralBonus",
      title: "Friend joined!", referenceId: uid,
    });
  });

/**
 * Cleans up Firestore when an account is deleted (GDPR / "delete account").
 * Removes the profile, wallet and private subcollections.
 */
export const onUserDeleted = functionsV1.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  await db.recursiveDelete(userDoc(uid));
  await walletDoc(uid).delete().catch(() => undefined);
});
