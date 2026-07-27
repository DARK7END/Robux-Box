import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/data/user_repository.dart';

class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final code = user?.referralCode ?? '';

    return AppScaffold(
      title: context.l10n.referralTitle,
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          GlassCard(
            gradient: AppGradients.neon,
            child: Column(
              children: [
                const Icon(Icons.group_add_rounded,
                    color: AppColors.white, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.referralSubtitle(AppConstants.referrerBonusCoins),
                  style:
                      context.text.titleMedium?.copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.referralYourCode, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            onTap: code.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    HapticFeedback.mediumImpact();
                    AppToast.success(context, context.l10n.referralCopied);
                  },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code.isEmpty ? '—' : code,
                    style: context.text.headlineSmall?.copyWith(letterSpacing: 3),
                  ),
                ),
                const Icon(Icons.copy_rounded, color: AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: context.l10n.referralShare,
            icon: Icons.share_rounded,
            gradient: AppGradients.neon,
            onPressed: code.isEmpty
                ? null
                : () => Share.share(
                      'Join me on Robux Box and earn free Robux! Use my code $code when you sign up. 🎮',
                      subject: 'Robux Box invite',
                    ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: context.l10n.profileReferrals,
                  value: '${user?.referralCount ?? 0}',
                  icon: Icons.people_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Lifetime share',
                  value:
                      '${(AppConstants.referralRevenueSharePercent * 100).round()}%',
                  icon: Icons.percent_rounded,
                  color: AppColors.coin,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How it works', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _Step(
                    n: 1,
                    text:
                        'Share your code with friends who love Roblox.'),
                _Step(
                    n: 2,
                    text:
                        'They enter it on sign-up and get ${AppConstants.refereeBonusCoins} coins.'),
                _Step(
                    n: 3,
                    text:
                        'You earn ${AppConstants.referrerBonusCoins} coins + ${(AppConstants.referralRevenueSharePercent * 100).round()}% of what they earn, forever.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: context.text.headlineSmall),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: context.colors.primary.withOpacity(0.16),
            child: Text('$n',
                style: context.text.labelSmall
                    ?.copyWith(color: context.colors.primary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
