import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/support_ticket.dart';
import '../domain/support_providers.dart';
import 'widgets/new_ticket_sheet.dart';
import 'widgets/ticket_thread_sheet.dart';

/// The user's support inbox: their own tickets, newest activity first, plus a
/// button to open a new one.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return AppScaffold(
      title: context.l10n.supportTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewTicketSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.supportNewTicket),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.black,
      ),
      body: ticketsAsync.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyStateView(
              icon: Icons.support_agent_rounded,
              title: context.l10n.supportEmptyTitle,
              message: context.l10n.supportEmptyDesc,
              actionLabel: context.l10n.supportNewTicket,
              onAction: () => showNewTicketSheet(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + AppSpacing.lg, bottom: 110),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) => TicketListTile(
              ticket: tickets[i],
              onTap: () => showTicketThreadSheet(context,
                  ticket: tickets[i], isAdminView: false),
            ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.08),
          );
        },
      ),
    );
  }
}

/// One ticket row. Shared by the user inbox and the admin ticket list;
/// [showRequester] adds the requester's name for the admin view.
class TicketListTile extends StatelessWidget {
  const TicketListTile({
    super.key,
    required this.ticket,
    required this.onTap,
    this.showRequester = false,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;
  final bool showRequester;

  @override
  Widget build(BuildContext context) {
    final isOpen = ticket.status == TicketStatus.open;
    // A user-sent last message on an open ticket is the admin's cue to reply.
    final awaitingReply = isOpen && !ticket.lastSenderIsAdmin;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ticket.subject,
                    style: context.text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: isOpen
                    ? context.l10n.supportStatusOpen
                    : context.l10n.supportStatusClosed,
                color: isOpen ? AppColors.success : AppColors.darkTextTertiary,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              StatusPill(
                  label: ticket.category, color: AppColors.info, dense: true),
              if (showRequester && ticket.displayName.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(ticket.displayName,
                      style: context.text.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              if (awaitingReply) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.mark_email_unread_rounded,
                    size: 14, color: AppColors.warning),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(ticket.lastMessagePreview,
              style: context.text.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (ticket.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(ticket.updatedAt!.relative(context.l10n),
                style: context.text.labelSmall),
          ],
        ],
      ),
    );
  }
}
