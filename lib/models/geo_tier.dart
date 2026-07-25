import 'package:equatable/equatable.dart';

import '../core/constants/app_constants.dart';

/// The resolved geo-tier for the current session.
///
/// Produced by `GeoTierService`: the device location → reverse-geocoded
/// country → tier mapping (from remote config), then confirmed server-side on
/// every earn so a spoofed client can't inflate its multiplier.
class GeoTierInfo extends Equatable {
  const GeoTierInfo({
    required this.countryCode,
    required this.countryName,
    required this.tier,
    required this.source,
    required this.confidence,
    required this.resolvedAt,
  });

  final String countryCode;
  final String countryName;
  final GeoTier tier;

  /// How the country was determined: `gps`, `sim`, `ip` or `locale`.
  final String source;

  /// 0..1 — GPS is highest; locale-only fallback is lowest. Low-confidence
  /// sessions are re-verified server-side before high-value payouts.
  final double confidence;
  final DateTime? resolvedAt;

  double get multiplier => tier.multiplier;

  Map<String, dynamic> toMap() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'tierLevel': tier.level,
        'source': source,
        'confidence': confidence,
        'resolvedAt': resolvedAt.toIso8601String(),
      };

  static const GeoTierInfo unknown = GeoTierInfo(
    countryCode: 'US',
    countryName: 'Unknown',
    tier: GeoTier.t4,
    source: 'locale',
    confidence: 0.1,
    resolvedAt: null,
  );

  @override
  List<Object?> get props => [countryCode, tier, source];
}
