import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/firebase_error_mapper.dart';
import '../../../core/utils/logger.dart';

/// Encapsulates every Firebase Authentication flow the app supports:
///  * Google Sign-In
///  * Email / password (sign-up, sign-in, reset, verification)
///  * Phone number (OTP) with auto-retrieval support
///
/// The repository speaks in [Result]s and never leaks raw `FirebaseAuthException`
/// to the UI. Account/profile provisioning (wallet, referral code) is handled
/// server-side by the `onUserCreated` auth trigger, so this layer only concerns
/// itself with obtaining a Firebase session.
class AuthRepository {
  AuthRepository(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authState() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------
  Future<Result<User>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Result.failure(
          AuthFailure('Sign-in cancelled.', code: 'auth/cancelled'),
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      return _requireUser(userCred);
    } catch (e, s) {
      log.e('signInWithGoogle failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  // ---------------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------------
  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());
      unawaited(cred.user?.sendEmailVerification());
      await cred.user?.reload();
      return _requireUser(cred);
    } catch (e, s) {
      log.e('signUpWithEmail failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(cred);
    } catch (e, s) {
      log.e('signInWithEmail failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> resendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  // ---------------------------------------------------------------------------
  // Phone (OTP)
  // ---------------------------------------------------------------------------

  /// Starts phone verification. On Android the SMS code may be auto-retrieved,
  /// in which case [onAutoVerified] fires and no manual code entry is needed.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Failure failure) onError,
    required void Function(User user) onAutoVerified,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          final user = cred.user;
          if (user != null) onAutoVerified(user);
        } catch (e, s) {
          onError(FirebaseErrorMapper.map(e, s));
        }
      },
      verificationFailed: (e) => onError(FirebaseErrorMapper.map(e)),
      codeSent: (verificationId, token) => onCodeSent(verificationId, token),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Confirms a manually-entered SMS [smsCode] against a [verificationId].
  Future<Result<User>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final cred = await _auth.signInWithCredential(credential);
      return _requireUser(cred);
    } catch (e, s) {
      log.e('confirmPhoneCode failed', e, s);
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  /// Deletes the auth account. Firestore data cleanup is handled by the
  /// `onUserDeleted` trigger; this may require a recent re-authentication.
  Future<Result<void>> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await _googleSignIn.signOut();
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(FirebaseErrorMapper.map(e, s));
    }
  }

  Result<User> _requireUser(UserCredential cred) {
    final user = cred.user;
    if (user == null) {
      return const Result.failure(
        AuthFailure('Sign-in failed. Please try again.', code: 'auth/no-user'),
      );
    }
    return Result.success(user);
  }
}

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: const ['email', 'profile']);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});
