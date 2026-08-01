import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/vip_level_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../models/app_user.dart';

/// Shared All/Bronze/Silver/Gold/Diamond filter chip row — lets an admin
/// narrow any request queue (redemptions, tickets) down to one VIP tier.
class TierFilterRow extends StatelessWidget {
  const TierFilterRow(
      {super.key, required this.selected, required this.onSelect});
  final VipLevel? selected;
  final ValueChanged<VipLevel?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _TierChip(
              label: 'All',
              color: context.surfaces.textTertiary,
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
            for (final tier in const [
              VipLevel.bronze,
              VipLevel.silver,
              VipLevel.gold,
              VipLevel.diamond,
            ])
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: _TierChip(
                  label: tier.label,
                  color: tier.tierColor,
                  selected: selected == tier,
                  onTap: () => onSelect(tier),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected ? color.withOpacity(0.22) : context.surfaces.surfaceHigh,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: selected ? color : context.surfaces.border),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: selected ? color : context.surfaces.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
