import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'routes.dart';

/// Branded splash shown while Firebase auth state resolves. The router's
/// redirect moves the user on to onboarding, welcome or home once known.
///
/// The full splash artwork (badge, wordmark, chest, coins, tagline and its
/// own "loading" bar) is the real brand image supplied by the team, shown
/// full-bleed — no part of it is drawn or generated in code. Since the art
/// already has its own loading affordance baked in, nothing else is layered
/// on top except the rare escape hatch below.
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(1.04, 1.04),
                  end: const Offset(1.0, 1.0),
                  duration: 900.ms,
                  curve: AppCurves.standard,
                ),
          ),
          if (_showEscapeHatch)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: SafeArea(
                top: false,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.welcome),
                        child: Text(
                          'Taking longer than expected — Tap to continue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
