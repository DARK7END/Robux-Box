import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A premium "daily game" tile (Spin Wheel / Lucky Chest) with a gradient body,
/// a soft glow, a floating/pulsing emblem and a press micro-interaction.
class GameFeatureCard extends StatefulWidget {
  const GameFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badge,
    this.dimmed = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
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
        scale: _pressed ? 0.95 : 1,
        duration: AppDuration.instant,
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient as LinearGradient)
                    .colors
                    .first
                    .withValues(alpha: 0.45),
                blurRadius: 22,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -6,
                child: Icon(
                  widget.icon,
                  size: 68,
                  color: Colors.white.withValues(alpha: 0.18),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -6, duration: 1600.ms, curve: Curves.easeInOut),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 26),
                      const Spacer(),
                      if (widget.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
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
              if (widget.dimmed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
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
