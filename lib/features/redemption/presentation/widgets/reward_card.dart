import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/r_glyph.dart';
import '../../../../models/reward.dart';

typedef _GlyphBuilder = Widget Function(double size, Color color);

/// A single catalogue reward tile, styled like a collectible trading card:
/// a glossy gradient "art" panel with a foil shimmer sweep and an oversized
/// brand emblem, a kind-tinted foil border, and a premium coin-cost pill.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.affordable,
    required this.onTap,
  });

  final Reward reward;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Gradient art, Color accent, _GlyphBuilder glyph) = switch (reward.kind) {
      RewardKind.robux => (
          AppGradients.robux,
          AppColors.brand,
          (double s, Color c) => RGlyph(size: s, color: c),
        ),
      RewardKind.giftCard => (
          AppGradients.coin,
          AppColors.coin,
          (double s, Color c) =>
              Icon(Icons.card_giftcard_rounded, size: s, color: c),
        ),
      RewardKind.digitalCode => (
          AppGradients.vip,
          AppColors.vip,
          (double s, Color c) => Icon(Icons.vpn_key_rounded, size: s, color: c),
        ),
    };

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      // A faint foil edge in the reward's own accent colour.
      borderColor: accent.withOpacity(0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'reward_${reward.id}',
            child: _ArtPanel(
              reward: reward,
              gradient: art,
              accent: accent,
              glyph: glyph,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title,
                    style: context.text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (reward.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(reward.subtitle,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: AppSpacing.md),
                _CostPill(cost: reward.coinCost, affordable: affordable),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtPanel extends StatelessWidget {
  const _ArtPanel({
    required this.reward,
    required this.gradient,
    required this.accent,
    required this.glyph,
  });

  final Reward reward;
  final Gradient gradient;
  final Color accent;
  final _GlyphBuilder glyph;

  @override
  Widget build(BuildContext context) {
    const radius =
        BorderRadius.vertical(top: Radius.circular(AppRadius.lg));
    // The panel is opaque (gradient fills it), so a foil shimmer applied to the
    // whole thing renders reliably — a slow diagonal light sweep like real foil.
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            // Oversized ghost emblem for depth.
            Positioned(
              right: -14,
              bottom: -18,
              child: glyph(96, Colors.black.withOpacity(0.10)),
            ),
            // Custom artwork, if provided, sits over the gradient.
            if (reward.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: reward.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth:
                    (220 * MediaQuery.of(context).devicePixelRatio).round(),
                memCacheHeight:
                    (96 * MediaQuery.of(context).devicePixelRatio).round(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              Center(
                child: glyph(42, AppColors.white),
              ),
            // Glossy top light.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            if (reward.badge.isNotEmpty)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _Ribbon(label: reward.badge),
              ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 2600.ms,
            delay: 1400.ms,
            color: Colors.white.withOpacity(0.22),
          ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({required this.cost, required this.affordable});
  final int cost;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final tint = affordable ? AppColors.coin : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.14),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: tint.withOpacity(0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 16),
          const SizedBox(width: 3),
          Text(
            context.l10n.rewardsCost(cost),
            style: context.text.labelMedium?.copyWith(
              color: affordable ? context.colors.onSurface : AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
