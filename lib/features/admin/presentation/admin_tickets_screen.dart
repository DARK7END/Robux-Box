import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_user.dart';
import '../../../models/support_ticket.dart';
import '../../support/data/support_repository.dart';
import '../../support/domain/support_providers.dart';
import '../../support/presentation/support_screen.dart';
import '../../support/presentation/widgets/ticket_thread_sheet.dart';
import 'widgets/tier_filter_row.dart';

/// Admin support desk: every user's tickets, filterable, with the category
/// list editable in place.
class AdminTicketsScreen extends ConsumerStatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  ConsumerState<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

enum _Filter { awaiting, open, all }

class _AdminTicketsScreenState extends ConsumerState<AdminTicketsScreen> {
  _Filter _filter = _Filter.awaiting;
  VipLevel? _tierFilter;

  bool _matches(SupportTicket t) {
    final statusOk = switch (_filter) {
      _Filter.awaiting => t.status == TicketStatus.open && !t.lastSenderIsAdmin,
      _Filter.open => t.status == TicketStatus.open,
      _Filter.all => true,
    };
    return statusOk && (_tierFilter == null || t.vipLevel == _tierFilter);
  }

  String _label(_Filter f) => switch (f) {
        _Filter.awaiting => context.l10n.supportFilterAwaiting,
        _Filter.open => context.l10n.supportStatusOpen,
        _Filter.all => context.l10n.supportFilterAll,
      };

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return AppScaffold(
      title: context.l10n.supportTitle,
      actions: [
        IconButton(
          tooltip: context.l10n.supportManageCategories,
          onPressed: () => _showCategoryEditor(context, ref),
          icon: const Icon(Icons.sell_outlined),
        ),
      ],
      body: Column(
        children: [
          SizedBox(height: kToolbarHeight + context.padding.top),
          SegmentedButton<_Filter>(
            segments: _Filter.values
                .map((f) => ButtonSegment(value: f, label: Text(_label(f))))
                .toList(),
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
          TierFilterRow(
            selected: _tierFilter,
            onSelect: (v) => setState(() => _tierFilter = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const PremiumLoadingView(),
              error: (e, _) =>
                  ErrorStateView(message: context.l10n.errorGeneric),
              data: (all) {
                final tickets = all.where(_matches).toList();
                if (tickets.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.inbox_rounded,
                    title: context.l10n.supportNoTicketsTitle,
                    message: context.l10n.supportNoTicketsDesc,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => TicketListTile(
                    ticket: tickets[i],
                    showRequester: true,
                    onTap: () => showTicketThreadSheet(context,
                        ticket: tickets[i], isAdminView: true),
                  ).animate().fadeIn(delay: (30 * i).ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCategoryEditor(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CategoryEditor(),
  );
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor();

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  final _newCategory = TextEditingController();
  List<String>? _draft;
  bool _busy = false;

  @override
  void dispose() {
    _newCategory.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> categories) async {
    setState(() => _busy = true);
    final result =
        await ref.read(supportRepositoryProvider).saveCategories(categories);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        AppToast.success(context, context.l10n.supportCategoriesSaved);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(ticketCategoriesProvider).valueOrNull ??
        SupportRepository.defaultCategories;
    final categories = _draft ??= List<String>.from(live);

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
          Text(context.l10n.supportManageCategories,
              style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.supportCategoriesDesc,
              style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: categories
                .map((c) => InputChip(
                      label: Text(c),
                      onDeleted: categories.length <= 1
                          ? null
                          : () => setState(() => categories.remove(c)),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCategory,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                      hintText: context.l10n.supportNewCategoryHint),
                  onSubmitted: (_) => _add(categories),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: () => _add(categories),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: context.l10n.commonSave,
            loading: _busy,
            onPressed: _busy ? null : () => _save(categories),
          ),
        ],
      ),
    );
  }

  void _add(List<String> categories) {
    final value = _newCategory.text.trim().toLowerCase();
    if (value.isEmpty || categories.contains(value)) return;
    setState(() {
      categories.add(value);
      _newCategory.clear();
    });
  }
}
