import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/logger.dart';
import 'secure_storage_service.dart';

/// Client-side anti-cheat / anti-fraud helper.
///
/// It builds a device fingerprint, runs cheap local integrity heuristics
/// (emulator / debuggable / clock-skew), and signs earning requests so the
/// backend can detect replays. The **authoritative** fraud checks live in Cloud
/// Functions and Firebase App Check — the client layer only raises the cost of
/// abuse and gives the backend richer signals.
class SecurityService {
  SecurityService(this._secure)
      : _deviceInfo = DeviceInfoPlugin();

  final SecureStorageService _secure;
  final DeviceInfoPlugin _deviceInfo;

  IntegritySignals? _cached;

  /// Collects a signed, privacy-respecting device context to attach to earn
  /// requests. No IMEI / advertising id is collected; only a per-install
  /// random device id (see [SecureStorageService.deviceId]).
  Future<DeviceContext> collect() async {
    final deviceId = await _secure.deviceId();
    final signals = await _integrity();
    final pkg = await PackageInfo.fromPlatform();

    return DeviceContext(
      deviceId: deviceId,
      platform: Platform.operatingSystem,
      osVersion: signals.osVersion,
      model: signals.model,
      appVersion: '${pkg.version}+${pkg.buildNumber}',
      isPhysicalDevice: signals.isPhysical,
      isDebug: kDebugMode,
      integrityScore: signals.score,
    );
  }

  /// Builds an idempotency-keyed, HMAC-signed envelope for an earn action. The
  /// backend verifies the signature against the registered device secret and
  /// rejects duplicate [nonce]s, defeating simple replay/tamper attacks.
  Future<SignedRequest> signEarn({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final deviceId = await _secure.deviceId();
    final nonce = _nonce();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final canonical = jsonEncode({
      'action': action,
      'deviceId': deviceId,
      'nonce': nonce,
      'ts': ts,
      'payload': payload,
    });
    final signature = await _secure.signPayload(canonical);
    return SignedRequest(
      action: action,
      deviceId: deviceId,
      nonce: nonce,
      ts: ts,
      payload: payload,
      signature: signature,
    );
  }

  Future<IntegritySignals> _integrity() async {
    if (_cached != null) return _cached!;
    var isPhysical = true;
    var model = 'unknown';
    var osVersion = 'unknown';
    var suspicious = false;

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        isPhysical = info.isPhysicalDevice;
        model = '${info.manufacturer} ${info.model}';
        osVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        // Cheap emulator heuristics.
        final fingerprint = info.fingerprint.toLowerCase();
        suspicious = !isPhysical ||
            fingerprint.contains('generic') ||
            info.brand.toLowerCase() == 'generic' ||
            info.model.toLowerCase().contains('sdk') ||
            info.product.toLowerCase().contains('sdk');
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        isPhysical = info.isPhysicalDevice;
        model = info.utsname.machine;
        osVersion = 'iOS ${info.systemVersion}';
        suspicious = !isPhysical;
      }
    } catch (e, s) {
      log.w('integrity probe failed', e, s);
    }

    // Score 0..1 — 1.0 is clean. Debug builds and emulators are penalised.
    var score = 1.0;
    if (suspicious) score -= 0.6;
    if (kDebugMode) score -= 0.1;
    score = score.clamp(0.0, 1.0);

    return _cached = IntegritySignals(
      isPhysical: isPhysical,
      model: model,
      osVersion: osVersion,
      score: score,
    );
  }

  String _nonce() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16)}${Object().hashCode.toRadixString(16)}';
  }
}

class IntegritySignals {
  const IntegritySignals({
    required this.isPhysical,
    required this.model,
    required this.osVersion,
    required this.score,
  });

  final bool isPhysical;
  final String model;
  final String osVersion;
  final double score;
}

class DeviceContext {
  const DeviceContext({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.appVersion,
    required this.isPhysicalDevice,
    required this.isDebug,
    required this.integrityScore,
  });

  final String deviceId;
  final String platform;
  final String osVersion;
  final String model;
  final String appVersion;
  final bool isPhysicalDevice;
  final bool isDebug;
  final double integrityScore;

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'platform': platform,
        'osVersion': osVersion,
        'model': model,
        'appVersion': appVersion,
        'isPhysicalDevice': isPhysicalDevice,
        'isDebug': isDebug,
        'integrityScore': integrityScore,
      };
}

class SignedRequest {
  const SignedRequest({
    required this.action,
    required this.deviceId,
    required this.nonce,
    required this.ts,
    required this.payload,
    required this.signature,
  });

  final String action;
  final String deviceId;
  final String nonce;
  final int ts;
  final Map<String, dynamic> payload;
  final String signature;

  Map<String, dynamic> toMap() => {
        'action': action,
        'deviceId': deviceId,
        'nonce': nonce,
        'ts': ts,
        'payload': payload,
        'signature': signature,
      };
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(secureStorageProvider));
});
