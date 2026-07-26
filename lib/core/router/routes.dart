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

  // Shell tabs: Home · Earn · Redeem · Tasks · Profile
  static const String home = '/home';
  static const String earn = '/earn';
  static const String rewards = '/rewards'; // "Redeem" tab
  static const String tasks = '/tasks';
  static const String profile = '/profile';

  // Leaderboard is reached from Home/Profile (not a bottom tab).
  static const String leaderboard = '/leaderboard';

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

  // Admin dashboard (claim-gated)
  static const String admin = '/admin';
  static const String adminRedemptions = '/admin/redemptions';
  static const String adminUsers = '/admin/users';
  static const String adminPromocodes = '/admin/promocodes';
  static const String adminBroadcast = '/admin/broadcast';
  static const String adminRewards = '/admin/rewards';
  static const String adminReports = '/admin/reports';
  static const String adminManage = '/admin/admins';
  static const String adminAnalytics = '/admin/analytics';

  static String redemption(String id) => '/redemptions/$id';
}
