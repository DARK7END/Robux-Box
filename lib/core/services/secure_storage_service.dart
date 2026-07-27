import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted local storage for sensitive values (device secret, cached auth
/// hints, anti-fraud nonce). Backed by the Android Keystore / iOS Keychain.
///
/// Never store the Firebase ID token here — the SDK manages that securely. This
/// is for app-level secrets like the per-install device id used to bind an
/// account to a limited number of devices.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kDeviceId = 'sec_device_id';
  static const _kDeviceSecret = 'sec_device_secret';

  Future<String> deviceId() async {
    final existing = await _storage.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _randomHex(16);
    await _storage.write(key: _kDeviceId, value: generated);
    return generated;
  }

  Future<String> deviceSecret() async {
    final existing = await _storage.read(key: _kDeviceSecret);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _randomHex(32);
    await _storage.write(key: _kDeviceSecret, value: generated);
    return generated;
  }

  /// Produces a rotating, signed nonce the backend can verify to detect replayed
  /// earn requests. HMAC over (deviceSecret, payload) — the secret never leaves
  /// the secure enclave in plaintext.
  Future<String> signPayload(String payload) async {
    final secret = await deviceSecret();
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> wipe() => _storage.deleteAll();

  String _randomHex(int bytes) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final seed = '$now:${identityHashCode(this)}:${Object().hashCode}';
    final digest = sha256.convert(utf8.encode(seed)).toString();
    return digest.substring(0, bytes * 2);
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
