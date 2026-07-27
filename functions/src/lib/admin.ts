import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {getMessaging} from "firebase-admin/messaging";

// Initialise the Admin SDK exactly once for the whole functions codebase.
initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();
export {FieldValue, Timestamp};

// Ignore undefined properties so partial updates are ergonomic.
db.settings({ignoreUndefinedProperties: true});

// Collection references, mirroring `lib/core/constants/firestore_paths.dart`.
export const cols = {
  users: db.collection("users"),
  wallets: db.collection("wallets"),
  transactions: db.collection("transactions"),
  offers: db.collection("offers"),
  offerCompletions: db.collection("offer_completions"),
  rewards: db.collection("rewards"),
  redemptions: db.collection("redemptions"),
  leaderboards: db.collection("leaderboards"),
  promocodes: db.collection("promocodes"),
  reports: db.collection("reports"),
  referrals: db.collection("referrals"),
  adImpressions: db.collection("ad_impressions"),
  fraudFlags: db.collection("fraud_flags"),
  auditLogs: db.collection("audit_logs"),
  config: db.collection("config"),
  geoTiers: db.collection("geo_tiers"),
};

export const userDoc = (uid: string) => cols.users.doc(uid);
export const walletDoc = (uid: string) => cols.wallets.doc(uid);
