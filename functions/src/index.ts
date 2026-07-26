/**
 * Robux Box — Cloud Functions entry point.
 *
 * All business logic that touches the economy runs here with the Admin SDK,
 * which bypasses Firestore security rules. This is the trust boundary: clients
 * can only *request* actions; the server validates and applies them.
 *
 * Grouped exports:
 *   • earn        — rewarded ads, daily reward, promo codes, tier resolution
 *   • redemption  — request/cancel + admin processing
 *   • offerwall   — signed URL (callable) + provider postback / AdMob SSV (HTTP)
 *   • admin       — claims, coin adjustments, status, VIP, promocodes, broadcast
 *   • triggers    — account provisioning/cleanup, referral rewards
 *   • scheduled   — daily reset, leaderboard aggregation, reminder campaigns
 */

// Callable: earning
export {
  beginRewardedAd,
  confirmRewardedAd,
  claimDailyReward,
  redeemPromocode,
  resolveTier,
} from "./handlers/earn";

// Callable: daily games (spin wheel / lucky chest)
export {playDailyGame} from "./handlers/games";

// Callable: redemption
export {
  requestRedemption,
  cancelRedemption,
  processRedemption,
} from "./handlers/redemption";

// Callable + HTTP: offerwall & ads verification
export {
  getOfferwallUrl,
  offerwallPostback,
  admobSsv,
} from "./handlers/offerwall";

// Callable: admin dashboard
export {
  setAdminClaim,
  adjustCoins,
  setAccountStatus,
  setVipLevel,
  upsertPromocode,
  broadcastNotification,
} from "./handlers/admin";

// Auth / Firestore triggers
export {
  onUserCreated,
  applyReferralOnProfile,
  onUserDeleted,
} from "./triggers/auth";

// Scheduled
export {
  resetDailyCounters,
  aggregateLeaderboards,
  dailyReminder,
  rewardReminder,
  vipReminder,
  referralReminder,
} from "./triggers/scheduled";
