import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// Ambient app background: the base scaffold color with two soft radial glows
/// layered on top, giving depth behind glass surfaces. Cheap to render (no
/// blur) and used as the root of every screen via [AppScaffold].
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaces = context.surfaces;
    return DecoratedBox(
      decoration: BoxDecoration(color: surfaces.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient:
                    isDark ? AppGradients.ambientDark : AppGradients.ambientLight,
              ),
            ),
          ),
          if (isDark)
            const Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: AppGradients.ambientDarkSecondary),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
