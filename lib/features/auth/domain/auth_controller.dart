import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/auth_repository.dart';

/// Drives the email/Google auth screens. The UI watches [state] for a loading
/// spinner and surfaces [AsyncError.error] (always a [Failure]) as a toast.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signInWithGoogle() => _run(() => _repo.signInWithGoogle());

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _run(() => _repo.signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          ));

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    final result = await _repo.sendPasswordReset(email);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _repo.signOut();
    state = const AsyncData(null);
  }

  Future<bool> _run(Future<Result<User>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (Failure f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
