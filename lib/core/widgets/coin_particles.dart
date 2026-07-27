import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An ambient field of slowly rising, shimmering gold coins rendered behind
/// hero content (home header, reward dialogs). Pure [CustomPaint] with a single
/// controller and a [RepaintBoundary], so it adds premium motion at ~zero cost
/// even on low-end devices.
class CoinParticles extends StatefulWidget {
  const CoinParticles({
    super.key,
    this.count = 14,
    this.color = AppColors.coin,
    this.maxRadius = 7,
    this.speed = 1,
  });

  final int count;
  final Color color;
  final double maxRadius;
  final double speed;

  @override
  State<CoinParticles> createState() => _CoinParticlesState();
}

class _CoinParticlesState extends State<CoinParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final List<_Particle> _particles = List.generate(
    widget.count,
    (i) => _Particle.random(math.Random(i * 7 + 3), widget.maxRadius),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _CoinPainter(
            particles: _particles,
            t: _c.value,
            color: widget.color,
            speed: widget.speed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle(this.x, this.phase, this.radius, this.drift, this.opacity);
  final double x; // 0..1
  final double phase; // 0..1 vertical offset
  final double radius;
  final double drift; // horizontal wobble amplitude
  final double opacity;

  factory _Particle.random(math.Random r, double maxRadius) => _Particle(
        r.nextDouble(),
        r.nextDouble(),
        2 + r.nextDouble() * (maxRadius - 2),
        (r.nextDouble() - 0.5) * 0.06,
        0.25 + r.nextDouble() * 0.5,
      );
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({
    required this.particles,
    required this.t,
    required this.color,
    required this.speed,
  });

  final List<_Particle> particles;
  final double t;
  final Color color;
  final double speed;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (p.phase + t * speed) % 1.0;
      final y = size.height * (1.0 - progress); // rise upward
      final wobble = math.sin(progress * 2 * math.pi * 2) * p.drift;
      final x = (p.x + wobble) * size.width;
      // Fade in at bottom, out at top.
      final edge = math.sin(progress * math.pi);
      final alpha = (p.opacity * edge).clamp(0.0, 1.0);

      final glow = Paint()
        ..color = color.withOpacity(alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), p.radius * 1.6, glow);

      final body = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.4)!.withOpacity(alpha),
            color.withOpacity(alpha),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: p.radius));
      canvas.drawCircle(Offset(x, y), p.radius, body);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.t != t;
}
