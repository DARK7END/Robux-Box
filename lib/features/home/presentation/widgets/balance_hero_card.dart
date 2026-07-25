import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../models/app_user.dart';
import '../../../../models/wallet.dart';

/// The hero balance card: large animated coin counter, level progress and
/// lifetime stats over a brand gradient with a soft glow.
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key, required this.user, required this.wallet});

  final AppUser user;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.brand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.homeYourBalance,
                style: context.text.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              _StreakChip(streak: user.streakCount),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 34),
              const SizedBox(width: AppSpacing.sm),
              AnimatedCounter(
                value: wallet.coins,
                style: AppTypography.counter(40, AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.l10n.homeCoins,
                  style:
                      context.text.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _LevelProgress(user: user),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                label: context.l10n.walletEarned,
                value: wallet.lifetimeEarned,
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white24,
              ),
              _Stat(
                label: 'Multiplier',
                valueText: '${user.earningMultiplier.toStringAsFixed(2)}x',
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              _Stat(
                label: context.l10n.profileXp,
                value: user.xp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: LinearProgressIndicator(
            value: user.levelProgress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(AppColors.coin),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Level ${user.level} • ${user.xp}/${user.xpForNextLevel} XP',
          style: context.text.labelSmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.warning, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: context.text.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, this.value, this.valueText});
  final String label;
  final int? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        valueText != null
            ? Text(valueText!,
                style: AppTypography.counter(16, AppColors.white))
            : AnimatedCounter(
                value: value ?? 0,
                style: AppTypography.counter(16, AppColors.white),
              ),
        Text(label,
            style: context.text.labelSmall?.copyWith(color: Colors.white60)),
      ],
    );
  }
}
