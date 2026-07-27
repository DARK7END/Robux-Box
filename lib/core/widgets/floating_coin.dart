import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_dimens.dart';

/// A single R$ coin that bursts outward from the crate on entrance (spring
/// scale + fade, staggered by [delay]), then settles into a continuous,
/// organic bob-and-sway loop for as long as it's on screen — used on the
/// splash screen so the coins genuinely move instead of sitting baked into a
/// static image.
class FloatingCoin extends StatefulWidget {
  const FloatingCoin({
    super.key,
    required this.size,
    this.rotation = 0,
    this.delay = Duration.zero,
    this.bobSeed = 0,
  });

  final double size;

  /// Resting tilt, in radians.
  final double rotation;
  final Duration delay;

  /// Varies the bob duration/phase per instance so coins don't move in
  /// lockstep — pass the loop index.
  final int bobSeed;

  @override
  State<FloatingCoin> createState() => _FloatingCoinState();
}

class _FloatingCoinState extends State<FloatingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2200 + (widget.bobSeed % 5) * 260),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bob.value);
        return Transform.translate(
          offset: Offset(0, -7 * t),
          child: Transform.rotate(
            angle: widget.rotation + (t - 0.5) * 0.16,
            child: child,
          ),
        );
      },
      child: Image.asset('assets/images/coin.png',
          width: widget.size, height: widget.size),
    )
        .animate(delay: widget.delay)
        .scale(
          begin: const Offset(0.15, 0.15),
          curve: AppCurves.spring,
          duration: 650.ms,
        )
        .fadeIn(duration: 350.ms)
        .then(delay: 200.ms)
        .shimmer(duration: 1400.ms, color: const Color(0x88FFFFFF));
  }
}
