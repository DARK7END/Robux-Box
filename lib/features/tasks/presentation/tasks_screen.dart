import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/offer.dart';
import '../data/offers_repository.dart';
import 'widgets/offer_card.dart';

/// Tasks tab: native offer feed with filters + search, plus the full offerwall.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  OfferCategory? _category;
  String _query = '';
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openOffer(Offer offer) async {
    final uri = Uri.tryParse(offer.trackingUrl);
    if (uri != null && offer.trackingUrl.isNotEmpty) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      context.push(AppRoutes.offerwall);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersProvider(_category));

    return AppScaffold(
      showAppBar: false,
      padded: false,
      body: Column(
        children: [
          _Header(
            searching: _searching,
            controller: _searchController,
            onToggleSearch: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchController.clear();
              }
            }),
            onQuery: (v) => setState(() => _query = v.toLowerCase()),
          ),
          _CategoryChips(
            selected: _category,
            onSelect: (c) => setState(() => _category = c),
          ),
          Expanded(
            child: offersAsync.when(
              loading: () => _skeleton(),
              error: (e, _) => ErrorStateView(
                message: context.l10n.errorGeneric,
                onRetry: () => ref.invalidate(offersProvider(_category)),
              ),
              data: (offers) {
                final filtered = _query.isEmpty
                    ? offers
                    : offers
                        .where((o) => o.title.toLowerCase().contains(_query))
                        .toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 110),
                  children: [
                    _OfferwallBanner(
                        onTap: () => context.push(AppRoutes.offerwall)),
                    const SizedBox(height: AppSpacing.lg),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.huge),
                        child: EmptyStateView(
                          icon: Icons.checklist_rounded,
                          title: context.l10n.tasksEmpty,
                          message: context.l10n.tasksEmptyDesc,
                          actionLabel: context.l10n.tasksOfferwall,
                          onAction: () => context.push(AppRoutes.offerwall),
                        ),
                      )
                    else
                      ...filtered.asMap().entries.map((e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: OfferCard(
                              offer: e.value,
                              onTap: () => _openOffer(e.value),
                            )
                                .animate()
                                .fadeIn(delay: (40 * e.key).ms)
                                .slideX(begin: 0.08),
                          )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 110),
        children: [
          const ShimmerBox(height: 92, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
              6,
              (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerBox(height: 84, radius: AppRadius.lg),
                  )),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searching,
    required this.controller,
    required this.onToggleSearch,
    required this.onQuery,
  });

  final bool searching;
  final TextEditingController controller;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: context.padding.top + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDuration.fast,
              child: searching
                  ? TextField(
                      key: const ValueKey('search'),
                      controller: controller,
                      autofocus: true,
                      onChanged: onQuery,
                      decoration: InputDecoration(
                        hintText: context.l10n.tasksSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                    )
                  : Column(
                      key: const ValueKey('title'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.tasksTitle,
                            style: context.text.headlineSmall),
                        Text(context.l10n.tasksSubtitle,
                            style: context.text.bodySmall),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onToggleSearch,
            icon: Icon(searching ? Icons.close_rounded : Icons.search_rounded),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaces.surfaceHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelect});
  final OfferCategory? selected;
  final ValueChanged<OfferCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, OfferCategory?)>[
      (context.l10n.tasksAll, null),
      (context.l10n.tasksSurveys, OfferCategory.survey),
      (context.l10n.tasksGames, OfferCategory.game),
      (context.l10n.tasksApps, OfferCategory.app),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (label, cat) = chips[i];
          final active = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? AppGradients.brand : null,
                color: active ? null : context.surfaces.surfaceHigh,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                    color: active
                        ? Colors.transparent
                        : context.surfaces.border),
              ),
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color:
                      active ? AppColors.black : context.surfaces.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OfferwallBanner extends StatelessWidget {
  const _OfferwallBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppGradients.accent,
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 34),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.tasksOfferwall,
                    style: context.text.titleMedium
                        ?.copyWith(color: Colors.white)),
                Text(context.l10n.earnOfferwallDesc,
                    style: context.text.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
