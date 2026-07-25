/// Global, non-secret constants shared across the app and mirrored by the
/// Cloud Functions economy (`functions/src/lib/economy.ts`). Any change to the
/// point economy must be made in BOTH places and kept in sync.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Robux Box';
  static const String defaultCurrencySymbol = 'RBX';

  /// Coins → Robux exchange. The developer margin lives in this ratio: the app
  /// earns more per ad/offer than it pays out, keeping the platform profitable
  /// for the developer while still rewarding the user fairly.
  static const int coinsPerRobux = 100; // 100 coins == 1 Robux payout unit

  /// Referral rewards.
  static const int referrerBonusCoins = 250;
  static const int refereeBonusCoins = 100;
  static const double referralRevenueSharePercent = 0.05; // lifetime 5%

  /// Daily streak reward table (index 0 == day 1).
  static const List<int> dailyStreakRewards = [25, 40, 60, 90, 130, 180, 300];

  /// XP required to reach each level is level * levelXpStep.
  static const int levelXpStep = 500;

  /// Rewarded-ad economy (base values in coins, before geo-tier multiplier).
  static const int baseRewardedAdCoins = 15;
  static const int maxRewardedAdsPerDay = 40;
  static const Duration rewardedAdCooldown = Duration(seconds: 30);

  /// Offerwall economy — reward is provider-driven; this is the minimum the app
  /// will credit and the app's cut is enforced server-side.
  static const double offerwallUserSharePercent = 0.70;

  /// VIP tiers unlock multipliers and lower withdrawal minimums.
  static const Map<String, double> vipMultipliers = {
    'none': 1.0,
    'bronze': 1.10,
    'silver': 1.20,
    'gold': 1.35,
    'diamond': 1.50,
  };

  /// Anti-fraud thresholds (client-side pre-checks; authoritative checks run in
  /// Cloud Functions).
  static const int maxDevicesPerAccount = 3;
  static const int suspiciousVelocityCoinsPerMinute = 500;

  static const int leaderboardPageSize = 50;
  static const int transactionsPageSize = 25;
}

/// The four monetisation tiers derived from the user's country. T1 pays the
/// most (high eCPM markets), T4 the least. The multiplier scales every earning.
enum GeoTier {
  t1(1, 1.00, 'T1'),
  t2(2, 0.70, 'T2'),
  t3(3, 0.45, 'T3'),
  t4(4, 0.28, 'T4');

  const GeoTier(this.level, this.multiplier, this.label);

  final int level;
  final double multiplier;
  final String label;

  static GeoTier fromLevel(int level) =>
      GeoTier.values.firstWhere((t) => t.level == level, orElse: () => GeoTier.t4);
}
