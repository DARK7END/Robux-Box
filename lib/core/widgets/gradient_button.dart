import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_gradients.dart';

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
    this.foregroundColor = AppColors.white,
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
  final Color foregroundColor;

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

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: widget.foregroundColor,
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
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: widget.glow && _interactive
                ? AppShadows.glow(widget.gradient.colors.first)
                : null,
          ),
          child: widget.loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.foregroundColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: widget.foregroundColor),
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
