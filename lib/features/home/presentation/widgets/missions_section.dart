import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/r_glyph.dart';
import '../../../profile/data/user_repository.dart';

class _Mission {
  const _Mission(this.icon, this.title, this.current, this.target, this.reward,
      this.color);
  final IconData icon;
  final String title;
  final int current;
  final int target;
  final int reward;
  final Color color;

  double get ratio => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
  bool get done => current >= target;
}

/// Daily progress missions, derived live from the user's wallet + profile so
/// the bars fill as the player earns. No backend call needed to render.
class MissionsSection extends ConsumerWidget {
  const MissionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(currentWalletProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;

    final missions = <_Mission>[
      _Mission(Icons.play_circle_fill_rounded, 'Watch 5 ads',
          wallet?.adsWatchedToday ?? 0, 5, 50, AppColors.brand),
      _Mission(Icons.checklist_rounded, 'Complete an offer',
          (wallet?.offersCompletedTotal ?? 0).clamp(0, 1), 1, 100, AppColors.accent),
      _Mission(Icons.group_add_rounded, 'Invite a friend',
          (user?.referralCount ?? 0).clamp(0, 1), 1, 250, AppColors.secondary),
    ];

    return Column(
      children: missions
          .map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MissionTile(mission: m),
              ))
          .toList(),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});
  final _Mission mission;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mission.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(mission.icon, color: mission.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(mission.title,
                            style: context.text.titleSmall)),
                    Text('${mission.current}/${mission.target}',
                        style: context.text.labelSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: mission.ratio),
                    duration: AppDuration.slow,
                    curve: AppCurves.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: context.surfaces.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(mission.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            children: [
              mission.done
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18)
                  : const RGlyph(size: 18, color: AppColors.coin),
              Text('+${mission.reward}',
                  style: context.text.labelSmall
                      ?.copyWith(color: AppColors.coin)),
            ],
          ),
        ],
      ),
    );
  }
}
