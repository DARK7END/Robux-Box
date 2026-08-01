/**
 * Server-authoritative economy constants.
 *
 * These MUST stay in sync with `lib/core/constants/app_constants.dart`. The
 * server is the single source of truth for payouts; the client copy is only for
 * display/estimates. The developer margin is baked into these numbers — the app
 * always earns more from the ad network / offerwall than it pays the user.
 */
export const ECONOMY = {
  coinsPerRobux: 100,

  // Rewarded ads
  baseRewardedAdCoins: 15,
  maxRewardedAdsPerDay: 40,
  rewardedAdCooldownSeconds: 30,

  // Offerwall — user gets this share of the tier-adjusted value; the rest is
  // the developer margin.
  offerwallUserSharePercent: 0.7,

  // Referrals
  referrerBonusCoins: 250,
  refereeBonusCoins: 100,
  referralRevenueSharePercent: 0.05,

  // Daily streak table (day 1..7 then repeats)
  dailyStreakRewards: [25, 40, 60, 90, 130, 180, 300],

  // XP / levels
  levelXpStep: 500,
  xpPerAd: 10,
  xpPerOffer: 25,

  // VIP multipliers
  vipMultipliers: {
    none: 1.0,
    bronze: 1.25,
    silver: 1.5,
    gold: 2.0,
    diamond: 3.0,
  } as Record<string, number>,

  // Raised daily rewarded-ad cap per VIP tier — see AppConstants.vipMaxAdsPerDay.
  vipMaxAdsPerDay: {
    none: 40,
    bronze: 55,
    silver: 70,
    gold: 90,
    diamond: 120,
  } as Record<string, number>,

  // Numeric rank per tier — mirrors AppConstants.vipRank / Reward.minVipLevel.
  vipRankOf: {
    none: 0,
    bronze: 1,
    silver: 2,
    gold: 3,
    diamond: 4,
  } as Record<string, number>,

  // A purchased VIP subscription lasts this many days. Admin-granted VIP
  // (setVipLevel) sets no expiry and stays permanent.
  vipDurationDays: 30,

  // Coin price for a vipDurationDays-long subscription. Gold/Diamond are
  // absent — real-money-only, enforced in purchaseVipWithCoins.
  vipCoinPrices: {bronze: 12000, silver: 30000} as Record<string, number>,

  // Anti-fraud
  nonceTtlSeconds: 600,
  minIntegrityScore: 0.35,
  suspiciousVelocityCoinsPerMinute: 500,
  maxDevicesPerAccount: 3,

  // Daily games — prize (coins) tables with parallel weights. Segment order MUST
  // match the client wheel (`AppConstants.spinWheelPrizes`). Weights favour small
  // prizes so the average payout stays below the ad/offer revenue per user.
  spinPrizes: [25, 50, 10, 100, 250, 15, 500, 75],
  spinWeights: [20, 14, 26, 8, 3, 24, 1, 10],
  chestPrizes: [30, 60, 120, 300],
  chestWeights: [50, 30, 15, 5],
} as const;

/** Weighted random index into a parallel prizes/weights table. */
export function weightedPick(weights: readonly number[]): number {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = Math.random() * total;
  for (let i = 0; i < weights.length; i++) {
    r -= weights[i];
    if (r <= 0) return i;
  }
  return weights.length - 1;
}

/** Geo-tier multipliers keyed by tier level (1..4). */
export const TIER_MULTIPLIERS: Record<number, number> = {
  1: 1.0,
  2: 0.7,
  3: 0.45,
  4: 0.28,
};

/** Level a given XP total corresponds to. */
export function levelForXp(xp: number): number {
  // level n requires cumulative n*(n+1)/2 * step; invert approximately.
  let level = 0;
  let required = 0;
  while (required <= xp) {
    level += 1;
    required += level * ECONOMY.levelXpStep;
  }
  return level - 1;
}

/** Effective earn multiplier for a user given tier + VIP. */
export function earnMultiplier(tierLevel: number, vipLevel: string): number {
  const tier = TIER_MULTIPLIERS[tierLevel] ?? TIER_MULTIPLIERS[4];
  const vip = ECONOMY.vipMultipliers[vipLevel] ?? 1.0;
  return tier * vip;
}

/** The tier-adjusted coins for a rewarded ad. */
export function rewardedAdCoins(tierLevel: number, vipLevel: string): number {
  return Math.max(
    1,
    Math.round(ECONOMY.baseRewardedAdCoins * earnMultiplier(tierLevel, vipLevel)),
  );
}

/**
 * A user's VIP level as stored can be stale for up to a day (the downgrade to
 * `none` runs on the `vipExpiryDowngrade` schedule, not the instant a
 * subscription lapses). Every economic decision must use this instead of the
 * raw `user.vipLevel` field so an expired-but-not-yet-swept subscription never
 * grants a benefit. A null/undefined `vipExpiresAt` means permanent (either
 * `none`, or an admin grant via `setVipLevel`).
 */
export function effectiveVipLevel(user: {
  vipLevel?: string;
  vipExpiresAt?: FirebaseFirestore.Timestamp | null;
}): string {
  const level = user.vipLevel ?? "none";
  if (level === "none") return "none";
  const exp = user.vipExpiresAt;
  if (exp && exp.toMillis() < Date.now()) return "none";
  return level;
}

/** Numeric rank of a VIP level name (`none` = 0 .. `diamond` = 4). */
export function vipRank(vipLevel: string): number {
  return ECONOMY.vipRankOf[vipLevel] ?? 0;
}

/** The daily rewarded-ad cap for a (already-effective) VIP level. */
export function maxAdsPerDay(vipLevel: string): number {
  return ECONOMY.vipMaxAdsPerDay[vipLevel] ?? ECONOMY.maxRewardedAdsPerDay;
}
