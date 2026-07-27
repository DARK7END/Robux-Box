import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';

class _Page {
  const _Page(this.icon, this.title, this.body, this.gradient);
  final IconData icon;
  final String title;
  final String body;
  final Gradient gradient;
}

/// Three-slide intro shown once on first launch. Persists a "seen" flag so it
/// never blocks returning users.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Page> _pages(BuildContext context) => [
        _Page(Icons.play_circle_fill_rounded, context.l10n.onboardingTitle1,
            context.l10n.onboardingBody1, AppGradients.brand),
        _Page(Icons.card_giftcard_rounded, context.l10n.onboardingTitle2,
            context.l10n.onboardingBody2, AppGradients.robux),
        _Page(Icons.shield_moon_rounded, context.l10n.onboardingTitle3,
            context.l10n.onboardingBody3, AppGradients.neon),
      ];

  Future<void> _finish() async {
    await ref.read(preferencesProvider).setOnboardingSeen(true);
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final isLast = _index == pages.length - 1;

    return AppScaffold(
      showAppBar: false,
      padded: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CoinParticles(count: 12, speed: 0.6)),
          ),
          Column(
            children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextButton(
                onPressed: _finish,
                child: Text(context.l10n.commonSkip),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final page = pages[i];
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          gradient: page.gradient,
                          shape: BoxShape.circle,
                          boxShadow:
                              AppShadows.glow(page.gradient.colors.first),
                        ),
                        child: Icon(page.icon,
                            size: 68, color: AppColors.white),
                      )
                          .animate(key: ValueKey(i))
                          .scale(
                              begin: const Offset(0.7, 0.7),
                              curve: AppCurves.spring,
                              duration: AppDuration.slow)
                          .fadeIn(),
                      const SizedBox(height: AppSpacing.huge),
                      Text(
                        page.title,
                        style: context.text.headlineMedium,
                        textAlign: TextAlign.center,
                      ).animate(key: ValueKey('t$i')).fadeIn().slideY(begin: 0.3),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        page.body,
                        style: context.text.bodyLarge
                            ?.copyWith(color: context.surfaces.textTertiary),
                        textAlign: TextAlign.center,
                      ).animate(key: ValueKey('b$i')).fadeIn(delay: 100.ms),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: AppDuration.fast,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? context.colors.primary
                      : context.surfaces.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: GradientButton(
              label: isLast
                  ? context.l10n.onboardingGetStarted
                  : context.l10n.commonNext,
              icon: isLast ? Icons.rocket_launch_rounded : null,
              onPressed: () {
                if (isLast) {
                  _finish();
                } else {
                  _controller.nextPage(
                    duration: AppDuration.medium,
                    curve: AppCurves.standard,
                  );
                }
              },
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}
