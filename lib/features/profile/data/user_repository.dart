import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../models/app_user.dart';
import '../../../models/wallet.dart';

/// Reads/streams the user profile and wallet, and applies the small set of
/// profile fields a client is permitted to write. Balances and status are
/// read-only here (enforced by security rules) and only change via functions.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FsPaths.users).doc(uid);
  DocumentReference<Map<String, dynamic>> _walletDoc(String uid) =>
      _firestore.collection(FsPaths.wallets).doc(uid);

  Stream<AppUser> watchUser(String uid) =>
      _userDoc(uid).snapshots().map((doc) =>
          doc.exists ? AppUser.fromDoc(doc) : AppUser.empty(uid));

  Stream<Wallet> watchWallet(String uid) =>
      _walletDoc(uid).snapshots().map((doc) =>
          doc.exists ? Wallet.fromDoc(doc) : Wallet.empty(uid));

  Future<AppUser?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? robloxUsername,
    String? locale,
  }) async {
    try {
      await _userDoc(uid).set({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (robloxUsername != null) 'robloxUsername': robloxUsername,
        if (locale != null) 'locale': locale,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  /// Touches `lastActiveAt` for retention analytics and daily-streak windows.
  Future<void> touchActivity(String uid) async {
    try {
      await _userDoc(uid).set(
        {'lastActiveAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      /* best-effort */
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

/// The signed-in user's profile, or null when signed out / still loading.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(auth.uid);
});

/// The signed-in user's wallet, or null when signed out.
final currentWalletProvider = StreamProvider<Wallet?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchWallet(auth.uid);
});
