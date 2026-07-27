import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_rain.dart';
import '../widgets/floating_coin.dart';
import '../widgets/premium_loader.dart';
import 'routes.dart';

/// Branded splash shown while Firebase auth state resolves. The router's
/// redirect moves the user on to onboarding, welcome or home once known.
///
/// A field of gold R$ coins bursts outward from the crate emblem and settles
/// into a gentle floating loop, slow light rays sweep behind it, and more
/// coins rain softly in the background — the app should feel alive and in
/// motion before the first frame of real content.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Defence in depth against ever trapping a user here: authStateProvider
  // already has its own timeout that forces the router to move on, but if
  // some other future bug keeps this screen mounted, a manual way out
  // appears after a while rather than leaving a dead end.
  bool _showEscapeHatch = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showEscapeHatch = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CoinRain(count: 16, speed: 0.5),
          ),
          const Center(child: _SplashLogo()),
          if (_showEscapeHatch)
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.welcome),
                  child: Text(
                    'Taking longer than expected — Tap to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  // Coins burst outward from the crate and settle at these offsets (relative
  // to the 320x320 stage below), each with its own size, resting tilt, entry
  // delay and bob phase so the whole cluster feels organic, not mechanical.
  static const _coins = [
    (size: 50.0, left: 128.0, top: 2.0, rot: -0.06, delay: 0, seed: 0),
    (size: 42.0, left: 56.0, top: 26.0, rot: -0.32, delay: 90, seed: 1),
    (size: 38.0, left: 208.0, top: 34.0, rot: 0.34, delay: 150, seed: 2),
    (size: 32.0, left: 168.0, top: 66.0, rot: 0.22, delay: 230, seed: 3),
    (size: 28.0, left: 92.0, top: 70.0, rot: -0.42, delay: 310, seed: 4),
    (size: 26.0, left: 232.0, top: 82.0, rot: 0.5, delay: 390, seed: 5),
    (size: 24.0, left: 42.0, top: 92.0, rot: -0.55, delay: 470, seed: 6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _LightRays()),
              // Breathing halo behind the emblem.
              Positioned(
                left: 60,
                top: 40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brand.withOpacity(0.32),
                        AppColors.brand.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                      begin: 0.85,
                      end: 1.15,
                      duration: 1800.ms,
                      curve: Curves.easeInOut),
              // The crate emblem — coins are separate widgets below so they
              // can move independently instead of being baked into the image.
              Positioned(
                left: 40,
                top: 90,
                child: Image.asset(
                  'assets/images/crate_badge.png',
                  width: 240,
                  height: 240,
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.6, 0.6),
                        curve: AppCurves.spring,
                        duration: 700.ms)
                    .fadeIn(duration: 400.ms),
              ),
              for (final c in _coins)
                Positioned(
                  left: c.left,
                  top: c.top,
                  child: FloatingCoin(
                    size: c.size,
                    rotation: c.rot,
                    delay: Duration(milliseconds: c.delay),
                    bobSeed: c.seed,
                  ),
                ),
            ],
          ),
        ),
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineMedium,
            children: const [
              TextSpan(text: 'Robux '),
              TextSpan(text: 'Box', style: TextStyle(color: AppColors.brand)),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 500.ms)
            .slideY(begin: 0.4, curve: AppCurves.standard)
            .then()
            .shimmer(duration: 1400.ms, color: AppColors.brand),
        const SizedBox(height: 6),
        Text('Play. Earn. Redeem.', style: theme.textTheme.bodyMedium)
            .animate()
            .fadeIn(delay: 650.ms, duration: 500.ms),
        const SizedBox(height: 18),
        const _HexDivider()
            .animate()
            .fadeIn(delay: 800.ms, duration: 500.ms)
            .scaleXY(begin: 0.7, curve: AppCurves.standard),
        const SizedBox(height: 22),
        const PremiumLoader(size: 30)
            .animate()
            .fadeIn(delay: 950.ms, duration: 500.ms),
      ],
    );
  }
}

/// Slow-rotating, blurred sweep-gradient spokes behind the emblem — a cheap
/// stand-in for radiating light beams. Pure decoration + one controller.
class _LightRays extends StatefulWidget {
  const _LightRays();

  @override
  State<_LightRays> createState() => _LightRaysState();
}

class _LightRaysState extends State<_LightRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _rayCount = 10;

  @override
  Widget build(BuildContext context) {
    final stops = <double>[];
    final colors = <Color>[];
    for (var i = 0; i < _rayCount; i++) {
      final center = i / _rayCount;
      const halfWidth = 0.03;
      stops
        ..add((center - halfWidth).clamp(0.0, 1.0))
        ..add(center)
        ..add((center + halfWidth).clamp(0.0, 1.0));
      colors.addAll([
        Colors.transparent,
        AppColors.brand.withOpacity(0.20),
        Colors.transparent,
      ]);
    }
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Transform.rotate(
            angle: _c.value * 2 * math.pi,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: colors, stops: stops),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny decorative divider — two fading brand-colour lines flanking a small
/// hex "R$" mark — echoing the crate's badge below the wordmark.
class _HexDivider extends StatelessWidget {
  const _HexDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(reversed: true),
        const SizedBox(width: 10),
        const SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(painter: _HexPainter()),
        ),
        const SizedBox(width: 10),
        _line(reversed: false),
      ],
    );
  }

  Widget _line({required bool reversed}) {
    final colors = [
      AppColors.brand.withOpacity(0.0),
      AppColors.brand.withOpacity(0.7),
    ];
    return Container(
      width: 28,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reversed ? colors.reversed.toList() : colors,
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'R\$',
        style: TextStyle(
          color: AppColors.brand,
          fontSize: size.width * 0.42,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) => false;
}
