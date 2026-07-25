import 'package:equatable/equatable.dart';

/// A domain-level failure. All layers speak in [Failure]s rather than throwing
/// raw exceptions across boundaries, so the UI can render a stable, localised
/// message and a machine-readable [code].
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.code, this.cause});

  /// Human-readable, already-safe-to-show fallback message (English). The UI
  /// prefers a localised string keyed on [code] when available.
  final String message;

  /// Stable machine code, e.g. `auth/wrong-password`, used for localisation and
  /// analytics.
  final String? code;

  /// Original error, kept for logging only — never shown to users.
  final Object? cause;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Network connectivity / timeout problems.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please try again.',
    Object? cause,
  ]) : super(code: 'network/unavailable', cause: cause);
}

/// Firebase Auth failures (wrong password, email in use, invalid OTP, …).
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.cause});
}

/// Firestore / backend read-write failures and permission denials.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
    Object? cause,
    String? code,
  ]) : super(code: code ?? 'server/error', cause: cause);
}

/// A Cloud Function rejected the request (validation, fraud check, insufficient
/// balance, cooldown, …). The [code] mirrors the function's `HttpsError` code.
class OperationFailure extends Failure {
  const OperationFailure(super.message, {super.code, super.cause});
}

/// A required permission (location, tracking, notifications) was denied.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.cause});
}

/// The user attempted something the anti-fraud/anti-cheat layer blocked.
class SecurityFailure extends Failure {
  const SecurityFailure(super.message, {super.code, super.cause});
}

/// Fallback for anything unexpected.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred.',
    Object? cause,
  ]) : super(code: 'unknown', cause: cause);
}
