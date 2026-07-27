import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/leaderboard_entry.dart';
import '../data/leaderboard_repository.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaderboardProvider(_period));
    return AppScaffold(
      title: context.l10n.leaderboardTitle,
      body: Column(
        children: [
          SizedBox(height: kToolbarHeight + context.padding.top),
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: async.when(
              loading: () => const PremiumLoadingView(),
              error: (e, _) =>
                  ErrorStateView(message: context.l10n.errorGeneric),
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.leaderboard_rounded,
                    title: context.l10n.commonComingSoon,
                    message: 'Earn coins to climb the ranks!',
                  );
                }
                final podium = entries.take(3).toList();
                final rest = entries.skip(3).toList();
                return ListView(
                  padding: const EdgeInsets.only(bottom: 110),
                  children: [
                    _Podium(entries: podium),
                    const SizedBox(height: AppSpacing.lg),
                    ...rest.map((e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _RankRow(entry: e),
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
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});
  final LeaderboardPeriod period;
  final ValueChanged<LeaderboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      LeaderboardPeriod.daily: context.l10n.leaderboardDaily,
      LeaderboardPeriod.weekly: context.l10n.leaderboardWeekly,
      LeaderboardPeriod.allTime: context.l10n.leaderboardAllTime,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceHigh,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        children: LeaderboardPeriod.values.map((p) {
          final active = p == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: AppDuration.fast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.brand : null,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  labels[p]!,
                  textAlign: TextAlign.center,
                  style: context.text.labelMedium?.copyWith(
                    color: active
                        ? AppColors.white
                        : context.surfaces.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => i < entries.length ? entries[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSpot(entry: at(1), place: 2, height: 108)),
        Expanded(child: _PodiumSpot(entry: at(0), place: 1, height: 140)),
        Expanded(child: _PodiumSpot(entry: at(2), place: 3, height: 88)),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.place,
    required this.height,
  });
  final LeaderboardEntry? entry;
  final int place;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final medal = switch (place) {
      1 => AppColors.coin,
      2 => const Color(0xFFC0C4CE),
      _ => const Color(0xFFCD7F32),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          _Avatar(entry: entry!, size: place == 1 ? 62 : 50, ring: medal),
          const SizedBox(height: AppSpacing.xs),
          Text(entry!.displayName,
              style: context.text.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('${entry!.score}',
              style: context.text.bodySmall
                  ?.copyWith(color: AppColors.coin, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [medal.withOpacity(0.4), medal.withOpacity(0.05)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
            child: Center(
              child: Text('$place',
                  style: context.text.headlineMedium?.copyWith(color: medal)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${entry.rank}',
                style: context.text.titleSmall, textAlign: TextAlign.center),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Avatar(entry: entry, size: 40, ring: context.surfaces.border),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(entry.displayName,
                style: context.text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 16),
          const SizedBox(width: 4),
          Text('${entry.score}', style: context.text.titleSmall),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.size, required this.ring});
  final LeaderboardEntry entry;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: ClipOval(
        child: entry.photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: entry.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        color: context.colors.primary.withOpacity(0.2),
        child: Center(
          child: Text(
            entry.displayName.isNotEmpty
                ? entry.displayName[0].toUpperCase()
                : '?',
            style: context.text.titleMedium,
          ),
        ),
      );
}
