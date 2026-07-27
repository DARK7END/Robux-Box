import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../models/offer.dart';

/// Premium offer/task card: brand icon, title, difficulty, ETA, reward and a
/// progress bar for multi-step offers.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onTap});

  final Offer offer;
  final VoidCallback onTap;

  (String, Color) _difficulty(BuildContext context) {
    if (offer.rewardCoins >= 15000) {
      return (context.l10n.difficultyHard, AppColors.danger);
    }
    if (offer.rewardCoins >= 4000) {
      return (context.l10n.difficultyMedium, AppColors.warning);
    }
    return (context.l10n.difficultyEasy, AppColors.brand);
  }

  int get _etaMinutes => switch (offer.category) {
        OfferCategory.survey => 6,
        OfferCategory.video => 3,
        OfferCategory.app => 10,
        OfferCategory.signup => 4,
        OfferCategory.game => 30,
        OfferCategory.purchase => 15,
        OfferCategory.other => 8,
      };

  IconData get _icon => switch (offer.category) {
        OfferCategory.survey => Icons.assignment_rounded,
        OfferCategory.game => Icons.sports_esports_rounded,
        OfferCategory.app => Icons.download_rounded,
        OfferCategory.video => Icons.play_circle_rounded,
        OfferCategory.signup => Icons.person_add_rounded,
        OfferCategory.purchase => Icons.shopping_bag_rounded,
        OfferCategory.other => Icons.bolt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final (diffLabel, diffColor) = _difficulty(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Icon(offer: offer, fallbackIcon: _icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.title,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (offer.provider.isNotEmpty)
                  Text(offer.provider,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusPill(label: diffLabel, color: diffColor, dense: true),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.schedule_rounded,
                        size: 13, color: context.surfaces.textTertiary),
                    const SizedBox(width: 3),
                    Text(context.l10n.tasksEta(_etaMinutes),
                        style: context.text.labelSmall),
                  ],
                ),
                if (offer.isMultiStep) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: 0.0,
                      minHeight: 5,
                      backgroundColor: context.surfaces.surfaceHigh,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coin.withOpacity(0.14),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        size: 14, color: AppColors.coin),
                    const SizedBox(width: 3),
                    Text('${offer.rewardCoins}',
                        style: context.text.labelMedium?.copyWith(
                          color: AppColors.coin,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: context.surfaces.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.offer, required this.fallbackIcon});
  final Offer offer;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: context.colors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: offer.iconUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: offer.iconUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Icon(fallbackIcon, color: context.colors.primary),
            )
          : Icon(fallbackIcon, color: context.colors.primary, size: 26),
    );
  }
}
