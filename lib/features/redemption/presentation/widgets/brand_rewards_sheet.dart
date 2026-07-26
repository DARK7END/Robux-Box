import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/data/user_repository.dart';
import '../../data/redemption_repository.dart';
import '../../domain/reward_brand.dart';
import 'redeem_sheet.dart';
import 'reward_card.dart';

/// Bottom sheet listing the catalogue rewards for a selected [RewardBrand].
Future<void> showBrandRewardsSheet(BuildContext context, RewardBrand brand) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) =>
          _BrandSheet(brand: brand, scrollController: scrollController),
    ),
  );
}

class _BrandSheet extends ConsumerWidget {
  const _BrandSheet({required this.brand, required this.scrollController});
  final RewardBrand brand;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider(brand.kind));
    final coins = ref.watch(currentWalletProvider).valueOrNull?.coins ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: brand.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(brand.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('${brand.name} rewards',
                  style: context.text.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: rewardsAsync.when(
              loading: () => const PremiumLoadingView(),
              error: (e, _) =>
                  ErrorStateView(message: context.l10n.errorGeneric),
              data: (all) {
                final rewards = all.where(brand.matches).toList();
                if (rewards.isEmpty) {
                  return EmptyStateView(
                    icon: brand.icon,
                    title: context.l10n.commonComingSoon,
                    message: '${brand.name} cards are being added. '
                        'Check back soon!',
                  );
                }
                return GridView.builder(
                  controller: scrollController,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, i) => RewardCard(
                    reward: rewards[i],
                    affordable: coins >= rewards[i].coinCost,
                    onTap: () {
                      Navigator.of(context).pop();
                      showRedeemSheet(context,
                          reward: rewards[i], coins: coins);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
