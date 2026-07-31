import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/data/user_repository.dart';
import '../../data/support_repository.dart';
import '../../domain/support_providers.dart';

/// Opens a new support ticket: category, subject, first message and an
/// optional screenshot.
Future<void> showNewTicketSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _NewTicketSheet(),
  );
}

class _NewTicketSheet extends ConsumerStatefulWidget {
  const _NewTicketSheet();

  @override
  ConsumerState<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends ConsumerState<_NewTicketSheet> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String? _category;
  XFile? _attachment;
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
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

  Future<void> _submit(List<String> categories) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (uid == null) return;
    if (subject.isEmpty || message.isEmpty) {
      AppToast.error(context, context.l10n.supportFillAllFields);
      return;
    }
    setState(() => _busy = true);
    final user = ref.read(currentUserProvider).valueOrNull;
    final result = await ref.read(supportRepositoryProvider).createTicket(
          uid: uid,
          displayName: user?.displayName ?? '',
          category: _category ?? categories.first,
          subject: subject,
          message: message,
          attachment:
              _attachment == null ? null : File(_attachment!.path),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        AppToast.success(context, context.l10n.supportTicketCreated);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(ticketCategoriesProvider).valueOrNull ??
        SupportRepository.defaultCategories;
    final selected = _category ?? categories.first;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: context.viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.supportNewTicket, style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.supportCategory, style: context.text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: categories
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: selected == c,
                        selectedColor: AppColors.brand.withOpacity(0.2),
                        onSelected: (_) => setState(() => _category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _subject,
              maxLength: 80,
              decoration:
                  InputDecoration(labelText: context.l10n.supportSubject),
            ),
            TextField(
              controller: _message,
              maxLines: 5,
              maxLength: 1000,
              decoration:
                  InputDecoration(hintText: context.l10n.supportMessageHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_attachment != null)
              Row(
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
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(context.l10n.supportAttachImage),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            GradientButton(
              label: context.l10n.supportSubmitTicket,
              icon: Icons.send_rounded,
              loading: _busy,
              onPressed: _busy ? null : () => _submit(categories),
            ),
          ],
        ),
      ),
    );
  }
}
