import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../error/failure.dart';
import '../error/result.dart';
import '../utils/logger.dart';
import 'tier_map.dart';

/// Resolves the user's monetisation [GeoTier] from their geographic location.
///
/// Strategy (highest confidence first):
///   1. GPS fix → reverse-geocode to an ISO country code (confidence ~0.95).
///   2. If permission denied or GPS unavailable, fall back to the device
///      locale's country (confidence ~0.15).
///
/// The client-resolved tier is only a hint for the UI. Every earning request is
/// re-validated server-side against the account's country of record, so a user
/// who spoofs GPS cannot inflate their multiplier — they only change what the
/// UI *previews*, never what actually gets credited.
class GeoTierService {
  GeoTierService(this._tierMap);

  /// country ISO → tier level, sourced from remote config with a baked-in
  /// default (see [TierMap]).
  final TierMap _tierMap;

  /// Whether we currently hold location permission.
  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Requests location permission, handling the "denied forever" case so the
  /// caller can route the user to settings.
  Future<Result<bool>> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Result.failure(
          PermissionFailure('Location services are turned off.',
              code: 'location/service-disabled'),
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(
          PermissionFailure('Location permission permanently denied.',
              code: 'location/denied-forever'),
        );
      }
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      return Result.success(granted);
    } catch (e, s) {
      log.e('requestPermission failed', e, s);
      return const Result.failure(
        PermissionFailure('Could not request location permission.',
            code: 'location/error'),
      );
    }
  }

  /// Resolves the tier. Always returns a value — falls back to the locale-based
  /// country if location cannot be obtained.
  Future<GeoTierResult> resolve() async {
    try {
      if (await hasPermission()) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final iso = placemarks
            .map((p) => p.isoCountryCode)
            .firstWhere((c) => c != null && c.isNotEmpty, orElse: () => null);
        if (iso != null) {
          return GeoTierResult(
            countryCode: iso.toUpperCase(),
            tierLevel: _tierMap.tierFor(iso),
            source: 'gps',
            confidence: 0.95,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      }
    } catch (e, s) {
      log.w('GPS tier resolution failed, falling back to locale', e, s);
    }
    return _localeFallback();
  }

  GeoTierResult _localeFallback() {
    final country =
        (ui.PlatformDispatcher.instance.locale.countryCode ?? 'US').toUpperCase();
    return GeoTierResult(
      countryCode: country,
      tierLevel: _tierMap.tierFor(country),
      source: 'locale',
      confidence: 0.15,
      latitude: null,
      longitude: null,
    );
  }
}

/// The raw resolution result handed to the backend for authoritative check.
class GeoTierResult {
  const GeoTierResult({
    required this.countryCode,
    required this.tierLevel,
    required this.source,
    required this.confidence,
    required this.latitude,
    required this.longitude,
  });

  final String countryCode;
  final int tierLevel;
  final String source;
  final double confidence;
  final double? latitude;
  final double? longitude;

  GeoTier get tier => GeoTier.fromLevel(tierLevel);

  /// Payload sent to `resolveTier` / attached to earn requests. Coordinates are
  /// rounded to ~1km so we never persist a precise home location.
  Map<String, dynamic> toRequest() => {
        'countryCode': countryCode,
        'source': source,
        'confidence': confidence,
        if (latitude != null) 'lat': (latitude! * 100).round() / 100,
        if (longitude != null) 'lng': (longitude! * 100).round() / 100,
      };
}

final geoTierServiceProvider = Provider<GeoTierService>((ref) {
  return GeoTierService(ref.watch(tierMapProvider));
});
