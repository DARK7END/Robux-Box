import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A small rounded status/label pill (used for tiers, redemption statuses,
/// VIP badges, etc.). Colour is tinted from [color].
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // On a filled pill, pick legible ink from the fill's brightness (dark on
    // bright tiers/gold, white on deep red/purple); otherwise use the colour.
    final fg = filled
        ? (color.computeLuminance() > 0.35 ? AppColors.black : AppColors.white)
        : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.14),
        borderRadius: AppRadius.pillRadius,
        border: filled
            ? null
            : Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 10 : 11,
                ),
          ),
        ],
      ),
    );
  }
}
