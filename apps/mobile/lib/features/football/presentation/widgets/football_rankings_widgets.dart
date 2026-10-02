import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_ranking_models.dart';
import '../controllers/football_rankings_controller.dart';

class SectionButton extends StatelessWidget {
  const SectionButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.inkMuted,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),
  );
}

class RankingContextBar extends StatelessWidget {
  const RankingContextBar({
    required this.state,
    required this.controller,
    this.trailing = const [],
    super.key,
  });
  final FootballRankingsState state;
  final FootballRankingsController controller;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          _CompactSelector(
            key: const ValueKey('ranking_filter_season'),
            label:
                state.seasons
                    .where((item) => item.id == state.selectedSeasonId)
                    .firstOrNull
                    ?.name ??
                '赛季',
            icon: Icons.calendar_month_outlined,
            onTap: () => _showSeasonStageOptions(context),
          ),
          ...trailing,
        ],
      ),
    ),
  );

  Future<void> _showSeasonStageOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _SeasonStageSheet(initialState: state, controller: controller),
    );
  }
}

class _SeasonStageSheet extends StatelessWidget {
  const _SeasonStageSheet({
    required this.initialState,
    required this.controller,
  });

  final FootballRankingsState initialState;
  final FootballRankingsController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final controllerState = controller.state;
      final state = controllerState.selectedLeagueId == null
          ? initialState
          : controllerState;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    '选择赛季与阶段',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _SheetSectionLabel(label: '赛季'),
                for (final season in state.seasons)
                  ListTile(
                    key: ValueKey('ranking_season_option_${season.id}'),
                    title: Text(season.name),
                    trailing: season.id == state.selectedSeasonId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    selected: season.id == state.selectedSeasonId,
                    onTap: () => controller.selectSeason(season.id),
                  ),
                const Divider(height: AppSpacing.lg),
                const _SheetSectionLabel(label: '阶段'),
                ListTile(
                  key: const ValueKey('ranking_stage_option_all'),
                  title: const Text('全部阶段'),
                  trailing: state.selectedStageId == null
                      ? const Icon(Icons.check_rounded)
                      : null,
                  selected: state.selectedStageId == null,
                  onTap: () => controller.selectStage(null),
                ),
                for (final stage in state.stages)
                  ListTile(
                    key: ValueKey('ranking_stage_option_${stage.id}'),
                    title: Text(stage.name),
                    trailing: stage.id == state.selectedStageId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    selected: stage.id == state.selectedStageId,
                    onTap: () => controller.selectStage(stage.id),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      0,
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Backwards-compatible wrapper retained for the existing ranking widget tests.
/// The compact context bar is now also used directly by the data page.
class FootballRankingFilters extends StatelessWidget {
  const FootballRankingFilters({
    required this.state,
    required this.controller,
    super.key,
  });

  final FootballRankingsState state;
  final FootballRankingsController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: RankingContextBar(state: state, controller: controller),
  );
}

class _CompactSelector extends StatelessWidget {
  const _CompactSelector({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      height: 34,
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const Icon(Icons.expand_more_rounded, size: 16),
        ],
      ),
    ),
  );
}

class StandingsList extends ConsumerWidget {
  const StandingsList({required this.table, super.key});
  final StandingTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return ListView(
      key: const PageStorageKey('football_standings'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        const _StandingHeader(),
        for (final record in table.records)
          _StandingRow(record: record, config: config),
      ],
    );
  }
}

