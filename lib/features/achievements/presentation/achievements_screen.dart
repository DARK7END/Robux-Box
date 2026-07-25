import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/achievement.dart';
import '../data/achievement_repository.dart';

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
    return AppScaffold(
      title: context.l10n.achievementsTitle,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateView(
              icon: Icons.emoji_events_rounded,
              title: context.l10n.commonComingSoon,
              message: 'Start earning to unlock achievements!',
            );
          }
          final unlocked = items.where((a) => a.isUnlocked).length;
          return ListView(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + AppSpacing.lg, bottom: 40),
            children: [
              Text(context.l10n.achievementsUnlocked(unlocked),
                  style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...items.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _AchievementTile(achievement: a, icon: _icon(a.icon)),
                  )),
            ],
          );
        },
      ),
    );
  }
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  child: LinearProgressIndicator(
                    value: achievement.ratio,
                    minHeight: 6,
                    backgroundColor: context.surfaces.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(color),
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
              const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 16),
              Text('+${achievement.rewardCoins}',
                  style: context.text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
