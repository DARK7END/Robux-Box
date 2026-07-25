import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../models/app_user.dart';

/// Compact card showing the user's geo-derived earning tier and multiplier.
class TierCard extends StatelessWidget {
  const TierCard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final tier = user.tier;
    final color = AppColors.tierColor(tier.level);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public_rounded, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(context.l10n.homeYourTier,
                    style: context.text.labelMedium,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusPill(label: tier.label, color: color, filled: true),
              const SizedBox(width: AppSpacing.sm),
              Text(user.countryCode, style: context.text.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.homeTierMultiplier(tier.multiplier.toStringAsFixed(2)),
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