class _StandingHeader extends StatelessWidget {
  const _StandingHeader();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceMuted,
    child: SizedBox(
      height: 42,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 26),
            SizedBox(width: 34),
            Expanded(child: Text('球队')),
            _TableCell('场', width: 28),
            _TableCell('胜', width: 28),
            _TableCell('平', width: 28),
            _TableCell('负', width: 28),
            _TableCell('进/失球', width: 62, fontSize: 11),
            _TableCell(
              '积分',
              key: ValueKey('standing_points_header'),
              width: 40,
              strong: true,
            ),
          ],
        ),
      ),
    ),
  );
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.record, required this.config});
  final StandingRecord record;
  final dynamic config;

  @override
  Widget build(BuildContext context) {
    final background = record.rank <= 4
        ? AppColors.brandSoft.withValues(alpha: .72)
        : record.rank <= 6
        ? const Color(0xFFDFF4F2)
        : AppColors.surface;
    return InkWell(
      key: ValueKey('standing_team_${record.teamId}'),
      onTap: record.teamId > 0
          ? () => context.push('/teams/${record.teamId}')
          : null,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 26, child: Text('${record.rank}')),
              AppTeamLogo(
                identity: 'team:${record.teamId}',
                name: record.teamName,
                imageUrl: resolveMediaUrl(config, record.teamLogoUrl),
                size: 28,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  record.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _TableCell('${record.played}', width: 28),
              _TableCell('${record.won}', width: 28),
              _TableCell('${record.drawn}', width: 28),
              _TableCell('${record.lost}', width: 28),
              _TableCell(
                '${record.goalsFor}/${record.goalsAgainst}',
                width: 62,
              ),
              _TableCell(
                '${record.points}',
                key: ValueKey('standing_points_${record.teamId}'),
                width: 40,
                strong: true,
                brand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerRankingList extends ConsumerWidget {
  const PlayerRankingList({
    required this.state,
    required this.onLoadMore,
    super.key,
  });
  final FootballRankingsState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return _SplitRankingLayout(
      sideItems: PlayerRankType.values,
      selected: state.playerRankType,
      onSelected: (value) => ref
          .read(footballRankingsControllerProvider)
          .selectPlayerRankType(value),
      header: const _RankingHeaderRow(children: ['球员', '球队', '数值']),
      child: _RankingRows(
        itemCount: state.playerRecords.length,
        hasMore: state.hasMore,
        loadingMore: state.loadingMore,
        appendMessage: state.appendMessage,
        onLoadMore: onLoadMore,
        itemBuilder: (context, index) {
          final record = state.playerRecords[index];
          return InkWell(
            key: ValueKey('ranking_player_${record.playerId}'),
            onTap: record.playerId > 0
                ? () => context.push('/players/${record.playerId}')
                : null,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${record.rank}')),
                  AppPlayerAvatar(
                    identity: 'player:${record.playerId}',
                    name: record.playerName,
                    imageUrl: resolveMediaUrl(config, record.playerAvatarUrl),
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      record.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      record.teamName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      record.displayValue ?? _number(record.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TeamRankingList extends ConsumerWidget {
  const TeamRankingList({
    required this.state,
    required this.onLoadMore,
    super.key,
  });
  final FootballRankingsState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return _SplitRankingLayout(
      sideItems: TeamRankType.values,
      selected: state.teamRankType,
      onSelected: (value) => ref
          .read(footballRankingsControllerProvider)
          .selectTeamRankType(value),
      header: const _RankingHeaderRow(children: ['球队', '数值']),
      child: _RankingRows(
        itemCount: state.teamRecords.length,
        hasMore: state.hasMore,
        loadingMore: state.loadingMore,
        appendMessage: state.appendMessage,
        onLoadMore: onLoadMore,
        itemBuilder: (context, index) {
          final record = state.teamRecords[index];
          return InkWell(
            key: ValueKey('ranking_team_${record.teamId}'),
            onTap: record.teamId > 0
                ? () => context.push('/teams/${record.teamId}')
                : null,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${record.rank}')),
                  AppTeamLogo(
                    identity: 'team:${record.teamId}',
                    name: record.teamName,
                    imageUrl: resolveMediaUrl(config, record.teamLogoUrl),
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      record.displayValue ?? _number(record.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplitRankingLayout<T> extends StatelessWidget {
  const _SplitRankingLayout({
    required this.sideItems,
    required this.selected,
    required this.onSelected,
    required this.header,
    required this.child,
  });
  final List<T> sideItems;
  final T selected;
  final ValueChanged<T> onSelected;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: 82,
        child: ColoredBox(
          color: AppColors.surfaceMuted,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            itemCount: sideItems.length,
            itemBuilder: (context, index) {
              final item = sideItems[index];
              final isSelected = item == selected;
              return InkWell(
                key: ValueKey('ranking_metric_$item'),
                onTap: () => onSelected(item),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  color: isSelected ? AppColors.brand : Colors.transparent,
                  child: Text(
                    (item as dynamic).label as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.inkMuted,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Expanded(
        child: Column(
          children: [
            header,
            Expanded(child: child),
          ],
        ),
      ),
    ],
  );
}

class _RankingHeaderRow extends StatelessWidget {
  const _RankingHeaderRow({required this.children});
  final List<String> children;
  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('ranking_header'),
    color: AppColors.surfaceMuted,
    child: SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 34),
          const SizedBox(width: 34),
          for (var index = 0; index < children.length; index++)
            Expanded(
              flex: index == children.length - 1
                  ? 0
                  : index == 0
                  ? 3
                  : 2,
              child: index == children.length - 1
                  ? SizedBox(
                      width: 58,
                      child: Text(children[index], textAlign: TextAlign.right),
                    )
                  : Text(children[index]),
            ),
        ],
      ),
    ),
  );
}

class _RankingRows extends StatelessWidget {
  const _RankingRows({
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    this.appendMessage,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final String? appendMessage;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 320) onLoadMore();
          return false;
        },
        child: ListView.builder(
          itemCount: itemCount + 1,
          itemBuilder: (context, index) {
            if (index < itemCount) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: itemBuilder(context, index),
              );
            }
            return SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : appendMessage != null
                    ? TextButton(
                        onPressed: onLoadMore,
                        child: Text('$appendMessage 点击重试'),
                      )
                    : Text(
                        hasMore ? '继续上滑加载' : '已经到底了',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
              ),
            );
          },
        ),
      );
}

class _TableCell extends StatelessWidget {
  const _TableCell(
    this.value, {
    this.width = 32,
    this.fontSize,
    this.strong = false,
    this.brand = false,
    super.key,
  });
  final String value;
  final double width;
  final double? fontSize;
  final bool strong;
  final bool brand;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: brand ? AppColors.brandDark : AppColors.ink,
        fontSize: fontSize,
        fontWeight: strong ? FontWeight.w800 : null,
      ),
    ),
  );
}

String _number(double? value) {
  if (value == null) return '—';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
