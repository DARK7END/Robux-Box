import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/reward.dart';
import '../../profile/data/user_repository.dart';
import '../data/redemption_repository.dart';
import 'widgets/redeem_sheet.dart';
import 'widgets/reward_card.dart';

/// Reward catalogue with Robux / Gift card / Digital code tabs.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(currentWalletProvider).valueOrNull;
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        titleWidget: Text(context.l10n.rewardsTitle),
        actions: [
          if (wallet != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(child: CoinBadge(amount: wallet.coins)),
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRoutes.redemptions),
          ),
        ],
        body: Column(
          children: [
            SizedBox(height: kToolbarHeight + context.padding.top),
            TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: AppRadius.pillRadius,
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: context.surfaces.textTertiary,
              tabs: [
                Tab(text: context.l10n.rewardsRobux),
                Tab(text: context.l10n.rewardsGiftCards),
                Tab(text: context.l10n.rewardsDigitalCodes),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                children: [
                  _RewardGrid(kind: RewardKind.robux),
                  _RewardGrid(kind: RewardKind.giftCard),
                  _RewardGrid(kind: RewardKind.digitalCode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardGrid extends ConsumerWidget {
  const _RewardGrid({required this.kind});
  final RewardKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider(kind));
    final coins = ref.watch(currentWalletProvider).valueOrNull?.coins ?? 0;

    return rewardsAsync.when(
      loading: () => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.only(bottom: 110),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
        children: List.generate(
            4, (_) => const ShimmerBox(height: 200, radius: AppRadius.lg)),
      ),
      error: (e, _) => ErrorStateView(
        message: context.l10n.errorGeneric,
        onRetry: () => ref.invalidate(rewardsProvider(kind)),
      ),
      data: (rewards) {
        if (rewards.isEmpty) {
          return EmptyStateView(
            icon: Icons.card_giftcard_rounded,
            title: context.l10n.commonComingSoon,
            message: 'New rewards are added regularly. Check back soon!',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.82,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, i) {
            final reward = rewards[i];
            return RewardCard(
              reward: reward,
              affordable: coins >= reward.coinCost,
              onTap: () => showRedeemSheet(context, reward: reward, coins: coins),
            );
          },
        );
      },
    );
  }
}
