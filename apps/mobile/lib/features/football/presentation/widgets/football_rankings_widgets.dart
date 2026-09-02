import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_ranking_models.dart';
import '../controllers/football_rankings_controller.dart';

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
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'ranking_league_${state.selectedLeagueId ?? 'none'}',
                  ),
                  initialValue: state.selectedLeagueId,
                  decoration: const InputDecoration(labelText: '赛事'),
                  items: [
                    for (final league in state.leagues)
                      DropdownMenuItem(
                        value: league.id,
                        child: Text(
                          league.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.status == FootballRankingsStatus.loading
                      ? null
                      : (value) {
                          if (value != null) controller.selectLeague(value);
                        },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'ranking_season_${state.selectedSeasonId ?? 'none'}',
                  ),
                  initialValue: state.selectedSeasonId,
                  decoration: const InputDecoration(labelText: '赛季'),
                  items: [
                    for (final season in state.seasons)
                      DropdownMenuItem(
                        value: season.id,
                        child: Text(
                          season.current ? '${season.name} · 当前' : season.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.status == FootballRankingsStatus.loading
                      ? null
                      : (value) {
                          if (value != null) controller.selectSeason(value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'ranking_stage_${state.selectedStageId ?? 'all'}',
                  ),
                  initialValue: state.selectedStageId ?? 0,
                  decoration: const InputDecoration(labelText: '阶段'),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('全部阶段')),
                    for (final stage in state.stages)
                      DropdownMenuItem(
                        value: stage.id,
                        child: Text(
                          stage.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.status == FootballRankingsStatus.loading
                      ? null
                      : (value) => controller.selectStage(
                          value == null || value == 0 ? null : value,
                        ),
                ),
              ),
              if (state.view == FootballRankingView.players) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<PlayerRankType>(
                    key: const ValueKey('player_rank_type'),
                    initialValue: state.playerRankType,
                    decoration: const InputDecoration(labelText: '指标'),
                    items: [
                      for (final type in PlayerRankType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.selectPlayerRankType(value);
                    },
                  ),
                ),
              ] else if (state.view == FootballRankingView.teams) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<TeamRankType>(
                    key: const ValueKey('team_rank_type'),
                    initialValue: state.teamRankType,
                    decoration: const InputDecoration(labelText: '指标'),
                    items: [
                      for (final type in TeamRankType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.selectTeamRankType(value);
                    },
                  ),
                ),
              ],
            ],
          ),
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
    return ListView.separated(
      key: const PageStorageKey('football_standings'),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: table.records.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _StandingHeader();
        }
        final record = table.records[index - 1];
        return InkWell(
          key: ValueKey('standing_team_${record.teamId}'),
          onTap: () => context.push('/teams/${record.teamId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text('${record.rank}')),
                AppTeamLogo(
                  identity: 'team:${record.teamId}',
                  name: record.teamName,
                  imageUrl: resolveMediaUrl(config, record.teamLogoUrl),
                  size: 30,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    record.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _Cell('${record.played}'),
                _Cell('${record.won}'),
                _Cell('${record.drawn}'),
                _Cell('${record.lost}'),
                _Cell(
                  record.goalDifference > 0
                      ? '+${record.goalDifference}'
                      : '${record.goalDifference}',
                ),
                _Cell('${record.points}', strong: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StandingHeader extends StatelessWidget {
  const _StandingHeader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(width: 28, child: Text('排名')),
        SizedBox(width: 38),
        Expanded(child: Text('球队')),
        _Cell('赛'),
        _Cell('胜'),
        _Cell('平'),
        _Cell('负'),
        _Cell('净胜'),
        _Cell('积分', strong: true),
      ],
    ),
  );
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
    return _PagedRankingList(
      key: const PageStorageKey('football_player_rankings'),
      itemCount: state.playerRecords.length,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      appendMessage: state.appendMessage,
      onLoadMore: onLoadMore,
      itemBuilder: (context, index) {
        final record = state.playerRecords[index];
        return ListTile(
          key: ValueKey('ranking_player_${record.playerId}'),
          onTap: () => context.push('/players/${record.playerId}'),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 28, child: Text('${record.rank}')),
              AppTeamLogo(
                identity: 'player:${record.playerId}',
                name: record.playerName,
                imageUrl: resolveMediaUrl(config, record.playerAvatarUrl),
                size: 38,
              ),
            ],
          ),
          title: Text(record.playerName),
          subtitle: Text(
            [
              record.teamName,
              if (record.appearances != null) '${record.appearances} 场',
            ].whereType<String>().join(' · '),
          ),
          trailing: Text(
            record.displayValue ?? _number(record.value),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
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
    return _PagedRankingList(
      key: const PageStorageKey('football_team_rankings'),
      itemCount: state.teamRecords.length,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      appendMessage: state.appendMessage,
      onLoadMore: onLoadMore,
      itemBuilder: (context, index) {
        final record = state.teamRecords[index];
        return ListTile(
          key: ValueKey('ranking_team_${record.teamId}'),
          onTap: () => context.push('/teams/${record.teamId}'),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 28, child: Text('${record.rank}')),
              AppTeamLogo(
                identity: 'team:${record.teamId}',
                name: record.teamName,
                imageUrl: resolveMediaUrl(config, record.teamLogoUrl),
                size: 38,
              ),
            ],
          ),
          title: Text(record.teamName),
          subtitle: record.played == null ? null : Text('${record.played} 场'),
          trailing: Text(
            record.displayValue ?? _number(record.value),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }
}

class _PagedRankingList extends StatelessWidget {
  const _PagedRankingList({
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    this.appendMessage,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool hasMore;
  final bool loadingMore;
  final String? appendMessage;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 320) onLoadMore();
          return false;
        },
        child: ListView.builder(
          key: key,
          itemCount: itemCount + 1,
          itemBuilder: (context, index) {
            if (index < itemCount) return itemBuilder(context, index);
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

class _Cell extends StatelessWidget {
  const _Cell(this.value, {this.strong = false});
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 33,
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: strong ? FontWeight.w800 : null),
    ),
  );
}

String _number(double? value) {
  if (value == null) return '—';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
