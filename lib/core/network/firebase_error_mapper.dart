import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../error/failure.dart';

/// Translates raw Firebase exceptions into domain [Failure]s with stable codes.
/// The UI maps these codes to localised strings; the [message] here is an
/// English fallback.
abstract final class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static Failure map(Object error, [StackTrace? _]) {
    if (error is Failure) return error;
    if (error is FirebaseAuthException) return _auth(error);
    if (error is FirebaseFunctionsException) return _functions(error);
    if (error is FirebaseException) return _firestore(error);
    return UnknownFailure(error.toString(), error);
  }

  static AuthFailure _auth(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'That email address looks invalid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Incorrect email or password.',
      'email-already-in-use' => 'That email is already registered.',
      'weak-password' => 'Please choose a stronger password.',
      'operation-not-allowed' => 'This sign-in method is not enabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      'invalid-verification-code' => 'The code you entered is incorrect.',
      'invalid-phone-number' => 'That phone number looks invalid.',
      'session-expired' => 'The code expired. Please request a new one.',
      'network-request-failed' => 'No internet connection. Please try again.',
      _ => e.message ?? 'Authentication failed. Please try again.',
    };
    return AuthFailure(message, code: 'auth/${e.code}', cause: e);
  }

  static OperationFailure _functions(FirebaseFunctionsException e) {
    // Cloud Functions throw HttpsError; `details` may carry a structured code.
    final code = (e.details is Map && (e.details as Map)['code'] != null)
        ? (e.details as Map)['code'].toString()
        : e.code;
    final message = switch (e.code) {
      'unauthenticated' => 'Please sign in to continue.',
      'permission-denied' => 'You are not allowed to do that.',
      'resource-exhausted' =>
        'You have reached the limit. Please try again later.',
      'failed-precondition' =>
        e.message ?? 'This action is not available right now.',
      'invalid-argument' => e.message ?? 'Invalid request.',
      'deadline-exceeded' => 'The request timed out. Please try again.',
      _ => e.message ?? 'The operation could not be completed.',
    };
    return OperationFailure(message, code: 'fn/$code', cause: e);
  }

  static ServerFailure _firestore(FirebaseException e) {
    final message = switch (e.code) {
      'permission-denied' => 'You do not have access to this data.',
      'unavailable' => 'Service temporarily unavailable. Please try again.',
      'not-found' => 'The requested data was not found.',
      _ => 'A database error occurred. Please try again.',
    };
    return ServerFailure(message, e, 'db/${e.code}');
  }
}
