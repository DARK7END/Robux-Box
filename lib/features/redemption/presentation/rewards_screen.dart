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
import '../../../core/theme/app_gradients.dart';
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
              title: 'Redeem for',
              subtitle: 'Pick a brand to see rewards',
              icon: Icons.storefront_rounded,
            ),
          ),
          _BrandGrid(),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(
              title: context.l10n.rewardsRobux,
              subtitle: 'Instant Robux packages',
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
                    message: 'New Robux packages are added regularly.',
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

  @override
  Widget build(BuildContext context) {
    final robux = coins.asRobux(AppConstants.coinsPerRobux);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.brand),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available balance',
                    style: context.text.bodySmall
                        ?.copyWith(color: Colors.black.withOpacity(0.7))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.black, size: 26),
                    const SizedBox(width: 6),
                    AnimatedCounter(
                      value: coins,
                      style: AppTypography.counter(30, AppColors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: AppRadius.cardRadius,
            ),
            child: Column(
              children: [
                Text('≈ $robux',
                    style: AppTypography.counter(18, AppColors.black)),
                Text('Robux',
                    style: context.text.labelSmall
                        ?.copyWith(color: Colors.black.withOpacity(0.7))),
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
