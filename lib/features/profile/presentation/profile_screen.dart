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
import 'widgets/profile_menu_tile.dart';
import '../data/user_repository.dart';

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
                      imageUrl: user.photoUrl, fit: BoxFit.cover)
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
          const SizedBox(height: AppSpacing.md),
          Text(user.displayName,
              style:
                  context.text.titleLarge?.copyWith(color: AppColors.white)),
          Text(
            user.email.isNotEmpty ? user.email : user.phoneNumber,
            style: context.text.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HeaderStat(label: context.l10n.homeCoins, value: '$coins'),
              _HeaderStat(
                  label: context.l10n.homeLevel(user.level).split(' ').last,
                  value: 'Lv ${user.level}'),
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
