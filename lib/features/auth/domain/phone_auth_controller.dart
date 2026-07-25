import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../data/auth_repository.dart';

/// Phase of the phone-number OTP flow.
enum PhoneStage { enterNumber, enterCode, verifying, verified }

class PhoneAuthState {
  const PhoneAuthState({
    this.stage = PhoneStage.enterNumber,
    this.phoneNumber = '',
    this.verificationId,
    this.resendToken,
    this.resendCooldown = 0,
    this.isBusy = false,
    this.failure,
  });

  final PhoneStage stage;
  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final int resendCooldown;
  final bool isBusy;
  final Failure? failure;

  bool get canResend => resendCooldown == 0 && !isBusy;

  PhoneAuthState copyWith({
    PhoneStage? stage,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    int? resendCooldown,
    bool? isBusy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return PhoneAuthState(
      stage: stage ?? this.stage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      isBusy: isBusy ?? this.isBusy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class PhoneAuthController extends Notifier<PhoneAuthState> {
  Timer? _cooldownTimer;

  @override
  PhoneAuthState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const PhoneAuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> sendCode(String phoneNumber) async {
    state = state.copyWith(
      isBusy: true,
      phoneNumber: phoneNumber,
      clearFailure: true,
    );
    await _repo.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      resendToken: state.resendToken,
      onCodeSent: (verificationId, token) {
        state = state.copyWith(
          stage: PhoneStage.enterCode,
          verificationId: verificationId,
          resendToken: token,
          isBusy: false,
        );
        _startCooldown();
      },
      onError: (failure) {
        state = state.copyWith(isBusy: false, failure: failure);
      },
      onAutoVerified: (_) {
        // Android auto-retrieval signed the user in already.
        state = state.copyWith(stage: PhoneStage.verified, isBusy: false);
      },
    );
  }

  /// Returns true on success. On failure [state.failure] is populated.
  Future<bool> verifyCode(String code) async {
    final verificationId = state.verificationId;
    if (verificationId == null) return false;
    state = state.copyWith(
      stage: PhoneStage.verifying,
      isBusy: true,
      clearFailure: true,
    );
    final result = await _repo.confirmPhoneCode(
      verificationId: verificationId,
      smsCode: code,
    );
    return result.when(
      success: (_) {
        state = state.copyWith(stage: PhoneStage.verified, isBusy: false);
        return true;
      },
      failure: (f) {
        state = state.copyWith(
          stage: PhoneStage.enterCode,
          isBusy: false,
          failure: f,
        );
        return false;
      },
    );
  }

  void reset() {
    _cooldownTimer?.cancel();
    state = const PhoneAuthState();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(resendCooldown: 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldown - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: next);
      }
    });
  }
}

final phoneAuthControllerProvider =
    NotifierProvider<PhoneAuthController, PhoneAuthState>(
        PhoneAuthController.new);
