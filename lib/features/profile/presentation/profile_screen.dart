import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_user.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/user_repository.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/profile_menu_tile.dart';

/// Profile hub: identity header, level, and navigation to every sub-feature.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final wallet = ref.watch(currentWalletProvider).valueOrNull;

    return AppScaffold(
      title: context.l10n.profileTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(
            top: kToolbarHeight + AppSpacing.lg, bottom: 110),
        children: [
          if (user != null) _ProfileHeader(user: user, coins: wallet?.coins ?? 0),
          const SizedBox(height: AppSpacing.xl),
          ProfileMenuTile(
            icon: Icons.account_balance_wallet_rounded,
            label: context.l10n.walletTitle,
            color: AppColors.brand,
            onTap: () => context.push(AppRoutes.wallet),
          ),
          ProfileMenuTile(
            icon: Icons.card_giftcard_rounded,
            iconWidget: const GiftIcon(size: 22, color: AppColors.robux),
            label: context.l10n.redemptionTitle,
            color: AppColors.robux,
            onTap: () => context.push(AppRoutes.redemptions),
          ),
          ProfileMenuTile(
            icon: Icons.emoji_events_rounded,
            label: context.l10n.profileAchievements,
            color: AppColors.coin,
            onTap: () => context.push(AppRoutes.achievements),
          ),
          ProfileMenuTile(
            icon: Icons.leaderboard_rounded,
            label: context.l10n.leaderboardTitle,
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.leaderboard),
          ),
          ProfileMenuTile(
            icon: Icons.group_rounded,
            label: context.l10n.profileReferrals,
            color: AppColors.secondary,
            onTap: () => context.push(AppRoutes.referrals),
          ),
          ProfileMenuTile(
            icon: Icons.workspace_premium_rounded,
            label: context.l10n.profileVip,
            color: AppColors.vip,
            onTap: () => context.push(AppRoutes.vip),
          ),
          ProfileMenuTile(
            icon: Icons.settings_rounded,
            label: context.l10n.settingsTitle,
            color: AppColors.info,
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: Text(context.l10n.authSignOut,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.coins});
  final AppUser user;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppGradients.brand,
      child: Column(
        children: [
          Pressable(
            onTap: () => showEditProfileSheet(context),
            child: Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 3),
                  ),
                  child: ClipOval(
                    child: user.photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: (84 *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                            memCacheHeight: (84 *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                          )
                        : Container(
                            color: Colors.white24,
                            child: Center(
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: context.text.headlineMedium
                                    ?.copyWith(color: AppColors.white),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 13, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user.displayName,
              style:
                  context.text.titleLarge?.copyWith(color: AppColors.white)),
          Text(
            user.email.isNotEmpty ? user.email : user.phoneNumber,
            style: context.text.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Level + XP progress.
          Row(
            children: [
              Text('Lv ${user.level}',
                  style: context.text.labelMedium
                      ?.copyWith(color: AppColors.black, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: user.levelProgress),
                    duration: AppDuration.slow,
                    curve: AppCurves.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.black.withOpacity(0.25),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${user.xp}/${user.xpForNextLevel}',
                  style: context.text.labelSmall?.copyWith(
                      color: Colors.black.withOpacity(0.7))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HeaderStat(label: context.l10n.homeCoins, value: '$coins'),
              _HeaderStat(
                  label: context.l10n.profileXp, value: '${user.xp}'),
              _HeaderStat(
                  label: context.l10n.profileReferrals,
                  value: '${user.referralCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: context.text.titleMedium?.copyWith(color: AppColors.white)),
        Text(label,
            style: context.text.labelSmall?.copyWith(color: Colors.white60)),
      ],
    );
  }
}
