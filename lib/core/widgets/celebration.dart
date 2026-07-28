import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'gradient_button.dart';
import 'r_glyph.dart';

/// Full-screen success celebration: dual confetti blasters, a spring-popped
/// glowing badge, an animated coin figure and confetti in the brand palette.
/// Used for successful redemptions and big rewards.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
  int? coins,
  IconData icon = Icons.check_rounded,
}) async {
  HapticFeedback.heavyImpact();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    barrierColor: Colors.black.withOpacity(0.82),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) =>
        _CelebrationView(title: title, message: message, coins: coins, icon: icon),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

class _CelebrationView extends StatefulWidget {
  const _CelebrationView({
    required this.title,
    required this.message,
    required this.coins,
    required this.icon,
  });

  final String title;
  final String message;
  final int? coins;
  final IconData icon;

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView> {
  late final ConfettiController _left =
      ConfettiController(duration: const Duration(seconds: 2));
  late final ConfettiController _right =
      ConfettiController(duration: const Duration(seconds: 2));

  static const _palette = [
    AppColors.brand,
    AppColors.secondary,
    AppColors.accent,
    AppColors.brandBright,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _left.play();
    _right.play();
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti blasters from the top corners.
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _left,
            blastDirection: math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 16,
            gravity: 0.25,
            colors: _palette,
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _right,
            blastDirection: 3 * math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 16,
            gravity: 0.25,
            colors: _palette,
          ),
        ),
        // Content card.
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlowBadge(icon: widget.icon),
              const SizedBox(height: AppSpacing.xxl),
              Text(widget.title,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.3, curve: AppCurves.spring),
              const SizedBox(height: AppSpacing.sm),
              if (widget.coins != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RGlyph(size: 30, color: AppColors.coin),
                    const SizedBox(width: AppSpacing.sm),
                    Text('+${widget.coins}',
                        style: AppTypography.counter(38, AppColors.coin)),
                  ],
                ).animate().fadeIn(delay: 320.ms).scale(curve: AppCurves.spring),
              const SizedBox(height: AppSpacing.sm),
              Text(widget.message,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 420.ms),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: 220,
                child: GradientButton(
                  label: context.l10n.commonAwesome,
                  icon: Icons.celebration_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ).animate().fadeIn(delay: 520.ms),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowBadge extends StatelessWidget {
  const _GlowBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.6),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 64, color: AppColors.black),
    )
        .animate()
        .scale(
            begin: const Offset(0, 0),
            duration: 600.ms,
            curve: AppCurves.spring)
        .then()
        .shimmer(duration: 1100.ms, color: Colors.white.withOpacity(0.5));
  }
}
