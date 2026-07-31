import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';

class _Page {
  const _Page({
    required this.title,
    required this.body,
    required this.glow,
    this.image,
    this.icon,
  });

  final String title;
  final String body;
  final Color glow;

  /// Real uploaded artwork, shown as-is — never generated.
  final String? image;

  /// Fallback glyph for the one page with no matching real artwork.
  final IconData? icon;
}

/// Three-slide intro shown once on first launch. Persists a "seen" flag so it
/// never blocks returning users.
///
/// No Lottie/Rive here: those need real animation files, and there are none
/// in the project to use — the same "only real, supplied assets" rule that
/// applies to images applies to motion files. Instead the "large 3D
/// illustration" feel comes from layering the two real uploaded images
/// (the coin and the chest) inside glowing glass discs with parallax,
/// idle-float and orbiting-coin motion, all built from Flutter's own
/// animation APIs (already used everywhere else in the app).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Page> _pages(BuildContext context) => [
        _Page(
          title: context.l10n.onboardingTitle1,
          body: context.l10n.onboardingBody1,
          image: 'assets/images/currency_coin.png',
          glow: AppColors.brand,
        ),
        _Page(
          title: context.l10n.onboardingTitle2,
          body: context.l10n.onboardingBody2,
          image: 'assets/images/chest_icon.png',
          glow: AppColors.coin,
        ),
        _Page(
          title: context.l10n.onboardingTitle3,
          body: context.l10n.onboardingBody3,
          icon: Icons.shield_moon_rounded,
          glow: AppColors.info,
        ),
      ];

  Future<void> _finish() async {
    await ref.read(preferencesProvider).setOnboardingSeen(true);
    if (mounted) context.go(AppRoutes.welcome);
  }

  double _livePage() {
    if (_controller.hasClients && _controller.page != null) {
      return _controller.page!;
    }
    return _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OnboardingBackground(),
          const Positioned.fill(
            child: IgnorePointer(child: _FloatingCoins(count: 9)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        context.l10n.commonSkip,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final distance =
                              (_livePage() - i).abs().clamp(0.0, 1.0);
                          return Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 460),
                              child: Opacity(
                                opacity: 1 - distance * 0.55,
                                child: Transform.scale(
                                  scale: 1 - distance * 0.12,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: _OnboardPage(page: pages[i], index: i),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) =>
                      _Indicator(count: pages.length, page: _livePage()),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: GradientButton(
                    label: isLast
                        ? context.l10n.onboardingGetStarted
                        : context.l10n.commonNext,
                    icon: isLast ? Icons.rocket_launch_rounded : null,
                    height: 56,
                    borderRadius: AppRadius.lg,
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: AppDuration.medium,
                          curve: AppCurves.standard,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: context.padding.bottom + AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Black-to-dark-green base with two soft ambient glow blobs for depth.
class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000),
                Color(0xFF071A0D),
                Color(0xFF0B2814),
                Color(0xFF050F09),
              ],
              stops: [0.0, 0.42, 0.75, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -110,
          left: -90,
          child: _GlowBlob(color: AppColors.brand.withOpacity(0.30), size: 320),
        ),
        Positioned(
          bottom: -150,
          right: -110,
          child:
              _GlowBlob(color: AppColors.brandDeep.withOpacity(0.26), size: 380),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

/// Small copies of the real coin artwork drifting upward, tumbling and
/// fading — the literal "floating Robux coins" ambient layer.
class _FloatingCoins extends StatefulWidget {
  const _FloatingCoins({required this.count});
  final int count;

  @override
  State<_FloatingCoins> createState() => _FloatingCoinsState();
}

class _FloatingCoinsState extends State<_FloatingCoins>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  late final List<_CoinSpec> _coins = List.generate(
    widget.count,
    (i) => _CoinSpec.random(math.Random(i * 13 + 5)),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: _coins.map((c) {
                final progress = (c.phase + _c.value * c.speed) % 1.0;
                final y = h * (1.0 - progress);
                final wobble =
                    math.sin(progress * 2 * math.pi * 1.4) * c.driftPx;
                final x = (c.xFrac * w + wobble).clamp(0.0, w - c.size);
                final edge = math.sin(progress * math.pi);
                final opacity = (c.baseOpacity * edge).clamp(0.0, 1.0);
                final angle = progress * 2 * math.pi * c.spin;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: angle,
                      child: Image.asset(
                        'assets/images/currency_coin.png',
                        width: c.size,
                        height: c.size,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _CoinSpec {
  const _CoinSpec({
    required this.xFrac,
    required this.phase,
    required this.size,
    required this.driftPx,
    required this.baseOpacity,
    required this.speed,
    required this.spin,
  });

  final double xFrac;
  final double phase;
  final double size;
  final double driftPx;
  final double baseOpacity;
  final double speed;
  final double spin;

  factory _CoinSpec.random(math.Random r) => _CoinSpec(
        xFrac: r.nextDouble(),
        phase: r.nextDouble(),
        size: 14 + r.nextDouble() * 16,
        driftPx: 10 + r.nextDouble() * 26,
        baseOpacity: 0.16 + r.nextDouble() * 0.28,
        speed: 0.55 + r.nextDouble() * 0.65,
        spin: (r.nextBool() ? 1 : -1) * (0.5 + r.nextDouble()),
      );
}

/// One slide: the glowing hero badge, then a frosted-glass panel with the
/// title/body. Wrapped in a scroll view so nothing overflows on short
/// phones — on anything taller it simply never needs to move.
class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.page, required this.index});
  final _Page page;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          _HeroBadge(page: page)
              .animate(key: ValueKey('hero$index'))
              .fadeIn(duration: AppDuration.slow)
              .scale(
                begin: const Offset(0.7, 0.7),
                curve: AppCurves.spring,
                duration: AppDuration.slow,
              ),
          const SizedBox(height: AppSpacing.xxxl),
          GlassCard(
            blur: 18,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            fillColor: Colors.white.withOpacity(0.06),
            borderColor: Colors.white.withOpacity(0.14),
            elevated: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page.title,
                  style: context.text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ).animate(key: ValueKey('t$index')).fadeIn().slideY(begin: 0.25),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  page.body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ).animate(key: ValueKey('b$index')).fadeIn(delay: 100.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The large glowing "3D" hero: an outer soft glow, a slowly rotating ring, a
/// frosted glass disc that idles up and down, the page's real artwork inside
/// it, and two small coins orbiting the rim.
class _HeroBadge extends StatefulWidget {
  const _HeroBadge({required this.page});
  final _Page page;

  @override
  State<_HeroBadge> createState() => _HeroBadgeState();
}

class _HeroBadgeState extends State<_HeroBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  static const double _size = 220;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.page.glow;
    return SizedBox(
      width: _size + 70,
      height: _size + 70,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final bob = math.sin(t * 2 * math.pi) * 6;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glow.withOpacity(0.45),
                      blurRadius: 70,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Container(
                  width: _size + 26,
                  height: _size + 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.16),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.10),
                        glow.withOpacity(0.16),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: widget.page.image != null
                        ? Image.asset(widget.page.image!, fit: BoxFit.contain)
                        : Icon(widget.page.icon, size: 88, color: Colors.white),
                  ),
                ),
              ),
              _OrbitCoin(angle: t * 2 * math.pi, radius: _size / 2 + 12, size: 30),
              _OrbitCoin(
                angle: t * 2 * math.pi + math.pi,
                radius: _size / 2 + 2,
                size: 20,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitCoin extends StatelessWidget {
  const _OrbitCoin({
    required this.angle,
    required this.radius,
    required this.size,
  });
  final double angle;
  final double radius;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius * 0.4; // flattened into an ellipse
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Image.asset(
        'assets/images/currency_coin.png',
        width: size,
        height: size,
      ),
    );
  }
}

/// A smoothly-interpolated dot indicator — width, colour and glow all track
/// the live PageView offset instead of snapping only when a page settles.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = 1 - (page - i).abs().clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + 24 * active,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.white24, AppColors.brand, active),
            borderRadius: AppRadius.pillRadius,
            boxShadow: active > 0.5
                ? [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(0.5 * active),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
