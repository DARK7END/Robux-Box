import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A branded, GPU-cheap loading indicator used everywhere instead of the
/// generic [CircularProgressIndicator].
///
/// It draws a rotating neon arc with a soft glow and a pulsing core — reads as
/// "premium game" rather than "Material default". Single [AnimationController],
/// repaint-boundaried, so it stays at 60 FPS even on low-end devices.
class PremiumLoader extends StatefulWidget {
  const PremiumLoader({
    super.key,
    this.size = 44,
    this.color = AppColors.brand,
    this.strokeWidth = 3.5,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  State<PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ArcPainter(
              progress: _c.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = progress * 2 * math.pi;

    // Track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    // Glowing sweep
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [color.withValues(alpha: 0.0), color],
        transform: GradientRotation(startAngle),
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(rect, startAngle, math.pi * 1.4, false, sweep);

    // Pulsing core
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final core = Paint()
      ..color = color.withValues(alpha: 0.25 + 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * 0.28 * (0.8 + 0.2 * pulse), core);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

/// Full-screen centered loader with an optional label.
class PremiumLoadingView extends StatelessWidget {
  const PremiumLoadingView({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumLoader(),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
