import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

/// A premium "daily game" tile (Spin Wheel / Lucky Chest) with a gradient body,
/// a soft glow, a real artwork thumbnail (or a floating/pulsing fallback icon
/// when no artwork is supplied) and a press micro-interaction.
class GameFeatureCard extends StatefulWidget {
  const GameFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.image,
    this.badge,
    this.dimmed = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  /// Real brand artwork asset shown as a thumbnail in place of [icon], when set.
  final String? image;
  final String? badge;

  /// When true (e.g. daily play already used), the card is desaturated with a
  /// small lock — still tappable so the caller can show a "come back" message.
  final bool dimmed;

  @override
  State<GameFeatureCard> createState() => _GameFeatureCardState();
}

class _GameFeatureCardState extends State<GameFeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: _pressed ? AppDuration.instant : AppDuration.fast,
        curve: _pressed ? Curves.easeOut : AppCurves.spring,
        child: Container(
          height: 128,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient as LinearGradient)
                    .colors
                    .first
                    .withOpacity(0.45),
                blurRadius: 22,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.image != null)
                Image.asset(widget.image!, fit: BoxFit.cover)
              else
                Positioned(
                  right: -8,
                  top: -6,
                  child: Icon(
                    widget.icon,
                    size: 68,
                    color: Colors.white.withOpacity(0.18),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -6, duration: 1600.ms, curve: Curves.easeInOut),
                ),
              // A uniform scrim keeps title/badge legible over busy artwork —
              // the plain gradient needs none, so it's skipped there.
              if (widget.image != null)
                ColoredBox(color: Colors.black.withOpacity(0.46)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (widget.image == null)
                          Icon(widget.icon, color: Colors.white, size: 26),
                        const Spacer(),
                        if (widget.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(widget.badge!,
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                )),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium
                                ?.copyWith(color: Colors.white)),
                        Text(widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.dimmed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_clock_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
