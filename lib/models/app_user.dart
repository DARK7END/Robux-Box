import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/app_constants.dart';
import 'model_utils.dart';

/// VIP membership levels. Values map to [AppConstants.vipMultipliers] keys.
enum VipLevel { none, bronze, silver, gold, diamond }

/// Account moderation status set by the anti-fraud system / admins.
enum AccountStatus { active, restricted, banned }

/// The canonical user profile document at `users/{uid}`.
///
/// Sensitive/authoritative fields (balances, fraud score) live in separate
/// documents/collections with stricter security rules; this document holds the
/// user-facing profile and progression.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.phoneNumber,
    required this.countryCode,
    required this.tierLevel,
    required this.vipLevel,
    required this.status,
    required this.xp,
    required this.level,
    required this.streakCount,
    required this.lastDailyClaim,
    this.lastSpinAt,
    this.lastChestAt,
    required this.referralCode,
    required this.referredBy,
    required this.referralCount,
    required this.robloxUsername,
    required this.createdAt,
    required this.lastActiveAt,
    required this.locale,
    required this.isEmailVerified,
  });

  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String phoneNumber;

  /// ISO 3166-1 alpha-2 country of the account, resolved from geolocation and
  /// used to pick the monetisation [tierLevel].
  final String countryCode;
  final int tierLevel;
  final VipLevel vipLevel;
  final AccountStatus status;

  final int xp;
  final int level;
  final int streakCount;
  final DateTime? lastDailyClaim;
  final DateTime? lastSpinAt;
  final DateTime? lastChestAt;

  final String referralCode;
  final String? referredBy;
  final int referralCount;

  final String robloxUsername;

  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final String locale;
  final bool isEmailVerified;

  GeoTier get tier => GeoTier.fromLevel(tierLevel);

  double get earningMultiplier {
    final vip = AppConstants.vipMultipliers[vipLevel.name] ?? 1.0;
    return tier.multiplier * vip;
  }

  int get xpForNextLevel => (level + 1) * AppConstants.levelXpStep;
  double get levelProgress {
    final currentFloor = level * AppConstants.levelXpStep;
    final span = xpForNextLevel - currentFloor;
    if (span <= 0) return 0;
    return ((xp - currentFloor) / span).clamp(0.0, 1.0);
  }

  static bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return now.year == d.year && now.month == d.month && now.day == d.day;
  }

  bool get canClaimDaily => !_isToday(lastDailyClaim);
  bool get canSpinToday => !_isToday(lastSpinAt);
  bool get canOpenChestToday => !_isToday(lastChestAt);

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: Parse.toStr(map['displayName'], 'Player'),
      email: Parse.toStr(map['email']),
      photoUrl: Parse.toStr(map['photoUrl']),
      phoneNumber: Parse.toStr(map['phoneNumber']),
      countryCode: Parse.toStr(map['countryCode'], 'US'),
      tierLevel: Parse.toInt(map['tierLevel'], 4),
      vipLevel: Parse.enumFromName(map['vipLevel'], VipLevel.values, VipLevel.none),
      status:
          Parse.enumFromName(map['status'], AccountStatus.values, AccountStatus.active),
      xp: Parse.toInt(map['xp']),
      level: Parse.toInt(map['level']),
      streakCount: Parse.toInt(map['streakCount']),
      lastDailyClaim: Parse.toDate(map['lastDailyClaim']),
      lastSpinAt: Parse.toDate(map['lastSpinAt']),
      lastChestAt: Parse.toDate(map['lastChestAt']),
      referralCode: Parse.toStr(map['referralCode']),
      referredBy: map['referredBy'] as String?,
      referralCount: Parse.toInt(map['referralCount']),
      robloxUsername: Parse.toStr(map['robloxUsername']),
      createdAt: Parse.toDate(map['createdAt']),
      lastActiveAt: Parse.toDate(map['lastActiveAt']),
      locale: Parse.toStr(map['locale'], 'en'),
      isEmailVerified: Parse.toBool(map['isEmailVerified']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  /// Only the fields a client is allowed to write are serialised here; balances,
  /// tier and status are written exclusively by Cloud Functions.
  Map<String, dynamic> toProfileUpdate() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'robloxUsername': robloxUsername,
        'locale': locale,
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? robloxUsername,
    int? tierLevel,
    VipLevel? vipLevel,
    int? xp,
    int? level,
    int? streakCount,
    DateTime? lastDailyClaim,
    String? locale,
    AccountStatus? status,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      tierLevel: tierLevel ?? this.tierLevel,
      vipLevel: vipLevel ?? this.vipLevel,
      status: status ?? this.status,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakCount: streakCount ?? this.streakCount,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      lastSpinAt: lastSpinAt,
      lastChestAt: lastChestAt,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount,
      robloxUsername: robloxUsername ?? this.robloxUsername,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      locale: locale ?? this.locale,
      isEmailVerified: isEmailVerified,
    );
  }

  static AppUser empty(String uid) => AppUser(
        uid: uid,
        displayName: 'Player',
        email: '',
        photoUrl: '',
        phoneNumber: '',
        countryCode: 'US',
        tierLevel: 4,
        vipLevel: VipLevel.none,
        status: AccountStatus.active,
        xp: 0,
        level: 0,
        streakCount: 0,
        lastDailyClaim: null,
        referralCode: '',
        referredBy: null,
        referralCount: 0,
        robloxUsername: '',
        createdAt: null,
        lastActiveAt: null,
        locale: 'en',
        isEmailVerified: false,
      );

  @override
  List<Object?> get props =>
      [uid, displayName, tierLevel, vipLevel, status, xp, level, streakCount];
}
