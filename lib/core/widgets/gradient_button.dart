import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_gradients.dart';
import 'premium_loader.dart';

/// A tactile, gradient-filled primary button with a press "squish" micro
/// interaction, an optional leading icon, a loading state and a glow.
///
/// This is the app's main call-to-action button — used for "Watch Ad",
/// "Redeem", "Continue", etc.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppGradients.brand,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.height = 54,
    this.expand = true,
    this.glow = true,
    this.foregroundColor,
    this.borderRadius = AppRadius.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final double height;
  final bool expand;
  final bool glow;
  final double borderRadius;

  /// Text/icon colour. When null it is derived from the gradient's brightness
  /// so labels stay legible on both bright (green/gold → dark ink) and deep
  /// (purple/red → white ink) fills.
  final Color? foregroundColor;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && !widget.loading && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_interactive) return;
    setState(() => _pressed = value);
  }

  /// Legible ink for the current gradient when no explicit colour is given:
  /// dark on bright fills (green/gold/cyan), white on deep fills (purple/red).
  Color get _foreground {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    final colors = widget.gradient.colors;
    final mean = colors.fold<double>(0, (s, c) => s + c.computeLuminance()) /
        colors.length;
    return mean > 0.35 ? AppColors.black : AppColors.white;
  }

  @override
  Widget build(BuildContext context) {
    final fg = _foreground;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: fg,
          fontSize: 15,
        );

    final button = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDuration.instant,
      curve: AppCurves.standard,
      child: AnimatedOpacity(
        opacity: _interactive ? 1 : 0.5,
        duration: AppDuration.fast,
        child: Container(
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.glow && _interactive
                ? AppShadows.glow(widget.gradient.colors.first)
                : null,
          ),
          child: widget.loading
              ? PremiumLoader(
                  size: 24,
                  strokeWidth: 2.6,
                  color: fg,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: fg),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    final tappable = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _interactive
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!.call();
            }
          : null,
      child: button,
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: tappable)
        : tappable;
  }
}
