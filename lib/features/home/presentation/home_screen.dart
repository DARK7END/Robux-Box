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
import '../../../models/app_user.dart';
import '../../../models/wallet.dart';
import '../../earn/domain/earn_controller.dart';
import '../../profile/data/user_repository.dart';
import 'widgets/balance_hero_card.dart';
import 'widgets/daily_reward_card.dart';
import 'widgets/missions_section.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/tier_card.dart';

/// The home dashboard: balance, tier, daily reward and quick actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final walletAsync = ref.watch(currentWalletProvider);

    return AppScaffold(
      showAppBar: false,
      padded: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(currentWalletProvider);
        },
        child: userAsync.when(
          loading: () => const _HomeSkeleton(),
          error: (e, _) => ErrorStateView(
            message: context.l10n.errorGeneric,
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
          data: (user) {
            if (user == null) return const _HomeSkeleton();
            final wallet = walletAsync.valueOrNull ?? Wallet.empty(user.uid);
            return _HomeContent(user: user, wallet: wallet);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.user, required this.wallet});

  final AppUser user;
  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.only(
        top: context.padding.top + AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: 110,
      ),
      children: [
        _Header(user: user),
        const SizedBox(height: AppSpacing.lg),
        // Balance hero with an ambient floating-coin field behind it.
        Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: const IgnorePointer(child: CoinParticles(count: 10)),
              ),
            ),
            BalanceHeroCard(user: user, wallet: wallet),
          ],
        ).animate().fadeIn().slideY(begin: 0.1, curve: AppCurves.standard),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: TierCard(user: user)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _RobuxValueCard(coins: wallet.coins),
            ),
          ],
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: AppSpacing.lg),
        if (user.canClaimDaily)
          DailyRewardCard(user: user)
              .animate()
              .fadeIn(delay: 120.ms)
              .slideY(begin: 0.1),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: context.l10n.homeQuickActions),
        const QuickActionGrid().animate().fadeIn(delay: 160.ms),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Daily games',
          subtitle: 'Free plays every day',
          icon: Icons.casino_rounded,
        ),
        Row(
          children: [
            Expanded(
              child: GameFeatureCard(
                title: 'Spin Wheel',
                subtitle: 'Win up to 1000',
                icon: Icons.casino_rounded,
                gradient: AppGradients.accent,
                badge: 'FREE',
                onTap: () => context.go(AppRoutes.earn),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GameFeatureCard(
                title: 'Lucky Chest',
                subtitle: 'Open for coins',
                icon: Icons.inventory_2_rounded,
                gradient: AppGradients.coin,
                badge: 'HOT',
                onTap: () => context.go(AppRoutes.earn),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Daily missions',
          subtitle: 'Finish to earn bonus coins',
          icon: Icons.flag_rounded,
        ),
        const MissionsSection(),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(
          title: context.l10n.rewardsTitle,
          actionLabel: context.l10n.commonSeeAll,
          onAction: () => context.go(AppRoutes.rewards),
        ),
        _RedeemPromptCard(coins: wallet.coins),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: context.colors.primary.withValues(alpha: 0.2),
          backgroundImage:
              user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: context.text.titleMedium,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.homeGreeting(user.displayName),
                style: context.text.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                context.l10n.homeLevel(user.level),
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _RobuxValueCard extends StatelessWidget {
  const _RobuxValueCard({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    final robux = coins.asRobux(AppConstants.coinsPerRobux);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: AppGradients.robux,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.paid_rounded,
                    size: 16, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Robux', style: context.text.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('≈ $robux', style: AppTypography.counter(22, AppColors.robux)),
          Text('redeemable', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _RedeemPromptCard extends StatelessWidget {
  const _RedeemPromptCard({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppGradients.brand,
      onTap: () => context.go(AppRoutes.rewards),
      child: Row(
        children: [
          const Icon(Icons.redeem_rounded, color: AppColors.white, size: 34),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rewardsRedeem,
                  style: context.text.titleMedium
                      ?.copyWith(color: AppColors.white),
                ),
                Text(
                  'Turn your coins into Robux & gift cards',
                  style: context.text.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.white, size: 16),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: context.padding.top + AppSpacing.xxl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      children: const [
        ShimmerBox(height: 48, radius: AppRadius.md),
        SizedBox(height: AppSpacing.lg),
        ShimmerBox(height: 150, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 96, radius: AppRadius.lg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerBox(height: 96, radius: AppRadius.lg)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        ShimmerBox(height: 120, radius: AppRadius.lg),
      ],
    );
  }
}
