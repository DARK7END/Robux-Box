/// Centralised route path + name constants for `go_router`.
///
/// Paths are also used as notification deeplink targets, so keep them stable.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String emailAuth = '/auth/email';
  static const String phoneAuth = '/auth/phone';

  // Shell tabs
  static const String home = '/home';
  static const String earn = '/earn';
  static const String rewards = '/rewards';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Detail routes
  static const String offerwall = '/earn/offerwall';
  static const String wallet = '/wallet';
  static const String transactions = '/wallet/transactions';
  static const String redemptions = '/redemptions';
  static const String redemptionDetail = '/redemptions/:id';
  static const String referrals = '/referrals';
  static const String vip = '/vip';
  static const String achievements = '/achievements';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String setupRoblox = '/setup/roblox';

  static String redemption(String id) => '/redemptions/$id';
}
