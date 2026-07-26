import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';

/// A lightweight "report a problem" form. Writes to the `reports` collection
/// (owner-scoped by security rules) so it appears in the admin Reports triage.
Future<void> showReportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ReportSheet(),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet();

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _message = TextEditingController();
  String _category = 'bug';
  bool _busy = false;

  static const _categories = ['bug', 'payment', 'offer', 'account', 'other'];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final message = _message.text.trim();
    if (uid == null || message.isEmpty) {
      AppToast.error(context, 'Please describe the issue.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(firestoreProvider).collection(FsPaths.reports).add({
        'uid': uid,
        'category': _category,
        'subject': _category,
        'message': message,
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, context.l10n.reportSent);
    } catch (_) {
      if (mounted) AppToast.error(context, context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: context.viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.settingsReport, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: _categories
                .map((c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      selectedColor: AppColors.brand.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _category = c),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(hintText: context.l10n.reportHint),
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            label: context.l10n.reportSubmit,
            icon: Icons.send_rounded,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
