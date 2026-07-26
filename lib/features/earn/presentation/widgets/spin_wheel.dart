import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A custom-painted prize wheel. [prizes] label each segment; [rotation] (in
/// radians) is driven by the parent's animation so the wheel can be spun to land
/// on an exact server-decided segment.
class SpinWheel extends StatelessWidget {
  const SpinWheel({
    super.key,
    required this.prizes,
    required this.rotation,
    this.size = 300,
  });

  final List<int> prizes;
  final double rotation;
  final double size;

  static const _segmentColors = [
    AppColors.brand,
    Color(0xFF141414),
    AppColors.accent,
    Color(0xFF141414),
    AppColors.secondary,
    Color(0xFF141414),
    AppColors.brand,
    Color(0xFF141414),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rim glow.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              size: Size(size, size),
              painter: _WheelPainter(
                prizes: prizes,
                rotation: rotation,
                colors: _segmentColors,
              ),
            ),
          ),
          // Center hub.
          Container(
            width: size * 0.22,
            height: size * 0.22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF101010)],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.monetization_on_rounded,
                color: AppColors.coin, size: size * 0.11),
          ),
          // Pointer at the top.
          Positioned(
            top: -2,
            child: CustomPaint(
              size: const Size(30, 30),
              painter: _PointerPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.prizes,
    required this.rotation,
    required this.colors,
  });

  final List<int> prizes;
  final double rotation;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final n = prizes.length;
    final seg = 2 * math.pi / n;
    final start = -math.pi / 2 - seg / 2; // segment 0 centered at top

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < n; i++) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];
      final a0 = start + i * seg;
      canvas.drawArc(rect, a0, seg, true, paint);

      // Divider line.
      final divider = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, a0, seg, true, divider);

      // Prize label.
      final labelAngle = a0 + seg / 2;
      final lr = radius * 0.66;
      final pos = Offset(
        center.dx + lr * math.cos(labelAngle),
        center.dy + lr * math.sin(labelAngle),
      );
      final isDark = colors[i % colors.length] == const Color(0xFF141414);
      final tp = TextPainter(
        text: TextSpan(
          text: '${prizes[i]}',
          style: TextStyle(
            color: isDark ? AppColors.coin : AppColors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(labelAngle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Outer rim.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.brand;
    canvas.drawCircle(center, radius - 3, rim);

    // Rim light dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < n * 2; i++) {
      final a = i * (math.pi / n);
      final p = Offset(
        center.dx + (radius - 3) * math.cos(a),
        center.dy + (radius - 3) * math.sin(a),
      );
      canvas.drawCircle(p, 2.2, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.rotation != rotation;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = AppColors.coin);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
