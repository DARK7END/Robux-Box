import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_dimens.dart';

/// A universal tactile wrapper: press it and it "squishes" with a spring and a
/// haptic tick, then springs back. This is the single source of the app's
/// game-like touch feel — used by cards, tiles and chips so every interactive
/// surface reacts identically (and nothing relies on the generic Material
/// ripple, which reads as "template").
///
/// Cheap: one implicit [AnimatedScale]; no controllers, no repaint churn.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.965,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool v) {
    if (!_active) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _active
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      onLongPress: _active && widget.onLongPress != null
          ? () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: _down ? AppDuration.instant : AppDuration.fast,
        curve: _down ? Curves.easeOut : AppCurves.spring,
        child: widget.child,
      ),
    );
  }
}
