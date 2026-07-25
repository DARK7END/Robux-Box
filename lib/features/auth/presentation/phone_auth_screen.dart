import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/phone_auth_controller.dart';

/// Phone number sign-in with OTP. Reacts to auto-retrieval on Android and
/// manual code entry elsewhere.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthControllerProvider);
    final controller = ref.read(phoneAuthControllerProvider.notifier);

    ref.listen(phoneAuthControllerProvider, (prev, next) {
      if (next.failure != null && next.failure != prev?.failure) {
        AppToast.error(context, next.failure!.message);
      }
      if (next.stage == PhoneStage.verified) {
        context.go(AppRoutes.home);
      }
    });

    final isCodeStage = state.stage == PhoneStage.enterCode ||
        state.stage == PhoneStage.verifying;

    return AppScaffold(
      title: context.l10n.authContinueWithPhone,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.xxl),
        child: isCodeStage
            ? _codeStage(context, state, controller)
            : _numberStage(context, state, controller),
      ),
    );
  }

  Widget _numberStage(
    BuildContext context,
    PhoneAuthState state,
    PhoneAuthController controller,
  ) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.authPhoneNumber, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We will send you a 6-digit verification code.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.authPhoneNumber,
              hintText: '+1 555 123 4567',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            label: context.l10n.authSendCode,
            loading: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () {
                    if (_phoneFormKey.currentState!.validate()) {
                      controller.sendCode(_phone.text.replaceAll(' ', ''));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _codeStage(
    BuildContext context,
    PhoneAuthState state,
    PhoneAuthController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.authEnterCode, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(state.phoneNumber, style: context.text.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: context.text.headlineMedium?.copyWith(letterSpacing: 12),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
          onChanged: (value) {
            if (value.length == 6) controller.verifyCode(value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        GradientButton(
          label: context.l10n.authVerify,
          loading: state.stage == PhoneStage.verifying,
          onPressed: state.isBusy
              ? null
              : () {
                  final error = Validators.otp(_code.text);
                  if (error != null) {
                    AppToast.error(context, error);
                    return;
                  }
                  controller.verifyCode(_code.text);
                },
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: state.canResend
                ? () => controller.sendCode(state.phoneNumber)
                : null,
            child: Text(
              state.resendCooldown > 0
                  ? context.l10n.authResendIn(state.resendCooldown)
                  : context.l10n.authResendCode,
            ),
          ),
        ),
      ],
    );
  }
}
