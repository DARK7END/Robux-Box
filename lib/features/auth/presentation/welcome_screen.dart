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
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_controller.dart';
import 'widgets/social_auth_button.dart';

/// Auth landing screen offering Google, phone and email sign-in.
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

    return AppScaffold(
      showAppBar: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CoinParticles(count: 14, speed: 0.6)),
          ),
          Column(
        children: [
          const Spacer(flex: 2),
          _Logo().animate().scale(
                begin: const Offset(0.6, 0.6),
                curve: AppCurves.spring,
                duration: AppDuration.slow,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.tagline,
            style: context.text.labelLarge
                ?.copyWith(color: context.colors.primary, letterSpacing: 1),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.authWelcomeTitle,
            style: context.text.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.authWelcomeSubtitle,
            style: context.text.bodyLarge
                ?.copyWith(color: context.surfaces.textTertiary),
          ).animate().fadeIn(delay: 250.ms),
          const Spacer(flex: 3),
          SocialAuthButton(
            label: context.l10n.authContinueWithGoogle,
            icon: Icons.g_mobiledata_rounded,
            loading: busy,
            onPressed: busy
                ? null
                : () async {
                    final ok =
                        await ref.read(authControllerProvider.notifier).signInWithGoogle();
                    if (ok && context.mounted) context.go(AppRoutes.home);
                  },
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSpacing.md),
          SocialAuthButton(
            label: context.l10n.authContinueWithPhone,
            icon: Icons.phone_iphone_rounded,
            onPressed: busy ? null : () => context.push(AppRoutes.phoneAuth),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSpacing.md),
          SocialAuthButton(
            label: context.l10n.authContinueWithEmail,
            icon: Icons.alternate_email_rounded,
            onPressed: busy ? null : () => context.push(AppRoutes.emailAuth),
          ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSpacing.xl),
          _TermsFooter(config: config),
          SizedBox(height: context.padding.bottom + AppSpacing.md),
            ],
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Image.asset('assets/images/chest_icon.png', fit: BoxFit.contain),
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
    final base =
        context.text.bodySmall?.copyWith(color: context.surfaces.textTertiary);
    final link = base?.copyWith(
      color: AppColors.brand,
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
              Text('  ·  ', style: base),
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
