import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../support/domain/support_providers.dart';
import '../domain/admin_providers.dart';

/// Admin dashboard home — a grid of management sections. Only reachable when the
/// signed-in user holds the `admin` claim (guarded by [AdminGate]).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRedemptionsCountProvider);
    final openTickets = ref.watch(openTicketsCountProvider);

    final sections = <_AdminSection>[
      _AdminSection('Withdraw Requests', Icons.account_balance_wallet_rounded,
          AppColors.brand, AppRoutes.adminRedemptions,
          badge: pending),
      _AdminSection('Support', Icons.support_agent_rounded, AppColors.info,
          AppRoutes.adminTickets,
          badge: openTickets),
      _AdminSection('Users', Icons.people_alt_rounded, AppColors.secondary,
          AppRoutes.adminUsers),
      _AdminSection('VIP Purchases', Icons.workspace_premium_rounded,
          AppColors.vip, AppRoutes.adminVipPurchases),
      _AdminSection('Rewards', Icons.card_giftcard_rounded, AppColors.robux,
          AppRoutes.adminRewards),
      _AdminSection('Promocodes', Icons.confirmation_number_rounded,
          AppColors.coin, AppRoutes.adminPromocodes),
      _AdminSection('Broadcast', Icons.campaign_rounded, AppColors.accent,
          AppRoutes.adminBroadcast),
      _AdminSection('Analytics', Icons.insights_rounded, AppColors.info,
          AppRoutes.adminAnalytics),
      _AdminSection('Reports', Icons.flag_rounded, AppColors.danger,
          AppRoutes.adminReports),
      _AdminSection('Manage admins', Icons.admin_panel_settings_rounded,
          AppColors.brandBright, AppRoutes.adminManage),
    ];

    return AppScaffold(
      title: 'Admin',
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          GlassCard(
            gradient: const LinearGradient(
              colors: [AppColors.brandDeep, Color(0xFF0B3D22)],
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppColors.white, size: 34),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Control center',
                          style: context.text.titleMedium
                              ?.copyWith(color: AppColors.white)),
                      Text(
                          '$pending payout(s) · $openTickets ticket(s) awaiting you',
                          style: context.text.bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.35,
            children: sections
                .asMap()
                .entries
                .map((e) => _SectionCard(section: e.value)
                    .animate()
                    .fadeIn(delay: (50 * e.key).ms)
                    .scale(
                        begin: const Offset(0.9, 0.9), curve: AppCurves.spring))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection(this.title, this.icon, this.color, this.route,
      {this.badge = 0});
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final int badge;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _AdminSection section;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push(section.route),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(section.icon, color: section.color, size: 24),
              ),
              Text(section.title, style: context.text.titleSmall),
            ],
          ),
          if (section.badge > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text('${section.badge}',
                    style: context.text.labelSmall?.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
