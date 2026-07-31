import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_controller.dart';
import 'widgets/social_auth_button.dart';

/// Auth landing screen offering Google, phone and email sign-in.
///
/// The hero artwork already carries the full "Robux Box / Play. Earn.
/// Redeem." branding, so this screen shows no separate logo or tagline on
/// top of it — just the welcome copy and the sign-in options, anchored low
/// where the artwork is naturally darkest.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final busy = authState.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && next.error is Failure) {
        AppToast.error(context, (next.error! as Failure).message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/welcome_hero.png', fit: BoxFit.cover),
          // Insurance, not the primary legibility mechanism — the artwork's
          // own ground/shadow is already near-black through this band, this
          // just guarantees it regardless of device aspect ratio and crop.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.45, 0.82],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                Text(
                  context.l10n.authWelcomeTitle,
                  style: context.text.headlineMedium
                      ?.copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    context.l10n.authWelcomeSubtitle,
                    style: context.text.bodyLarge
                        ?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 250.ms),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      SocialAuthButton(
                        label: context.l10n.authContinueWithGoogle,
                        icon: Icons.g_mobiledata_rounded,
                        loading: busy,
                        onPressed: busy
                            ? null
                            : () async {
                                final ok = await ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGoogle();
                                if (ok && context.mounted) {
                                  context.go(AppRoutes.home);
                                }
                              },
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.md),
                      SocialAuthButton(
                        label: context.l10n.authContinueWithPhone,
                        icon: Icons.phone_iphone_rounded,
                        onPressed: busy
                            ? null
                            : () => context.push(AppRoutes.phoneAuth),
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.md),
                      SocialAuthButton(
                        label: context.l10n.authContinueWithEmail,
                        icon: Icons.alternate_email_rounded,
                        onPressed: busy
                            ? null
                            : () => context.push(AppRoutes.emailAuth),
                      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _TermsFooter(config: config),
                SizedBox(height: context.padding.bottom + AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter({required this.config});
  final AppConfig config;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: Colors.white70, fontSize: 12);
    const link = TextStyle(
      color: AppColors.brand,
      fontSize: 12,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.brand,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(context.l10n.authAgreeTerms,
              style: base, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _open(config.termsUrl),
                child: Text(context.l10n.settingsTerms, style: link),
              ),
              const Text('  ·  ', style: base),
              GestureDetector(
                onTap: () => _open(config.privacyUrl),
                child: Text(context.l10n.settingsPrivacy, style: link),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
