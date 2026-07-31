/// Centralised Firestore collection/document path builders.
///
/// Keeping every path in one place means the schema is documented once and
/// refactors are safe. These names must match `firestore.rules` and the Cloud
/// Functions exactly.
abstract final class FsPaths {
  const FsPaths._();

  // Root collections
  static const String users = 'users';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String offers = 'offers';
  static const String offerCompletions = 'offer_completions';
  static const String rewards = 'rewards';
  static const String redemptions = 'redemptions';
  static const String notifications = 'notifications';
  static const String leaderboards = 'leaderboards';
  static const String events = 'events';
  static const String banners = 'banners';
  static const String promocodes = 'promocodes';
  static const String reports = 'reports';
  static const String supportTickets = 'supportTickets';
  static const String referrals = 'referrals';
  static const String devices = 'devices';
  static const String adImpressions = 'ad_impressions';
  static const String config = 'config';
  static const String tiers = 'geo_tiers';
  static const String fraudFlags = 'fraud_flags';
  static const String auditLogs = 'audit_logs';

  // Sub-collections
  static const String userTransactions = 'transactions';
  static const String userDevices = 'devices';
  static const String userNotifications = 'notifications';

  // Documents
  static String user(String uid) => '$users/$uid';
  static String wallet(String uid) => '$wallets/$uid';
  static String redemption(String id) => '$redemptions/$id';
  static String offer(String id) => '$offers/$id';
  static String reward(String id) => '$rewards/$id';
  static String promocode(String code) => '$promocodes/$code';
  static String configDoc(String name) => '$config/$name';
  static String leaderboard(String period) => '$leaderboards/$period';
  static String supportTicket(String id) => '$supportTickets/$id';
  static String ticketMessages(String id) => '$supportTickets/$id/messages';

  // Well-known config docs
  static const String configEconomy = 'economy';
  static const String configFeatureFlags = 'feature_flags';
  static const String configMaintenance = 'maintenance';
}
