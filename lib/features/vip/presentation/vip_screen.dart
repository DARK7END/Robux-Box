import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_user.dart';
import '../../profile/data/user_repository.dart';

/// Presents the VIP tiers and multipliers, highlighting the user's current
/// level. Purchasing/unlocking is intentionally routed through the backend
/// (`upgradeVip`) and store billing — this screen is the storefront.
class VipScreen extends ConsumerWidget {
  const VipScreen({super.key});

  static const _tierOrder = [
    VipLevel.none,
    VipLevel.bronze,
    VipLevel.silver,
    VipLevel.gold,
    VipLevel.diamond,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final current = user?.vipLevel ?? VipLevel.none;

    return AppScaffold(
      title: context.l10n.vipTitle,
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          GlassCard(
            gradient: AppGradients.vip,
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.black, size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.vipSubtitle,
                    style: context.text.titleMedium
                        ?.copyWith(color: AppColors.black),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.vipCurrentTier(_label(current)),
                  style: context.text.bodyMedium
                      ?.copyWith(color: Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._tierOrder.where((t) => t != VipLevel.none).map((tier) {
            final multiplier = AppConstants.vipMultipliers[tier.name] ?? 1.0;
            final isCurrent = tier == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _VipTierCard(
                tier: tier,
                label: _label(tier),
                multiplier: multiplier,
                isCurrent: isCurrent,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _label(VipLevel level) =>
      level.name[0].toUpperCase() + level.name.substring(1);
}

class _VipTierCard extends StatelessWidget {
  const _VipTierCard({
    required this.tier,
    required this.label,
    required this.multiplier,
    required this.isCurrent,
  });

  final VipLevel tier;
  final String label;
  final double multiplier;
  final bool isCurrent;

  Color get _color => switch (tier) {
        VipLevel.bronze => const Color(0xFFCD7F32),
        VipLevel.silver => const Color(0xFFC0C4CE),
        VipLevel.gold => AppColors.coin,
        VipLevel.diamond => AppColors.secondary,
        VipLevel.none => AppColors.darkTextTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: isCurrent ? _color : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.military_tech_rounded, color: _color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.titleMedium),
                Text(
                  context.l10n.vipMultiplier(multiplier.toStringAsFixed(2)),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          if (isCurrent)
            StatusPill(
                label: context.l10n.vipActiveLabel,
                color: _color,
                filled: true,
                dense: true)
          else
            const Icon(Icons.lock_outline_rounded, size: 18),
        ],
      ),
    );
  }
}
