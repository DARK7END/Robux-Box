import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/providers.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_notification.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType t) => switch (t) {
        NotificationType.reward => Icons.bolt_rounded,
        NotificationType.redemption => Icons.card_giftcard_rounded,
        NotificationType.referral => Icons.group_rounded,
        NotificationType.vip => Icons.workspace_premium_rounded,
        NotificationType.promo => Icons.local_offer_rounded,
        NotificationType.achievement => Icons.emoji_events_rounded,
        NotificationType.dailyReminder => Icons.alarm_rounded,
        NotificationType.system => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return AppScaffold(
      title: context.l10n.notificationsTitle,
      actions: [
        TextButton(
          onPressed: uid == null
              ? null
              : () => ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(uid),
          child: Text(context.l10n.notificationsMarkAllRead),
        ),
      ],
      body: async.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateView(
              icon: Icons.notifications_off_rounded,
              title: context.l10n.notificationsEmpty,
              message: 'New rewards and updates will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + AppSpacing.lg, bottom: 40),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final n = items[i];
              return GlassCard(
                fillColor: n.isRead
                    ? null
                    : context.colors.primary.withValues(alpha: 0.08),
                onTap: () {
                  if (uid != null && !n.isRead) {
                    ref.read(notificationRepositoryProvider).markRead(uid, n.id);
                  }
                  if (n.deeplink.isNotEmpty) context.push(n.deeplink);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(_icon(n.type),
                          color: context.colors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: context.text.titleSmall),
                          Text(n.body, style: context.text.bodySmall),
                          if (n.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(n.createdAt!.relative(),
                                  style: context.text.labelSmall?.copyWith(
                                      color: context.surfaces.textTertiary)),
                            ),
                        ],
                      ),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                            color: AppColors.brand, shape: BoxShape.circle),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
