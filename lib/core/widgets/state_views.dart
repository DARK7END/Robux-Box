import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// Reusable empty-state view with an illustration slot, title, message and an
/// optional CTA.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.iconWidget,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Overrides [icon] with a real-artwork widget when set.
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow ring behind the emblem.
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withOpacity(0.16),
                        primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.22)),
                  ),
                  child: iconWidget ?? Icon(icon, size: 38, color: primary),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                        begin: 0,
                        end: -6,
                        duration: 2200.ms,
                        curve: Curves.easeInOut),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: AppCurves.spring),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 120.ms)
                .slideY(begin: 0.2, curve: AppCurves.standard),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              GradientButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable error view for failed async loads.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.danger.withOpacity(0.24)),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: AppColors.danger),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: AppCurves.spring)
                .shakeX(hz: 3, amount: 2, delay: 300.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 140.ms),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              GradientButton(
                label: context.l10n.commonRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expand: false,
              ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.3),
            ],
          ],
        ),
      ),
    );
  }
}

/// A shimmering placeholder box for skeleton loading states.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Shimmer.fromColors(
      baseColor: surfaces.surfaceHigh,
      highlightColor: surfaces.glassFill,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: surfaces.surfaceHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
