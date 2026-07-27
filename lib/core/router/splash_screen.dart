import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_gradients.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_particles.dart';
import '../widgets/premium_loader.dart';

/// Branded splash shown while Firebase auth state resolves. The router's
/// redirect moves the user on to onboarding, welcome or home once known.
///
/// A treasure-box emblem springs in over a breathing glow, with an ambient
/// coin field rising behind it — the app should feel alive before the first
/// frame of content.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      showAppBar: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CoinParticles(count: 16, speed: 0.7)),
          ),
          Center(child: _SplashLogo()),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Breathing halo behind the emblem.
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withOpacity(0.45),
                    AppColors.brand.withOpacity(0.0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    begin: 0.85,
                    end: 1.15,
                    duration: 1800.ms,
                    curve: Curves.easeInOut),
            // The emblem.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.glow(AppColors.brand),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 46, color: AppColors.black),
            )
                .animate()
                .scale(
                    begin: const Offset(0.6, 0.6),
                    curve: AppCurves.spring,
                    duration: 700.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineMedium,
            children: const [
              TextSpan(text: 'Robux '),
              TextSpan(text: 'Box', style: TextStyle(color: AppColors.brand)),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 220.ms, duration: 500.ms)
            .slideY(begin: 0.4, curve: AppCurves.standard)
            .then()
            .shimmer(duration: 1400.ms, color: AppColors.brand),
        const SizedBox(height: 6),
        Text('Play. Earn. Redeem.', style: theme.textTheme.bodyMedium)
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 28),
        const PremiumLoader(size: 30)
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms),
      ],
    );
  }
}
