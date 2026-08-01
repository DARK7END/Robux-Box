import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/reward.dart';
import '../../profile/data/user_repository.dart';
import '../data/redemption_repository.dart';
import '../domain/reward_brand.dart';
import 'widgets/brand_category_card.dart';
import 'widgets/brand_rewards_sheet.dart';
import 'widgets/redeem_sheet.dart';
import 'widgets/reward_card.dart';

/// The Redeem tab: a premium storefront with a balance hero, a 9-brand category
/// grid and featured Robux packages.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(currentWalletProvider).valueOrNull;
    final coins = wallet?.coins ?? 0;
    final robuxAsync = ref.watch(rewardsProvider(RewardKind.robux));

    return AppScaffold(
      showAppBar: false,
      padded: false,
      body: ListView(
        padding: EdgeInsets.only(top: context.padding.top + AppSpacing.md, bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(context.l10n.rewardsTitle,
                      style: context.text.headlineSmall),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.redemptions),
                  icon: const Icon(Icons.history_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: context.surfaces.surfaceHigh),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _BalanceHero(coins: coins)
                .animate()
                .fadeIn()
                .slideY(begin: 0.1, curve: AppCurves.standard),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(
              title: context.l10n.rewardsRedeemForTitle,
              subtitle: context.l10n.rewardsPickBrand,
              icon: Icons.storefront_rounded,
            ),
          ),
          _BrandGrid(),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(
              title: context.l10n.rewardsRobux,
              subtitle: context.l10n.rewardsInstantPackages,
              icon: Icons.bolt_rounded,
              actionLabel: context.l10n.commonSeeAll,
              onAction: () => showBrandRewardsSheet(context, RewardBrands.roblox),
            ),
          ),
          robuxAsync.when(
            loading: () => const _RobuxSkeleton(),
            error: (e, _) => const SizedBox.shrink(),
            data: (rewards) {
              if (rewards.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: EmptyStateView(
                    icon: Icons.card_giftcard_rounded,
                    title: context.l10n.commonComingSoon,
                    message: context.l10n.rewardsComingSoonDesc,
                  ),
                );
              }
              return SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: rewards.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) => SizedBox(
                    width: 150,
                    child: RewardCard(
                      reward: rewards[i],
                      affordable: coins >= rewards[i].coinCost,
                      onTap: () => showRedeemSheet(context,
                          reward: rewards[i], coins: coins),
                    ).animate().fadeIn(delay: (60 * i).ms).slideX(begin: 0.1),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.coins});
  final int coins;

  // The chest artwork is a full scene (its own glow/backdrop baked in), so it
  // works as the card's background rather than a separate floating emblem:
  // it fills the card edge-to-edge, clipped to the card's own corners, with a
  // dark scrim so the balance stays readable over it.
  static const double _height = 210;

  @override
  Widget build(BuildContext context) {
    final usd = coins.asUsd(AppConstants.coinsPerRobux, AppConstants.usdPerRobux);

    return Container(
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.brand),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/redeem_balance_art.png',
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.90),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(context.l10n.rewardsAvailableBalance,
                    style: context.text.bodySmall?.copyWith(
                        color: AppColors.brandBright,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RGlyph(size: 30, color: AppColors.white),
                    const SizedBox(width: 6),
                    AnimatedCounter(
                      value: coins,
                      style: AppTypography.counter(34, AppColors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('≈ $usd',
                    style: AppTypography.counter(
                        15, Colors.white.withOpacity(0.85))),
                Text(context.l10n.rewardsRedeemableValue,
                    style: context.text.labelSmall
                        ?.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0,
        ),
        itemCount: RewardBrands.all.length,
        itemBuilder: (context, i) {
          final brand = RewardBrands.all[i];
          return BrandCategoryCard(
            brand: brand,
            onTap: () => showBrandRewardsSheet(context, brand),
          )
              .animate()
              .fadeIn(delay: (40 * i).ms)
              .scale(begin: const Offset(0.85, 0.85), curve: AppCurves.spring);
        },
      ),
    );
  }
}

class _RobuxSkeleton extends StatelessWidget {
  const _RobuxSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) =>
            const ShimmerBox(width: 150, height: 200, radius: AppRadius.lg),
      ),
    );
  }
}
