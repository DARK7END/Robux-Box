import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/format_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/support_ticket.dart';
import '../../data/support_repository.dart';
import '../../domain/support_providers.dart';

/// The message thread for one ticket: history + a reply box. Shared by the
/// user's own ticket view and the admin ticket view — [isAdminView] only
/// changes which side of the conversation new messages are sent as
/// (`firestore.rules` independently checks the sender's real admin claim).
Future<void> showTicketThreadSheet(
  BuildContext context, {
  required SupportTicket ticket,
  required bool isAdminView,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _TicketThreadSheet(
        ticket: ticket,
        isAdminView: isAdminView,
        scrollController: scrollController,
      ),
    ),
  );
}

class _TicketThreadSheet extends ConsumerStatefulWidget {
  const _TicketThreadSheet({
    required this.ticket,
    required this.isAdminView,
    required this.scrollController,
  });

  final SupportTicket ticket;
  final bool isAdminView;
  final ScrollController scrollController;

  @override
  ConsumerState<_TicketThreadSheet> createState() => _TicketThreadSheetState();
}

class _TicketThreadSheetState extends ConsumerState<_TicketThreadSheet> {
  final _reply = TextEditingController();
  XFile? _attachment;
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file != null && mounted) setState(() => _attachment = file);
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    // An attachment on its own is a valid message.
    if ((text.isEmpty && _attachment == null) || uid == null) return;
    setState(() => _sending = true);
    final result = await ref.read(supportRepositoryProvider).sendMessage(
          ticketId: widget.ticket.id,
          senderUid: uid,
          isAdmin: widget.isAdminView,
          text: text,
          attachment:
              _attachment == null ? null : File(_attachment!.path),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Success():
        _reply.clear();
        setState(() => _attachment = null);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  Future<void> _toggleStatus(TicketStatus current) async {
    final next =
        current == TicketStatus.open ? TicketStatus.closed : TicketStatus.open;
    final result =
        await ref.read(supportRepositoryProvider).setStatus(widget.ticket.id, next);
    if (!mounted) return;
    if (result case Err(:final Failure failure)) {
      AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticket.id));
    // The ticket doc updates (status) as the conversation continues; prefer
    // the live copy where available so the header reflects reality.
    final live = widget.isAdminView
        ? ref.watch(allTicketsProvider)
        : ref.watch(myTicketsProvider);
    final matches = (live.valueOrNull ?? const <SupportTicket>[])
        .where((t) => t.id == widget.ticket.id);
    final ticket = matches.isEmpty ? widget.ticket : matches.first;
    final isOpen = ticket.status == TicketStatus.open;

    return Padding(
      padding: EdgeInsets.only(bottom: context.viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.subject,
                          style: context.text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (widget.isAdminView && ticket.displayName.isNotEmpty)
                        Text(ticket.displayName, style: context.text.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      StatusPill(
                        label: isOpen
                            ? context.l10n.supportStatusOpen
                            : context.l10n.supportStatusClosed,
                        color: isOpen ? AppColors.success : AppColors.danger,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isOpen
                      ? context.l10n.supportCloseTicket
                      : context.l10n.supportReopenTicket,
                  onPressed: () => _toggleStatus(ticket.status),
                  icon: Icon(isOpen
                      ? Icons.check_circle_outline_rounded
                      : Icons.refresh_rounded),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: messagesAsync.when(
              loading: () => const PremiumLoadingView(),
              error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
              data: (messages) => ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: messages.length,
                itemBuilder: (context, i) =>
                    _MessageBubble(message: messages[i], isMine: messages[i].senderUid == myUid),
              ),
            ),
          ),
          const Divider(height: 1),
          if (_attachment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.file(File(_attachment!.path),
                        width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(context.l10n.supportAttachmentReady,
                        style: context.text.bodySmall),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _attachment = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.l10n.supportAttachImage,
                  onPressed: _sending ? null : _pickAttachment,
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _reply,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration:
                        InputDecoration(hintText: context.l10n.supportReplyHint),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen, pinch-zoomable view of an attachment.
void _openImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(child: CachedNetworkImage(imageUrl: url)),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.sm,
          right: AppSpacing.sm,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});
  final TicketMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.brand : context.surfaces.surfaceHigh;
    final textColor = isMine ? AppColors.black : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
              child: Text(
                message.isAdmin
                    ? context.l10n.supportTeamLabel
                    : context.l10n.supportYouLabel,
                style: context.text.labelSmall,
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: context.width * 0.75),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.hasImage) ...[
                  GestureDetector(
                    onTap: () => _openImage(context, message.imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth:
                            (240 * MediaQuery.of(context).devicePixelRatio)
                                .round(),
                        placeholder: (_, __) =>
                            const ShimmerBox(width: 200, height: 140),
                        errorWidget: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: textColor),
                      ),
                    ),
                  ),
                  if (message.text.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                ],
                if (message.text.isNotEmpty)
                  Text(message.text,
                      style:
                          context.text.bodyMedium?.copyWith(color: textColor)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          if (message.createdAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(message.createdAt!.relative(context.l10n),
                  style: context.text.labelSmall),
            ),
        ],
      ),
    );
  }
}
