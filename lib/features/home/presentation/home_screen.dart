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
import '../../notifications/data/notification_repository.dart';
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
                subtitle: user.canSpinToday ? 'Win up to 500' : 'Played today',
                icon: Icons.casino_rounded,
                gradient: AppGradients.accent,
                badge: user.canSpinToday ? 'FREE' : timeUntilMidnight(),
                dimmed: !user.canSpinToday,
                onTap: () => context.go(AppRoutes.earn),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GameFeatureCard(
                title: 'Lucky Chest',
                subtitle: user.canOpenChestToday ? 'Open for coins' : 'Opened today',
                icon: Icons.inventory_2_rounded,
                gradient: AppGradients.coin,
                badge: user.canOpenChestToday ? 'HOT' : timeUntilMidnight(),
                dimmed: !user.canOpenChestToday,
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
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return Row(
      children: [
        // Avatar inside a brand-gradient ring for a premium "profile" accent.
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brand,
            boxShadow: AppShadows.glow(AppColors.brand),
          ),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: context.surfaces.surfaceHigh,
            backgroundImage:
                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: context.text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.homeGreeting(user.displayName),
                style: context.text.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.homeLevel(user.level),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notification bell in a tappable glass circle with an unread dot.
        Pressable(
          onTap: () => context.push(AppRoutes.notifications),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.surfaces.glassFill,
              shape: BoxShape.circle,
              border: Border.all(color: context.surfaces.glassBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 22),
                if (unread > 0)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.surfaces.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    // Gold "cash out" banner — dark ink for legibility on the bright fill.
    const ink = Color(0xFF3A2600);
    return GlassCard(
      gradient: AppGradients.coin,
      onTap: () => context.go(AppRoutes.rewards),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ink.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.redeem_rounded, color: ink, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rewardsRedeem,
                  style: context.text.titleMedium?.copyWith(
                      color: ink, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Turn your coins into Robux & gift cards',
                  style: context.text.bodySmall
                      ?.copyWith(color: ink.withOpacity(0.72)),
                ),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ink.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                color: ink, size: 18),
          ),
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
