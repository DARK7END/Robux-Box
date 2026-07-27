import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'animated_counter.dart';

/// A compact coin balance chip: a gradient coin glyph followed by an animated
/// amount. Used in app bars and cards throughout the app.
class CoinBadge extends StatelessWidget {
  const CoinBadge({
    super.key,
    required this.amount,
    this.size = 16,
    this.animate = true,
    this.color = AppColors.coin,
  });

  final num amount;
  final double size;
  final bool animate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.counter(size, color);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size + 4,
            height: size + 4,
            decoration: const BoxDecoration(
              gradient: AppGradients.coin,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: size - 2, color: AppColors.black),
          ),
          const SizedBox(width: 6),
          if (animate)
            AnimatedCounter(value: amount, style: style)
          else
            Text(amount.round().toString(), style: style),
        ],
      ),
    );
  }
}
