import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A field of gold "R$" coins gently falling from the top of the screen —
/// used on the splash screen so the very first frame the user sees feels like
/// a jackpot. Pure [CustomPainter] with a single controller and a shared,
/// laid-out-once [TextPainter] for the glyph, so it stays cheap at 60 FPS even
/// with a couple dozen coins on screen.
class CoinRain extends StatefulWidget {
  const CoinRain({super.key, this.count = 22, this.speed = 1});

  final int count;
  final double speed;

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _CoinRainState extends State<CoinRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final List<_Coin> _coins = List.generate(
    widget.count,
    (i) => _Coin.random(math.Random(i * 13 + 5)),
  );

  late final TextPainter _glyph = TextPainter(
    text: const TextSpan(
      text: 'R\$',
      style: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w900,
        fontSize: 13,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _CoinRainPainter(
              coins: _coins,
              t: _c.value,
              speed: widget.speed,
              glyph: _glyph,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Coin {
  _Coin(this.x, this.phase, this.radius, this.drift, this.spin, this.opacity);
  final double x; // 0..1 horizontal start
  final double phase; // 0..1 vertical offset so falls are staggered
  final double radius;
  final double drift; // horizontal sway amplitude
  final double spin; // full rotations over one fall cycle
  final double opacity;

  factory _Coin.random(math.Random r) => _Coin(
        r.nextDouble(),
        r.nextDouble(),
        7 + r.nextDouble() * 8,
        (r.nextDouble() - 0.5) * 0.10,
        (r.nextDouble() - 0.5) * 3,
        0.35 + r.nextDouble() * 0.5,
      );
}

class _CoinRainPainter extends CustomPainter {
  _CoinRainPainter({
    required this.coins,
    required this.t,
    required this.speed,
    required this.glyph,
  });

  final List<_Coin> coins;
  final double t;
  final double speed;
  final TextPainter glyph;

  static final Paint _ring = Paint()..style = PaintingStyle.fill;
  static final Paint _face = Paint()..color = AppColors.brandDeep;
  static final Paint _rim = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFE8A3);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in coins) {
      final progress = (c.phase + t * speed) % 1.0;
      final y = size.height * progress - c.radius * 2;
      final wobble = math.sin(progress * 2 * math.pi * 2) * c.drift;
      final x = (c.x + wobble) * size.width;
      // Fade in at top, out near the bottom.
      final edge = math.sin(progress * math.pi).clamp(0.0, 1.0);
      final alpha = c.opacity * edge;
      if (alpha <= 0.02) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * c.spin * 2 * math.pi);

      _ring.color = AppColors.coin.withValues(alpha: alpha);
      canvas.drawCircle(Offset.zero, c.radius, _ring);
      _rim.color = const Color(0xFFFFE8A3).withValues(alpha: alpha);
      _rim.strokeWidth = c.radius * 0.16;
      canvas.drawCircle(Offset.zero, c.radius * 0.86, _rim);
      _face.color = AppColors.brandDeep.withValues(alpha: alpha);
      canvas.drawCircle(Offset.zero, c.radius * 0.68, _face);

      final scale = c.radius / 16;
      canvas.translate(-glyph.width * scale / 2, -glyph.height * scale / 2);
      canvas.scale(scale);
      // saveLayer so the glyph fades in step with the ring/face above instead
      // of staying at the TextSpan's fixed opaque colour.
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, glyph.width, glyph.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      glyph.paint(canvas, Offset.zero);
      canvas.restore();

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CoinRainPainter old) => old.t != t;
}
