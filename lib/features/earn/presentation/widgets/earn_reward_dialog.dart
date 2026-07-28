import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';

/// A celebratory "you earned N coins" dialog with a spring pop and glow.
Future<void> showEarnRewardDialog(BuildContext context,
    {required int coins}) async {
  HapticFeedback.heavyImpact();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => _RewardDialog(coins: coins),
  );
}

class _RewardDialog extends StatelessWidget {
  const _RewardDialog({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.surfaces.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.surfaces.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: AppGradients.coin,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 56, color: AppColors.black),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    curve: AppCurves.spring,
                    duration: AppDuration.slow)
                .then()
                .shimmer(duration: 900.ms, color: Colors.white54),
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.earnRewardEarnedTitle,
                    style: context.text.headlineSmall,
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text('+$coins',
                    style: AppTypography.counter(36, AppColors.coin)),
              ],
            ).animate().fadeIn(delay: 300.ms).scale(curve: AppCurves.spring),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: context.l10n.commonContinue,
              onPressed: () => Navigator.of(context).pop(),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
