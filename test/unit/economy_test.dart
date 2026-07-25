import 'package:flutter_test/flutter_test.dart';
import 'package:robux_box/core/constants/app_constants.dart';
import 'package:robux_box/core/services/tier_map.dart';
import 'package:robux_box/models/app_user.dart';

void main() {
  group('GeoTier', () {
    test('multipliers decrease from T1 to T4', () {
      expect(GeoTier.t1.multiplier, greaterThan(GeoTier.t2.multiplier));
      expect(GeoTier.t2.multiplier, greaterThan(GeoTier.t3.multiplier));
      expect(GeoTier.t3.multiplier, greaterThan(GeoTier.t4.multiplier));
      expect(GeoTier.t1.multiplier, 1.0);
    });

    test('fromLevel maps correctly and defaults to T4', () {
      expect(GeoTier.fromLevel(1), GeoTier.t1);
      expect(GeoTier.fromLevel(4), GeoTier.t4);
      expect(GeoTier.fromLevel(99), GeoTier.t4);
    });
  });

  group('TierMap', () {
    const map = TierMap();
    test('known countries resolve to expected tiers', () {
      expect(map.tierFor('US'), 1);
      expect(map.tierFor('fr'), 2); // case-insensitive
      expect(map.tierFor('BR'), 3);
      expect(map.tierFor('IN'), 4);
    });

    test('unknown countries default to tier 3', () {
      expect(map.tierFor('ZZ'), 3);
    });

    test('overrides take precedence', () {
      final overridden = map.withOverrides({'IN': 1});
      expect(overridden.tierFor('IN'), 1);
      expect(overridden.tierFor('US'), 1);
    });
  });

  group('AppUser progression', () {
    test('earningMultiplier combines tier and VIP', () {
      final user = AppUser.empty('u').copyWith(
        tierLevel: 1,
        vipLevel: VipLevel.gold,
      );
      final expected =
          GeoTier.t1.multiplier * AppConstants.vipMultipliers['gold']!;
      expect(user.earningMultiplier, closeTo(expected, 1e-9));
    });

    test('levelProgress is clamped between 0 and 1', () {
      final user = AppUser.empty('u').copyWith(level: 2, xp: 1200);
      expect(user.levelProgress, inInclusiveRange(0.0, 1.0));
    });

    test('canClaimDaily is true when never claimed', () {
      expect(AppUser.empty('u').canClaimDaily, isTrue);
    });

    test('canClaimDaily is false when claimed today', () {
      final user = AppUser.empty('u').copyWith(lastDailyClaim: DateTime.now());
      expect(user.canClaimDaily, isFalse);
    });
  });
}
