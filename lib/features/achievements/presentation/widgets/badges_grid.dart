import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../models/app_user.dart';
import '../../../../models/wallet.dart';
import '../../../profile/data/user_repository.dart';

class _Badge {
  const _Badge(this.name, this.icon, this.colors, this.unlocked);
  final String name;
  final IconData icon;
  final List<Color> colors;
  final bool unlocked;
}

/// A grid of collectible badge emblems, unlocked live from the player's stats.
/// Unlocked badges glow in brand colours; locked ones are dimmed with a lock.
class BadgesGrid extends ConsumerWidget {
  const BadgesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull ??
        AppUser.empty('');
    final wallet = ref.watch(currentWalletProvider).valueOrNull ??
        Wallet.empty('');

    final badges = <_Badge>[
      _Badge('Rookie', Icons.hexagon_rounded,
          const [Color(0xFF5BFFA0), AppColors.brandDeep], user.level >= 1),
      _Badge('Streaker', Icons.local_fire_department_rounded,
          const [Color(0xFFFF8A3D), Color(0xFFFF5722)], user.streakCount >= 7),
      _Badge('Collector', Icons.workspace_premium_rounded,
          const [Color(0xFFFFE178), AppColors.coinDeep],
          wallet.lifetimeEarned >= 5000),
      _Badge('Champion', Icons.emoji_events_rounded,
          const [Color(0xFFFFD84D), Color(0xFFF5A600)],
          wallet.lifetimeEarned >= 25000),
      _Badge('Inviter', Icons.diamond_rounded,
          const [Color(0xFF7FE7FF), Color(0xFF2E9BFF)], user.referralCount >= 1),
      _Badge('VIP', Icons.military_tech_rounded,
          const [Color(0xFFA78BFA), AppColors.accentDeep],
          user.vipLevel != VipLevel.none),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) => _BadgeTile(badge: badges[i])
          .animate()
          .fadeIn(delay: (50 * i).ms)
          .scale(begin: const Offset(0.8, 0.8), curve: AppCurves.spring),
    );
  }
}

/// A collectible medal: a metallic-rimmed disc (glossy highlight + centred
/// icon) with a two-flap ribbon tail peeking out beneath it, like a real
/// enamel-pin achievement badge. Locked badges keep the same silhouette,
/// desaturated, with a lock glyph in place of the badge's icon.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});
  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    final ribbonColor =
        unlocked ? badge.colors.last : context.surfaces.surfaceHigh;
    final rimColors = unlocked
        ? [Colors.white.withOpacity(0.95), badge.colors.last]
        : [context.surfaces.border, context.surfaces.border];
    final faceGradient = unlocked
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: badge.colors,
          )
        : LinearGradient(colors: [
            context.surfaces.surfaceHigh,
            context.surfaces.surfaceHigh,
          ]);

    final medallion = SizedBox(
      width: 78,
      height: 86,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RibbonFlap(color: ribbonColor, angle: -0.32),
                const SizedBox(width: 8),
                _RibbonFlap(color: ribbonColor, angle: 0.32),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: rimColors,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: badge.colors.first.withOpacity(0.55),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: faceGradient,
                border: Border.all(
                  color: unlocked
                      ? Colors.white.withOpacity(0.35)
                      : context.surfaces.border,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (unlocked)
                    Positioned(
                      top: 9,
                      left: 13,
                      child: Container(
                        width: 20,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.30),
                        ),
                      ),
                    ),
                  Icon(
                    unlocked ? badge.icon : Icons.lock_rounded,
                    color:
                        unlocked ? AppColors.black : context.surfaces.textTertiary,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        unlocked
            ? medallion
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: 2400.ms,
                    color: Colors.white.withOpacity(0.35))
            : medallion,
        const SizedBox(height: AppSpacing.xs),
        Text(
          unlocked ? badge.name : context.l10n.badgesLocked,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: unlocked
                ? context.colors.onSurface
                : context.surfaces.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// One flag-shaped end of a medal's ribbon: a small rectangle with a
/// triangular notch cut from its bottom edge.
class _RibbonFlap extends StatelessWidget {
  const _RibbonFlap({required this.color, required this.angle});
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ClipPath(
        clipper: _RibbonClipper(),
        child: Container(width: 15, height: 28, color: color),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 7)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _RibbonClipper oldClipper) => false;
}
