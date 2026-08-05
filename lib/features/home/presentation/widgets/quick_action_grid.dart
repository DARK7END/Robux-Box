import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/glass_card.dart';

/// 2×2 grid of primary earn/redeem/invite actions.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.play_circle_fill_rounded, context.l10n.homeWatchAd,
          AppColors.brand, () => context.go(AppRoutes.earn)),
      _Action(Icons.checklist_rounded, context.l10n.homeOffers,
          AppColors.accent, () => context.go(AppRoutes.tasks)),
      _Action(Icons.card_giftcard_rounded, context.l10n.homeRedeem,
          AppColors.robux, () => context.go(AppRoutes.rewards)),
      _Action(Icons.group_add_rounded, context.l10n.homeInvite,
          AppColors.coinDeep, () => context.push(AppRoutes.referrals)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 6.2,
      children: actions
          .map(
            (a) => GlassCard(
              onTap: a.onTap,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(a.icon, color: a.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      a.label,
                      style: context.text.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
