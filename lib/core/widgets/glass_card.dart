import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The app's primary surface.
///
/// Redesigned for a premium, "console UI" feel: a solid tinted panel with a
/// gentle top-lit gradient, a hairline highlight along the top edge, a subtle
/// border and a two-layer elevation shadow. Tapping springs the card (via
/// [Pressable]) instead of a generic Material ripple.
///
/// Performance: by default there is **no** `BackdropFilter`, so hundreds of
/// these can scroll at 60 FPS on low-end devices. Real frosted glass is reserved
/// for overlays (nav bar, sheets) by passing [blur] > 0.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.cardRadius,
    this.blur = 0,
    this.onTap,
    this.gradient,
    this.highlight = true,
    this.borderColor,
    this.fillColor,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;

  /// When > 0, renders real frosted glass (backdrop blur). Default 0 (solid,
  /// fast). Use for overlays, not list items.
  final double blur;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool highlight;
  final Color? borderColor;
  final Color? fillColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final base = fillColor ?? surfaces.card;

    // Gentle top-lit gradient for depth (skipped when a custom gradient is set).
    final decoration = BoxDecoration(
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(Colors.white.withOpacity(0.05), base),
              base,
            ],
          ),
      borderRadius: borderRadius,
      border: Border.all(color: borderColor ?? surfaces.border),
      boxShadow: elevated ? AppShadows.elevated : null,
    );

    Widget inner = Stack(
      children: [
        if (highlight)
          Positioned(
            top: 0,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    Widget surface = DecoratedBox(decoration: decoration, child: inner);

    if (blur > 0) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: decoration.copyWith(
              gradient: gradient,
              color: gradient == null
                  ? (fillColor ?? surfaces.glassFill)
                  : null,
            ),
            child: inner,
          ),
        ),
      );
    } else {
      surface = ClipRRect(borderRadius: borderRadius, child: surface);
    }

    if (onTap != null) {
      surface = Pressable(onTap: onTap, child: surface);
    }

    return Padding(padding: margin, child: surface);
  }
}
