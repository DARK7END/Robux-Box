import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps an ISO 3166-1 alpha-2 country code to a monetisation tier (1–4).
///
/// A sensible default classification ships with the app so tiering works
/// offline and on first launch. In production the map is overlaid with the
/// `config/geo_tiers` document (editable from the admin dashboard) so payouts
/// can be tuned per-country without an app update.
class TierMap {
  const TierMap([this._overrides = const {}]);

  final Map<String, int> _overrides;

  /// Returns 1–4 for [countryCode]; unknown countries default to tier 3.
  int tierFor(String countryCode) {
    final code = countryCode.toUpperCase();
    if (_overrides.containsKey(code)) return _overrides[code]!;
    return _defaultTiers[code] ?? 3;
  }

  TierMap withOverrides(Map<String, int> overrides) => TierMap({
        ..._overrides,
        ...overrides.map((k, v) => MapEntry(k.toUpperCase(), v)),
      });

  /// High-eCPM markets pay the most (T1) down to emerging markets (T4).
  static const Map<String, int> _defaultTiers = {
    // Tier 1 — highest eCPM
    'US': 1, 'CA': 1, 'GB': 1, 'AU': 1, 'NZ': 1, 'DE': 1, 'NL': 1,
    'SE': 1, 'NO': 1, 'DK': 1, 'CH': 1, 'IE': 1, 'AT': 1, 'BE': 1, 'FI': 1,
    // Tier 2
    'FR': 2, 'IT': 2, 'ES': 2, 'JP': 2, 'KR': 2, 'SG': 2, 'AE': 2, 'SA': 2,
    'QA': 2, 'KW': 2, 'IL': 2, 'PT': 2, 'GR': 2, 'PL': 2, 'CZ': 2, 'HK': 2,
    // Tier 3
    'BR': 3, 'MX': 3, 'AR': 3, 'CL': 3, 'TR': 3, 'RU': 3, 'MY': 3, 'TH': 3,
    'ZA': 3, 'RO': 3, 'HU': 3, 'CN': 3, 'CO': 3, 'PE': 3, 'RS': 3, 'UA': 3,
    // Tier 4 — emerging markets
    'IN': 4, 'ID': 4, 'PK': 4, 'BD': 4, 'NG': 4, 'EG': 4, 'PH': 4, 'VN': 4,
    'KE': 4, 'MA': 4, 'DZ': 4, 'IQ': 4, 'LK': 4, 'NP': 4, 'GH': 4, 'TZ': 4,
  };
}

/// Overridden after the remote `config/geo_tiers` document loads (see
/// `RemoteConfigService`); starts with the baked-in defaults.
final tierMapProvider = Provider<TierMap>((ref) {
  return const TierMap();
});
