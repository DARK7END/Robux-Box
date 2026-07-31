import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../core/widgets/r_glyph.dart';
import '../../../../models/app_user.dart';
import '../../../../models/wallet.dart';

/// The hero balance card: a bright brand-green "currency" panel with a large
/// animated coin counter, level progress and lifetime stats.
///
/// Because the fill is vivid neon green, all ink is near-black — this reads as a
/// premium reward card (think in-game currency vault) instead of a low-contrast
/// gradient. A soft top-left light and an oversized coin watermark add depth.
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key, required this.user, required this.wallet});

  final AppUser user;
  final Wallet wallet;

  // Rich, slightly green-tinted black so ink feels part of the card, not pasted.
  static const Color _ink = Color(0xFF06230F);
  static Color get _inkSoft => _ink.withOpacity(0.62);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.brand),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // Top-left "lit" highlight for a glossy, dimensional surface.
            Positioned(
              top: -70,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.32),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Oversized coin watermark bottom-right.
            Positioned(
              right: -28,
              bottom: -34,
              child: RGlyph(size: 168, color: _ink.withOpacity(0.10)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.l10n.homeYourBalance,
                        style: context.text.labelMedium?.copyWith(
                          color: _inkSoft,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      _StreakChip(streak: user.streakCount),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: _ink, size: 36),
                      const SizedBox(width: 4),
                      AnimatedCounter(
                        value: wallet.coins,
                        style: AppTypography.counter(44, _ink),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          context.l10n.homeCoins,
                          style: context.text.bodyMedium?.copyWith(
                            color: _inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LevelProgress(user: user, ink: _ink, inkSoft: _inkSoft),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _ink.withOpacity(0.14),
                      borderRadius: AppRadius.cardRadius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Stat(
                          label: context.l10n.walletEarned,
                          value: wallet.lifetimeEarned,
                          ink: _ink,
                          inkSoft: _inkSoft,
                        ),
                        const _Divider(color: _ink),
                        _Stat(
                          label: context.l10n.profileXp,
                          value: user.xp,
                          ink: _ink,
                          inkSoft: _inkSoft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 26, color: color.withOpacity(0.18));
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress(
      {required this.user, required this.ink, required this.inkSoft});
  final AppUser user;
  final Color ink;
  final Color inkSoft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: user.levelProgress.clamp(0.0, 1.0)),
            duration: AppDuration.slow,
            curve: AppCurves.standard,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: ink.withOpacity(0.16),
              valueColor: AlwaysStoppedAnimation(ink.withOpacity(0.88)),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Level ${user.level} • ${user.xp}/${user.xpForNextLevel} XP',
          style: context.text.labelSmall?.copyWith(
            color: inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: BalanceHeroCard._ink.withOpacity(0.16),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFFF7A1A), size: 17),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: context.text.labelMedium?.copyWith(
              color: BalanceHeroCard._ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.ink,
    required this.inkSoft,
    this.value,
    this.valueText,
  });
  final String label;
  final Color ink;
  final Color inkSoft;
  final int? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        valueText != null
            ? Text(valueText!, style: AppTypography.counter(16, ink))
            : AnimatedCounter(
                value: value ?? 0,
                style: AppTypography.counter(16, ink),
              ),
        const SizedBox(height: 1),
        Text(label,
            style: context.text.labelSmall?.copyWith(
              color: inkSoft,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
