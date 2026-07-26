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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});
  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    final emblem = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: unlocked
            ? LinearGradient(colors: badge.colors)
            : LinearGradient(colors: [
                context.surfaces.surfaceHigh,
                context.surfaces.surfaceHigh
              ]),
        shape: BoxShape.circle,
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: badge.colors.first.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
        border: Border.all(
          color: unlocked
              ? Colors.white.withValues(alpha: 0.3)
              : context.surfaces.border,
          width: 2,
        ),
      ),
      child: Icon(
        unlocked ? badge.icon : Icons.lock_rounded,
        color: unlocked ? AppColors.black : context.surfaces.textTertiary,
        size: 30,
      ),
    );

    return Column(
      children: [
        unlocked
            ? emblem
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: 2400.ms,
                    color: Colors.white.withValues(alpha: 0.35))
            : emblem,
        const SizedBox(height: AppSpacing.sm),
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
