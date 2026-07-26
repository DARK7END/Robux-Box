import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../models/reward.dart';

/// A single catalogue reward tile.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.affordable,
    required this.onTap,
  });

  final Reward reward;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (reward.kind) {
      RewardKind.robux => AppGradients.robux,
      RewardKind.giftCard => AppGradients.neon,
      RewardKind.digitalCode => AppGradients.vip,
    };

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'reward_${reward.id}',
            child: Stack(
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg)),
                ),
                child: reward.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg)),
                        child: CachedNetworkImage(
                          imageUrl: reward.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.card_giftcard_rounded,
                              color: AppColors.white,
                              size: 40),
                        ),
                      )
                    : Center(
                        child: Icon(
                          switch (reward.kind) {
                            RewardKind.robux => Icons.paid_rounded,
                            RewardKind.giftCard => Icons.card_giftcard_rounded,
                            RewardKind.digitalCode => Icons.vpn_key_rounded,
                          },
                          color: AppColors.white,
                          size: 40,
                        ),
                      ),
              ),
              if (reward.badge.isNotEmpty)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: StatusPill(
                    label: reward.badge,
                    color: AppColors.coin,
                    filled: true,
                    dense: true,
                  ),
                ),
            ],
          ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (reward.subtitle.isNotEmpty)
                  Text(reward.subtitle,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.coin, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.rewardsCost(reward.coinCost),
                      style: context.text.labelMedium?.copyWith(
                        color: affordable
                            ? context.colors.onSurface
                            : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
