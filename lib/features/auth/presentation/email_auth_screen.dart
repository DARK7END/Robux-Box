import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_controller.dart';

/// Combined sign-in / sign-up screen with email + password.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    final ok = _isSignUp
        ? await controller.signUpWithEmail(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
          )
        : await controller.signInWithEmail(_email.text, _password.text);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _forgotPassword() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      AppToast.error(context, 'Enter your email first, then tap reset.');
      return;
    }
    final ok =
        await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (ok && mounted) AppToast.success(context, context.l10n.authResetSent);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && next.error is Failure) {
        AppToast.error(context, (next.error! as Failure).message);
      }
    });

    return AppScaffold(
      title: _isSignUp ? context.l10n.authSignUp : context.l10n.authSignIn,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSignUp) ...[
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.authDisplayName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: Validators.displayName,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: context.l10n.authEmail,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.l10n.authPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.password,
              ),
              if (_isSignUp) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.l10n.authConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                ),
              ],
              if (!_isSignUp)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: busy ? null : _forgotPassword,
                    child: Text(context.l10n.authForgotPassword),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                label: _isSignUp
                    ? context.l10n.authSignUp
                    : context.l10n.authSignIn,
                loading: busy,
                onPressed: busy ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? context.l10n.authHaveAccount
                        : context.l10n.authNoAccount,
                    style: context.text.bodyMedium,
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(_isSignUp
                        ? context.l10n.authSignIn
                        : context.l10n.authSignUp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
