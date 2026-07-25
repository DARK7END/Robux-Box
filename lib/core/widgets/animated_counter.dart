import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Smoothly tweens between numeric values — used for coin/XP balances so a
/// credit "rolls up" instead of snapping. Uses tabular figures via the passed
/// [style] to avoid horizontal jitter.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = AppDuration.counter,
    this.curve = AppCurves.standard,
    this.prefix = '',
    this.suffix = '',
    this.separator = ',',
  });

  final num value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final String separator;

  String _format(num v) {
    final intPart = v.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(separator);
      buffer.write(intPart[i]);
    }
    return '$prefix${buffer.toString()}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        return Text(_format(animatedValue), style: style);
      },
    );
  }
}
