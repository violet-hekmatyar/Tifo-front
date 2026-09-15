import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../domain/football_models.dart';
import '../../domain/match_detail_models.dart';
import '../controllers/match_detail_controllers.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';

class MatchDetailPage extends ConsumerStatefulWidget {
  const MatchDetailPage({
    required this.matchId,
    this.recommendationSource,
    super.key,
  });
  final int matchId;
  final RecommendationSourceContext? recommendationSource;

  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  int _tab = 1;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    if (widget.matchId > 0) {
      Future.microtask(
        () => ref.read(matchDetailControllerProvider(widget.matchId)).load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matchId <= 0) return _invalidMatch(context);
    final controller = ref.watch(matchDetailControllerProvider(widget.matchId));
    final state = controller.state;
    final detail = state.value;
    if (state.status == MatchResourceStatus.loading && detail == null) {
      return const Scaffold(
        body: AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载比赛',
          message: '正在读取比分、事件与赛况…',
        ),
      );
    }
    if (detail == null) {
      return Scaffold(
        body: AppStateView(
          kind: AppStateKind.error,
          title: '比赛详情加载失败',
          message: state.message ?? '请稍后重试。',
          onRetry: controller.load,
        ),
      );
    }
    if (!_reported) {
      _reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(recommendationBehaviorDispatcherProvider)
              .record(
                RecommendationBehaviorType.detail,
                widget.recommendationSource,
              );
        }
      });
    }
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          _MatchHeader(detail: detail),
          _MatchTabs(
            selectedIndex: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _RatingsTab(matchId: widget.matchId, detail: detail),
                _OverviewTab(detail: detail, controller: controller),
                _LineupsTab(matchId: widget.matchId),
                _RankingTab(matchId: widget.matchId),
                _StatsTab(matchId: widget.matchId, detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invalidMatch(BuildContext context) => Scaffold(
    backgroundColor: AppColors.page,
    appBar: AppBar(
      leading: IconButton(
        key: const ValueKey('match_back'),
        tooltip: '返回',
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/app/data'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('比赛详情'),
    ),
    body: const AppStateView(
      kind: AppStateKind.error,
      title: '比赛编号无效',
      message: '无法打开该比赛，请返回数据页重新选择。',
    ),
  );
}

class _MatchHeader extends ConsumerWidget {
  const _MatchHeader({required this.detail});
  final MatchDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = detail.match;
    final config = ref.watch(appConfigProvider);
    final status = footballStatus(match.status);
    return Container(
      key: const ValueKey('match_header'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff152b3c), Color(0xff06131d)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('match_back'),
                tooltip: '返回',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/app/data'),
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      [match.leagueName, detail.roundName ?? detail.season]
                          .whereType<String>()
                          .where((value) => value.trim().isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${footballDate(match.matchTime)} ${footballTime(match.matchTime)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeaderTeam(
                  team: match.homeTeam,
                  imageUrl: resolveMediaUrl(config, match.homeTeam.logoUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Text(
                      match.homeTeam.score != null &&
                              match.awayTeam.score != null
                          ? '${match.homeTeam.score} : ${match.awayTeam.score}'
                          : 'VS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(color: status.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _HeaderTeam(
                  team: match.awayTeam,
                  imageUrl: resolveMediaUrl(config, match.awayTeam.logoUrl),
                ),
              ),
            ],
          ),
          if (match.leagueName.trim().isNotEmpty || detail.venue != null)
            Text(
              [match.leagueName, detail.venue]
                  .whereType<String>()
                  .where((value) => value.trim().isNotEmpty)
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _HeaderTeam extends StatelessWidget {
  const _HeaderTeam({required this.team, required this.imageUrl});
  final FootballTeam team;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('match_team_${team.id}'),
    onTap: team.id > 0 ? () => context.push('/teams/${team.id}') : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: [
          AppTeamLogo(
            identity: 'team:${team.id}',
            name: team.name,
            imageUrl: imageUrl,
            size: 56,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            team.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _MatchTabs extends StatelessWidget {
  const _MatchTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = <(String, String, IconData)>[
    ('match_tab_ratings', '评分', Icons.star_outline_rounded),
    ('match_tab_overview', '总览', Icons.timeline_rounded),
    ('match_tab_lineups', '阵容', Icons.groups_outlined),
    ('match_tab_ranking', '当前排名', Icons.leaderboard_outlined),
    ('match_tab_stats', '统计', Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xff06131d),
      border: Border(bottom: BorderSide(color: Colors.white24)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            InkWell(
              key: ValueKey(_tabs[i].$1),
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tabs[i].$3,
                      color: i == selectedIndex ? Colors.white : Colors.white60,
                    ),
                    Text(
                      _tabs[i].$2,
                      style: TextStyle(
                        color: i == selectedIndex
                            ? Colors.white
                            : Colors.white60,
                        fontWeight: i == selectedIndex
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 3,
                      width: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i == selectedIndex
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.detail, required this.controller});
  final MatchDetail detail;
  final MatchResourceController<MatchDetail> controller;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    key: const ValueKey('match_overview_refresh'),
    onRefresh: controller.refresh,
    child: ListView(
      key: const PageStorageKey('match_overview_scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (controller.state.message != null)
          _RefreshError(
            key: const ValueKey('match_overview_refresh_error'),
            message: controller.state.message!,
            onRetry: controller.refresh,
            retryKey: const ValueKey('match_overview_refresh_retry'),
          ),
        if (detail.report case final report?)
          Card(
            key: const ValueKey('match_report'),
            child: ListTile(
              onTap: report.contentId > 0
                  ? () => context.push('/contents/${report.contentId}')
                  : null,
              leading: const Icon(Icons.article_outlined),
              title: Text(report.title),
              subtitle: const Text('查看战报'),
              trailing: report.contentId > 0
                  ? const Icon(Icons.chevron_right_rounded)
                  : null,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const _SectionTitle('比赛事件'),
        if (detail.events.isEmpty)
          const CapabilityEmpty(title: '暂无比赛事件', message: '本场比赛暂未记录事件。')
        else
          for (final event in _sortedEvents(detail.events))
            _EventTile(event: event),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class _LineupsTab extends ConsumerStatefulWidget {
  const _LineupsTab({required this.matchId});
  final int matchId;
  @override
  ConsumerState<_LineupsTab> createState() => _LineupsTabState();
}

class _LineupsTabState extends ConsumerState<_LineupsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matchLineupsControllerProvider(widget.matchId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      matchLineupsControllerProvider(widget.matchId),
    );
    final state = controller.state;
    if (state.status == MatchResourceStatus.loading && state.value == null) {
      return const _ResourceState(
        key: ValueKey('match_lineups_state'),
        title: '阵容',
        loading: true,
      );
    }
    if (state.value == null) {
      return _ResourceState(
        key: const ValueKey('match_lineups_state'),
        title: '阵容',
        message: state.message,
        retryKey: const ValueKey('match_lineups_retry'),
        onRetry: controller.load,
      );
    }
    final value = state.value!;
    return RefreshIndicator(
      key: const ValueKey('match_lineups_refresh'),
      onRefresh: controller.refresh,
      child: ListView(
        key: const PageStorageKey('match_lineups_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (state.message != null)
            _RefreshError(
              message: state.message!,
              onRetry: controller.refresh,
              retryKey: const ValueKey('match_lineups_refresh_retry'),
            ),
          if (!value.hasData)
            const CapabilityEmpty(title: '暂无比赛阵容', message: '本场比赛暂未公布阵容。')
          else ...[
            if (value.home case final team?)
              _TeamLineupCard(team: team, side: '主队'),
            if (value.away case final team?)
              _TeamLineupCard(team: team, side: '客队'),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _TeamLineupCard extends ConsumerWidget {
  const _TeamLineupCard({required this.team, required this.side});
  final MatchTeamLineup team;
  final String side;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _lineupGroups(team);
    return Card(
      key: ValueKey('lineup_team_${team.teamId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: ValueKey('lineup_team_link_${team.teamId}'),
              onTap: team.teamId > 0
                  ? () => context.push('/teams/${team.teamId}')
                  : null,
              child: Row(
                children: [
                  AppTeamLogo(
                    identity: 'team:${team.teamId}',
                    name: team.teamName,
                    imageUrl: resolveMediaUrl(
                      ref.watch(appConfigProvider),
                      team.teamLogoUrl,
                    ),
                    size: 42,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$side · ${team.teamName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (team.formation?.trim().isNotEmpty == true ||
                            team.coachName?.trim().isNotEmpty == true)
                          Text(
                            [team.formation, team.coachName]
                                .whereType<String>()
                                .where((v) => v.trim().isNotEmpty)
                                .join(' · '),
                            style: const TextStyle(color: AppColors.inkMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final group in groups)
              _LineupGroup(title: group.$1, players: group.$2),
          ],
        ),
      ),
    );
  }
}

class _LineupGroup extends StatelessWidget {
  const _LineupGroup({required this.title, required this.players});
  final String title;
  final List<MatchLineupPlayer> players;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: AppSpacing.sm),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      for (final player in players) _LineupPlayerTile(player: player),
    ],
  );
}

class _LineupPlayerTile extends ConsumerWidget {
  const _LineupPlayerTile({required this.player});
  final MatchLineupPlayer player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('lineup_player_${player.playerId}'),
    contentPadding: EdgeInsets.zero,
    onTap: player.playerId > 0
        ? () => context.push('/players/${player.playerId}')
        : null,
    leading: AppPlayerAvatar(
      identity: 'player:${player.playerId}',
      name: player.playerName,
      imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), player.avatarUrl),
      size: 42,
    ),
    title: Text(
      '${player.playerName}${player.captain ? '（队长）' : ''}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      [
        if (player.shirtNumber != null) '${player.shirtNumber} 号',
        _position(player.position),
        if (player.started) '首发',
        if (player.appeared) '已出场',
        if (player.substitutedInMinute != null)
          '${player.substitutedInMinute}′ 替补登场',
        if (player.substitutedOutMinute != null)
          '${player.substitutedOutMinute}′ 被换下',
      ].whereType<String>().join(' · '),
    ),
    trailing: player.playerId > 0
        ? const Icon(Icons.chevron_right_rounded)
        : null,
  );
}

class _RankingTab extends ConsumerStatefulWidget {
  const _RankingTab({required this.matchId});
  final int matchId;
  @override
  ConsumerState<_RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends ConsumerState<_RankingTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matchOverviewControllerProvider(widget.matchId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      matchOverviewControllerProvider(widget.matchId),
    );
    final state = controller.state;
    final ranking = state.value?.ranking;
    if (state.status == MatchResourceStatus.loading && state.value == null) {
      return const _ResourceState(
        key: ValueKey('match_ranking_state'),
        title: '当前排名',
        loading: true,
      );
    }
    if (state.value == null) {
      return _ResourceState(
        key: const ValueKey('match_ranking_state'),
        title: '当前排名',
        message: state.message,
        retryKey: const ValueKey('match_ranking_retry'),
        onRetry: controller.load,
      );
    }
    return RefreshIndicator(
      key: const ValueKey('match_ranking_refresh'),
      onRefresh: controller.refresh,
      child: ListView(
        key: const PageStorageKey('match_ranking_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (state.message != null)
            _RefreshError(
              message: state.message!,
              onRetry: controller.refresh,
              retryKey: const ValueKey('match_ranking_refresh_retry'),
            ),
          if (ranking == null || !ranking.available)
            const CapabilityEmpty(title: '暂无当前排名', message: '当前赛事没有可展示的当前排名。')
          else ...[
            const _SectionTitle('当前排名'),
            if ([
              ranking.leagueName,
              ranking.seasonName,
              ranking.stageName,
            ].whereType<String>().any((v) => v.trim().isNotEmpty))
              Text(
                [ranking.leagueName, ranking.seasonName, ranking.stageName]
                    .whereType<String>()
                    .where((v) => v.trim().isNotEmpty)
                    .join(' · '),
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            if (ranking.home case final value?) _StandingCard(value: value),
            if (ranking.away case final value?) _StandingCard(value: value),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.value});
  final MatchStandingSnapshot value;
  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('standing_team_${value.teamId}'),
    margin: const EdgeInsets.only(top: AppSpacing.sm),
    child: ListTile(
      onTap: value.teamId > 0
          ? () => context.push('/teams/${value.teamId}')
          : null,
      leading: CircleAvatar(child: Text(_safe(value.rank))),
      title: Text(value.teamName, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          '赛 ${_safe(value.played)}',
          '胜 ${_safe(value.won)}',
          '平 ${_safe(value.drawn)}',
          '负 ${_safe(value.lost)}',
          '进 ${_safe(value.goalsFor)}',
          '失 ${_safe(value.goalsAgainst)}',
          '净 ${_safe(value.goalDifference)}',
        ].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('${_safe(value.points)} 积分'),
    ),
  );
}

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab({required this.matchId, required this.detail});
  final int matchId;
  final MatchDetail detail;
  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchTeamStatsControllerProvider(widget.matchId)).load();
      ref
          .read(matchPlayerStatsControllerProvider(widget.matchId))
          .loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(matchTeamStatsControllerProvider(widget.matchId));
    final players = ref.watch(
      matchPlayerStatsControllerProvider(widget.matchId),
    );
    return RefreshIndicator(
      key: const ValueKey('match_stats_refresh'),
      onRefresh: () => Future.wait([teams.refresh(), players.refresh()]),
      child: ListView(
        key: const PageStorageKey('match_stats_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _TeamStatsSection(controller: teams, detail: widget.detail),
          const SizedBox(height: AppSpacing.lg),
          _PlayerStatsSection(controller: players, detail: widget.detail),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TeamStatsSection extends StatelessWidget {
  const _TeamStatsSection({required this.controller, required this.detail});
  final MatchResourceController<List<MatchTeamStatItem>> controller;
  final MatchDetail detail;
  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    if (state.status == MatchResourceStatus.loading && state.value == null) {
      return const _ResourceState(
        key: ValueKey('match_team_stats_state'),
        title: '球队统计',
        loading: true,
      );
    }
    if (state.value == null) {
      return _ResourceState(
        key: const ValueKey('match_team_stats_state'),
        title: '球队统计',
        message: state.message,
        retryKey: const ValueKey('match_team_stats_retry'),
        onRetry: controller.load,
      );
    }
    final values = state.value!;
    final rows = <Widget>[];
    String? previousType;
    for (final item in values) {
      if (item.rawType != previousType) {
        previousType = item.rawType;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              item.rawType,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ),
        );
      }
      rows.add(_TeamStatRow(item: item));
    }
    return Card(
      key: const ValueKey('match_team_stats_state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('球队统计'),
            if (state.message != null)
              _RefreshError(
                message: state.message!,
                onRetry: controller.refresh,
                retryKey: const ValueKey('match_team_stats_refresh_retry'),
              ),
            if (values.isEmpty)
              const Text('暂无球队统计')
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.match.homeTeam.name,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Expanded(
                    child: Text('指标', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text(
                      detail.match.awayTeam.name,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...rows,
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamStatRow extends StatelessWidget {
  const _TeamStatRow({required this.item});
  final MatchTeamStatItem item;
  @override
  Widget build(BuildContext context) {
    final comparable =
        _finiteNumber(item.homeValue) != null &&
        _finiteNumber(item.awayValue) != null;
    return Padding(
      key: ValueKey('match_team_stat_${item.rawType}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _displayStat(item.homeValue, item.unit),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  item.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  _displayStat(item.awayValue, item.unit),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (comparable) _ComparisonBar(item: item),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({required this.item});
  final MatchTeamStatItem item;
  @override
  Widget build(BuildContext context) {
    final home = _finiteNumber(item.homeValue)!;
    final away = _finiteNumber(item.awayValue)!;
    if (home < 0 || away < 0) return const SizedBox.shrink();
    final total = home.abs() + away.abs();
    if (total == 0 || !total.isFinite) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          flex: (home.abs() / total * 1000).round().clamp(1, 999),
          child: const SizedBox(
            height: 6,
            child: ColoredBox(color: AppColors.inkMuted),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: (away.abs() / total * 1000).round().clamp(1, 999),
          child: const SizedBox(
            height: 6,
            child: ColoredBox(color: AppColors.success),
          ),
        ),
      ],
    );
  }
}

class _PlayerStatsSection extends StatelessWidget {
  const _PlayerStatsSection({required this.controller, required this.detail});
  final MatchPlayerStatsController controller;
  final MatchDetail detail;
  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final teams = [
      detail.match.homeTeam,
      detail.match.awayTeam,
    ].where((team) => team.id > 0).toList(growable: false);
    final positions = state.records
        .map((value) => value.position?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return Card(
      key: const ValueKey('match_player_stats_state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('球员统计'),
            if (teams.isNotEmpty || positions.isNotEmpty)
              _PlayerStatFilters(
                controller: controller,
                teams: teams,
                positions: positions,
              ),
            if (state.status == TeamPagedStatus.loading &&
                state.records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.status == TeamPagedStatus.failure &&
                state.records.isEmpty)
              _InlineRetry(
                key: const ValueKey('match_player_stats_retry'),
                message: state.message ?? '球员统计加载失败',
                onRetry: controller.loadInitial,
              )
            else if (state.records.isEmpty)
              const Text('暂无球员统计')
            else ...[
              if (state.message != null)
                _RefreshError(
                  message: state.message!,
                  onRetry: controller.refresh,
                  retryKey: const ValueKey('match_player_stats_refresh_retry'),
                ),
              for (final player in state.records)
                _PlayerStatTile(player: player),
              if (state.loadingMore)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.appendMessage != null)
                TextButton(
                  key: const ValueKey('match_player_stats_append_retry'),
                  onPressed: controller.loadMore,
                  child: Text('${state.appendMessage}，点击重试'),
                )
              else if (state.hasMore)
                TextButton(
                  key: const ValueKey('match_player_stats_load_more'),
                  onPressed: controller.loadMore,
                  child: const Text('加载更多'),
                )
              else
                const Text('已经到底了', textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerStatFilters extends StatelessWidget {
  const _PlayerStatFilters({
    required this.controller,
    required this.teams,
    required this.positions,
  });
  final MatchPlayerStatsController controller;
  final List<FootballTeam> teams;
  final List<String> positions;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('筛选', style: TextStyle(fontWeight: FontWeight.w700)),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          ChoiceChip(
            key: const ValueKey('match_player_filter_all'),
            label: const Text('全部球队'),
            selected: controller.teamId == null,
            onSelected: (_) =>
                controller.setFilter(position: controller.position),
          ),
          for (final team in teams)
            ChoiceChip(
              key: ValueKey('match_player_filter_team_${team.id}'),
              label: Text(team.name),
              selected: controller.teamId == team.id,
              onSelected: (_) => controller.setFilter(
                teamId: team.id,
                position: controller.position,
              ),
            ),
        ],
      ),
      if (positions.isNotEmpty)
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              key: const ValueKey('match_player_filter_position_all'),
              label: const Text('全部位置'),
              selected: controller.position == null,
              onSelected: (_) =>
                  controller.setFilter(teamId: controller.teamId),
            ),
            for (final position in positions)
              ChoiceChip(
                key: ValueKey('match_player_filter_position_$position'),
                label: Text(_position(position) ?? position),
                selected: controller.position == position,
                onSelected: (_) => controller.setFilter(
                  teamId: controller.teamId,
                  position: position,
                ),
              ),
          ],
        ),
    ],
  );
}

class _PlayerStatTile extends ConsumerWidget {
  const _PlayerStatTile({required this.player});
  final MatchPlayerStat player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('stat_player_${player.playerId}'),
    contentPadding: EdgeInsets.zero,
    onTap: player.playerId > 0
        ? () => context.push('/players/${player.playerId}')
        : null,
    leading: AppPlayerAvatar(
      identity: 'player:${player.playerId}',
      name: player.playerName,
      imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), player.avatarUrl),
      size: 40,
    ),
    title: Text(
      '${player.playerName}${player.captain ? '（队长）' : ''}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(_playerStatDetails(player)),
    trailing: Text(_finiteDisplay(player.officialRating, digits: 1)),
  );
}

class _RatingsTab extends ConsumerStatefulWidget {
  const _RatingsTab({required this.matchId, required this.detail});
  final int matchId;
  final MatchDetail detail;
  @override
  ConsumerState<_RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends ConsumerState<_RatingsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matchRatingsControllerProvider(widget.matchId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      matchRatingsControllerProvider(widget.matchId),
    );
    final state = controller.state;
    final teams = [
      widget.detail.match.homeTeam,
      widget.detail.match.awayTeam,
    ].where((team) => team.id > 0).toList(growable: false);
    if (state.status == MatchRatingsStatus.loading && state.records.isEmpty) {
      return const _ResourceState(
        key: ValueKey('match_ratings_state'),
        title: '评分',
        loading: true,
      );
    }
    if (state.status == MatchRatingsStatus.failure && state.records.isEmpty) {
      return _ResourceState(
        key: const ValueKey('match_ratings_state'),
        title: '评分',
        message: state.message,
        retryKey: const ValueKey('match_ratings_retry'),
        onRetry: controller.load,
      );
    }
    return RefreshIndicator(
      key: const ValueKey('match_ratings_refresh'),
      onRefresh: controller.refresh,
      child: ListView(
        key: const PageStorageKey('match_ratings_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (teams.length > 1)
            Wrap(
              key: const ValueKey('match_ratings_team_filter'),
              spacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  key: const ValueKey('match_ratings_team_all'),
                  label: const Text('全部'),
                  selected: controller.teamId == null,
                  onSelected: (_) => controller.load(force: true),
                ),
                for (final team in teams)
                  ChoiceChip(
                    key: ValueKey('match_ratings_team_${team.id}'),
                    label: Text(team.name),
                    selected: controller.teamId == team.id,
                    onSelected: (_) =>
                        controller.load(teamId: team.id, force: true),
                  ),
              ],
            ),
          if (state.message != null)
            _RefreshError(
              message: state.message!,
              onRetry: controller.refresh,
              retryKey: const ValueKey('match_ratings_refresh_retry'),
            ),
          if (state.status == MatchRatingsStatus.empty)
            const CapabilityEmpty(title: '暂无可评分球员', message: '暂无真实评分数据。')
          else
            for (final rating in state.records)
              _RatingTile(
                rating: rating,
                busy: controller.isBusy(rating.playerId),
                onRate: rating.playerId > 0
                    ? () => _chooseRating(context, controller, rating)
                    : null,
                onCancel:
                    rating.playerId > 0 && rating.currentUserRating != null
                    ? () => controller.cancel(rating.playerId)
                    : null,
              ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _chooseRating(
    BuildContext context,
    MatchRatingsController controller,
    MatchRatingSummary rating,
  ) async {
    var selected = _safeRating(
      rating.currentUserRating ?? rating.averageRating ?? rating.officialRating,
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('为 ${rating.playerName} 评分'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                key: const ValueKey('match_rating_slider'),
                value: selected,
                min: 1,
                max: 10,
                divisions: 18,
                label: selected.toStringAsFixed(1),
                onChanged: (value) => setDialogState(() => selected = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('match_rating_cancel_input'),
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const ValueKey('match_rating_submit_input'),
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
    if (value != null) await controller.submit(rating.playerId, value);
  }
}

class _RatingTile extends ConsumerWidget {
  const _RatingTile({
    required this.rating,
    required this.busy,
    required this.onRate,
    required this.onCancel,
  });
  final MatchRatingSummary rating;
  final bool busy;
  final VoidCallback? onRate;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    key: ValueKey('rating_player_${rating.playerId}'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: rating.playerId > 0
            ? () => context.push('/players/${rating.playerId}')
            : null,
        leading: AppPlayerAvatar(
          identity: 'player:${rating.playerId}',
          name: rating.playerName,
          imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), null),
          size: 40,
        ),
        title: Text(rating.playerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '官方 ${_finiteDisplay(rating.officialRating, digits: 1)} · 用户 ${_finiteDisplay(rating.averageRating, digits: 1)} · ${rating.ratingCount} 人评分${rating.currentUserRating == null ? '' : ' · 我的 ${_finiteDisplay(rating.currentUserRating, digits: 1)}'}',
            ),
            if (rating.distribution.isNotEmpty)
              Text(
                rating.distribution.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: busy
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCancel != null)
                    IconButton(
                      key: ValueKey('cancel_rating_${rating.playerId}'),
                      tooltip: '撤销评分',
                      onPressed: onCancel,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                  if (onRate != null)
                    IconButton(
                      key: ValueKey('rate_player_${rating.playerId}'),
                      tooltip: '提交评分',
                      onPressed: onRate,
                      icon: const Icon(Icons.star_rounded),
                    ),
                ],
              ),
      ),
    ),
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final MatchEvent event;
  @override
  Widget build(BuildContext context) {
    final actors = <Widget>[
      if (event.teamName?.trim().isNotEmpty == true)
        _eventLink(
          context,
          key: ValueKey('event_team_${event.id}'),
          text: event.teamName!,
          id: event.teamId,
          path: 'teams',
        ),
      if (event.playerName?.trim().isNotEmpty == true)
        _eventLink(
          context,
          key: ValueKey('event_player_${event.id}'),
          text: event.playerName!,
          id: event.playerId,
          path: 'players',
        ),
      if (event.assistPlayerName?.trim().isNotEmpty == true)
        _eventLink(
          context,
          key: ValueKey('event_assist_${event.id}'),
          text: '助攻 ${event.assistPlayerName}',
          id: event.assistPlayerId,
          path: 'players',
        ),
      if (event.description?.trim().isNotEmpty == true)
        Text(event.description!),
      if (event.period?.trim().isNotEmpty == true) Text(event.period!),
      if (event.hasDebate) const Text('存在争议'),
    ];
    return Card(
      key: ValueKey('match_event_${event.id}'),
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_eventIcon(event.type), size: 18)),
        title: Text(
          '${_eventType(event.type)}${event.scoreAfter == null ? '' : ' · ${event.scoreAfter}'}',
        ),
        subtitle: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 2,
          children: [
            Text(
              '${event.minute}${event.extraMinute == null ? '' : '+${event.extraMinute}'}′',
            ),
            ...actors,
          ],
        ),
      ),
    );
  }
}

Widget _eventLink(
  BuildContext context, {
  required Key key,
  required String text,
  required int? id,
  required String path,
}) => InkWell(
  key: key,
  onTap: id != null && id > 0 ? () => context.push('/$path/$id') : null,
  child: Text(text),
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _ResourceState extends StatelessWidget {
  const _ResourceState({
    required this.title,
    this.loading = false,
    this.message,
    this.onRetry,
    this.retryKey,
    super.key,
  });
  final String title;
  final bool loading;
  final String? message;
  final VoidCallback? onRetry;
  final Key? retryKey;
  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('${title}_state_card'),
    margin: const EdgeInsets.all(AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: loading
          ? Column(
              children: [
                Text(title),
                const SizedBox(height: AppSpacing.sm),
                const CircularProgressIndicator(),
              ],
            )
          : Column(
              children: [
                Text(title),
                Text(message ?? '加载失败，请稍后重试。'),
                if (onRetry != null)
                  TextButton(
                    key: retryKey,
                    onPressed: onRetry,
                    child: const Text('重试'),
                  ),
              ],
            ),
    ),
  );
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({
    required this.message,
    required this.onRetry,
    this.retryKey,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;
  final Key? retryKey;
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.error.withValues(alpha: .08),
    child: ListTile(
      title: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: TextButton(
        key: retryKey,
        onPressed: onRetry,
        child: const Text('重试'),
      ),
    ),
  );
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message),
      TextButton(onPressed: onRetry, child: const Text('重试')),
    ],
  );
}

List<(String, List<MatchLineupPlayer>)> _lineupGroups(MatchTeamLineup team) {
  final seen = <int>{};
  List<MatchLineupPlayer> unique(Iterable<MatchLineupPlayer> values) => [
    for (final player in values)
      if (player.playerId <= 0 || seen.add(player.playerId)) player,
  ];
  return [
    if (team.starters.isNotEmpty) ('首发', unique(team.starters)),
    if (team.substitutes.isNotEmpty) ('替补', unique(team.substitutes)),
    if (team.bench.isNotEmpty) ('替补席', unique(team.bench)),
  ];
}

List<MatchEvent> _sortedEvents(List<MatchEvent> values) => [
  ...values.indexed.toList()..sort((a, b) {
    final minute = a.$2.minute.compareTo(b.$2.minute);
    if (minute != 0) return minute;
    final extra = (a.$2.extraMinute ?? -1).compareTo(b.$2.extraMinute ?? -1);
    return extra != 0 ? extra : a.$1.compareTo(b.$1);
  }),
].map((entry) => entry.$2).toList(growable: false);

String _eventType(String value) => switch (value.trim().toUpperCase()) {
  'GOAL' => '进球',
  'OWN_GOAL' => '乌龙球',
  'PENALTY_GOAL' => '点球',
  'YELLOW_CARD' => '黄牌',
  'RED_CARD' => '红牌',
  'SUBSTITUTION' => '换人',
  _ => '未知事件',
};

IconData _eventIcon(String value) => switch (value.trim().toUpperCase()) {
  'GOAL' || 'OWN_GOAL' || 'PENALTY_GOAL' => Icons.sports_soccer,
  'YELLOW_CARD' || 'RED_CARD' => Icons.crop_square,
  'SUBSTITUTION' => Icons.swap_horiz_rounded,
  _ => Icons.info_outline,
};

String? _position(String? value) => switch (value?.trim().toUpperCase()) {
  'GOALKEEPER' || 'GK' => '门将',
  'DEFENDER' || 'DF' => '后卫',
  'MIDFIELDER' || 'MF' => '中场',
  'FORWARD' || 'FW' => '前锋',
  null || '' => null,
  _ => value,
};

String _safe(num? value) => value?.toString() ?? '—';
double? _finiteNumber(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
String _displayStat(Object? value, String? unit) =>
    value == null || (value is num && !value.isFinite)
    ? '—'
    : '$value${unit ?? ''}';
String _finiteDisplay(double? value, {required int digits}) =>
    value == null || !value.isFinite ? '—' : value.toStringAsFixed(digits);
double _safeRating(double? value) =>
    value == null || !value.isFinite ? 7.0 : value.clamp(1.0, 10.0);

String _playerStatDetails(MatchPlayerStat player) => [
  if (player.teamName?.trim().isNotEmpty == true) player.teamName,
  if (player.position?.trim().isNotEmpty == true) _position(player.position),
  if (player.shirtNumber != null) '${player.shirtNumber} 号',
  if (player.starter) '首发',
  if (player.minutes != null) '${player.minutes} 分钟',
  if (player.goals != null) '${player.goals} 球',
  if (player.assists != null) '${player.assists} 助攻',
  if (player.shots != null) '射门 ${player.shots}',
  if (player.shotsOnTarget != null) '射正 ${player.shotsOnTarget}',
  if (player.passes != null) '传球 ${player.passes}',
  if (player.successfulPasses != null) '成功 ${player.successfulPasses}',
  if (player.passAccuracy != null)
    '传球率 ${_finiteDisplay(player.passAccuracy, digits: 1)}%',
  if (player.keyPasses != null) '关键传球 ${player.keyPasses}',
  if (player.tackles != null) '铲断 ${player.tackles}',
  if (player.interceptions != null) '拦截 ${player.interceptions}',
  if (player.saves != null) '扑救 ${player.saves}',
  if (player.yellowCards != null) '黄牌 ${player.yellowCards}',
  if (player.redCards != null) '红牌 ${player.redCards}',
  if (player.userRatingAverage != null)
    '用户评分 ${_finiteDisplay(player.userRatingAverage, digits: 1)}',
  if (player.userRatingCount > 0) '评分人数 ${player.userRatingCount}',
  if (player.currentUserRating != null)
    '我的评分 ${_finiteDisplay(player.currentUserRating, digits: 1)}',
].whereType<String>().join(' · ');
