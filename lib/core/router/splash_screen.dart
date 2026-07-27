import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_rain.dart';
import '../widgets/premium_loader.dart';
import 'routes.dart';

/// Branded splash shown while Firebase auth state resolves. The router's
/// redirect moves the user on to onboarding, welcome or home once known.
///
/// The Robux Box emblem springs in over a breathing glow, with a field of
/// gold R$ coins raining gently behind it — the app should feel alive before
/// the first frame of real content.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Defence in depth against ever trapping a user here: authStateProvider
  // already has its own timeout that forces the router to move on, but if
  // some other future bug keeps this screen mounted, a manual way out
  // appears after a while rather than leaving a dead end.
  bool _showEscapeHatch = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showEscapeHatch = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CoinRain(count: 22, speed: 0.55),
          ),
          const Center(child: _SplashLogo()),
          if (_showEscapeHatch)
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.welcome),
                  child: Text(
                    'Taking longer than expected — Tap to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),
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
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withOpacity(0.35),
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
            // The brand emblem — treasure crate + spilling R$ coins inside a
            // glowing frame, baked as one crisp image (see tool/generate_icon.py).
            Image.asset(
              'assets/images/splash_logo.png',
              width: 176,
              height: 176,
            )
                .animate()
                .scale(
                    begin: const Offset(0.6, 0.6),
                    curve: AppCurves.spring,
                    duration: 700.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
        const SizedBox(height: 20),
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
