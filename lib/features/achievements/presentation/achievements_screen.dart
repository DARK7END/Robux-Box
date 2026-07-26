import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/achievement.dart';
import '../data/achievement_repository.dart';
import 'widgets/badges_grid.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  IconData _icon(String key) => switch (key) {
        'first_earn' => Icons.bolt_rounded,
        'streak' => Icons.local_fire_department_rounded,
        'offers' => Icons.assignment_turned_in_rounded,
        'referrals' => Icons.group_rounded,
        'redeem' => Icons.card_giftcard_rounded,
        'level' => Icons.arrow_upward_rounded,
        _ => Icons.emoji_events_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(achievementsProvider);
    final items = async.valueOrNull ?? const <Achievement>[];
    final unlocked = items.where((a) => a.isUnlocked).length;

    return AppScaffold(
      title: context.l10n.achievementsTitle,
      body: ListView(
        padding: const EdgeInsets.only(
            top: kToolbarHeight + AppSpacing.lg, bottom: 40),
        children: [
          _ProgressHeader(
            unlocked: unlocked,
            total: items.isEmpty ? 0 : items.length,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: context.l10n.badgesTitle,
            icon: Icons.military_tech_rounded,
          ),
          const BadgesGrid(),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: context.l10n.achievementsTitle,
            icon: Icons.emoji_events_rounded,
          ),
          if (async.isLoading)
            ...List.generate(
                4,
                (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: ShimmerBox(height: 92, radius: AppRadius.lg),
                    ))
          else if (items.isEmpty)
            EmptyStateView(
              icon: Icons.emoji_events_rounded,
              title: context.l10n.commonComingSoon,
              message: 'Keep earning to unlock achievements!',
            )
          else
            ...items.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AchievementTile(achievement: a, icon: _icon(a.icon)),
                )),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: AppDuration.slow,
                  curve: AppCurves.standard,
                  builder: (context, value, _) => CustomPaint(
                    size: const Size(84, 84),
                    painter: _RingPainter(value),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$unlocked',
                        style: AppTypography.counter(22, AppColors.brand)),
                    Text('of $total', style: context.text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your progress', style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Complete tasks to unlock rewards and badges.'
                      : 'You\'ve unlocked ${(ratio * 100).round()}% of all achievements. Keep going!',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.brand.withValues(alpha: 0.14);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..shader = const SweepGradient(
        colors: [AppColors.brand, AppColors.brandBright],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.icon});
  final Achievement achievement;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? AppColors.coin : context.surfaces.textTertiary;
    return GlassCard(
      borderColor: unlocked ? AppColors.coin.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: AppColors.coin.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(unlocked ? icon : Icons.lock_outline_rounded,
                color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: context.text.titleSmall),
                Text(achievement.description, style: context.text.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: achievement.ratio),
                    duration: AppDuration.slow,
                    curve: AppCurves.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: context.surfaces.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${achievement.progress}/${achievement.target}',
                    style: context.text.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: AppColors.coin, size: 18),
              Text('+${achievement.rewardCoins}',
                  style: context.text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
