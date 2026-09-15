import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../user_center/data/user_center_repository.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../domain/football_models.dart';
import '../../domain/match_display_sort.dart';
import '../../domain/team_detail_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/football_rankings_controller.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';

class TeamDetailPage extends ConsumerStatefulWidget {
  const TeamDetailPage({
    required this.teamId,
    this.recommendationSource,
    super.key,
  });
  final int teamId;
  final RecommendationSourceContext? recommendationSource;
  @override
  ConsumerState<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends ConsumerState<TeamDetailPage> {
  int _tab = 0;
  late final TeamDetailContext _request;
  bool _detailReported = false;

  @override
  void initState() {
    super.initState();
    final ranking = ref.read(footballRankingsControllerProvider).state;
    _request = (
      teamId: widget.teamId,
      seasonId: ranking.selectedSeasonId,
      stageId: ranking.selectedStageId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teamDetailProvider(widget.teamId));
    if (detail.hasValue && !_detailReported) {
      _detailReported = true;
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
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/app/data'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('球队详情'),
      ),
      body: detail.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球队',
          message: '正在读取球队基础资料…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球队',
          error: error,
          onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        ),
        data: (team) => Column(
          children: [
            _TeamHeader(team: team),
            _TeamTabs(
              selectedIndex: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _OverviewTab(request: _request),
                  _ContentsTab(teamId: widget.teamId),
                  _PlayersTab(request: _request),
                  _StatsTab(request: _request),
                  _MatchesTab(teamId: widget.teamId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamTabs extends StatelessWidget {
  const _TeamTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = <(String, String, IconData)>[
    ('team_tab_overview', '概览', Icons.info_outline),
    ('team_tab_contents', '动态', Icons.dynamic_feed_outlined),
    ('team_tab_players', '球员', Icons.groups_outlined),
    ('team_tab_stats', '数据', Icons.bar_chart_outlined),
    ('team_tab_matches', '赛程', Icons.calendar_month_outlined),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: InkWell(
                key: ValueKey(_tabs[i].$1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        color: i == selectedIndex
                            ? AppColors.brand
                            : AppColors.inkMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tabs[i].$2,
                        style: TextStyle(
                          color: i == selectedIndex
                              ? AppColors.brand
                              : AppColors.inkMuted,
                          fontWeight: i == selectedIndex
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _TeamHeader extends ConsumerStatefulWidget {
  const _TeamHeader({required this.team});
  final TeamDetail team;
  @override
  ConsumerState<_TeamHeader> createState() => _TeamHeaderState();
}

class _TeamHeaderState extends ConsumerState<_TeamHeader> {
  late bool _followed = widget.team.followed;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy || widget.team.id <= 0) return;
    setState(() => _busy = true);
    try {
      final value = await ref
          .read(userCenterRepositoryProvider)
          .toggleEntity('TEAM', widget.team.id);
      if (mounted) setState(() => _followed = value);
    } on AppNetworkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(footballErrorMessage(error, target: '关注'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
        ),
      ),
      child: Row(
        children: [
          AppTeamLogo(
            identity: 'team:${widget.team.id}',
            name: widget.team.name,
            imageUrl: resolveMediaUrl(config, widget.team.logoUrl),
            size: 72,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.team.nameEn != null)
                  Text(
                    widget.team.nameEn!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                Text(
                  '${widget.team.followerCount} 人关注',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (widget.team.city != null || widget.team.country != null)
                  Text(
                    [widget.team.city, widget.team.country]
                        .whereType<String>()
                        .where((value) => value.trim().isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
          FilledButton.tonal(
            key: const ValueKey('team_follow'),
            onPressed: _busy || widget.team.id <= 0 ? null : _toggle,
            child: Text(_followed ? '已关注' : '关注'),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.request});
  final TeamDetailContext request;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teamOverviewProvider(request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载总览',
          message: '正在读取当前赛季信息…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球队总览',
          error: error,
          onRetry: () => ref.invalidate(teamOverviewProvider(request)),
        ),
        data: (overview) => SingleChildScrollView(
          key: const PageStorageKey('team_overview'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      DetailFact(
                        label: '赛事',
                        value: overview.leagueName ?? '暂无',
                      ),
                      DetailFact(
                        label: '赛季',
                        value: overview.seasonName ?? '暂无',
                      ),
                      DetailFact(label: '城市', value: overview.city ?? '暂无'),
                      DetailFact(label: '主场', value: overview.stadium ?? '暂无'),
                      DetailFact(
                        label: '成立年份',
                        value: overview.foundedYear?.toString() ?? '暂无',
                      ),
                      if (overview.standing case final standing?) ...[
                        DetailFact(
                          label: '当前排名',
                          value: standing.rank == null
                              ? '暂无'
                              : '第 ${standing.rank} 名',
                        ),
                        DetailFact(label: '场次', value: _value(standing.played)),
                        DetailFact(
                          label: '战绩',
                          value:
                              '${_value(standing.won)}胜 ${_value(standing.drawn)}平 ${_value(standing.lost)}负',
                        ),
                        DetailFact(
                          label: '进失球',
                          value:
                              '${_value(standing.goalsFor)} / ${_value(standing.goalsAgainst)}',
                        ),
                        DetailFact(
                          label: '净胜球',
                          value: _value(standing.goalDifference),
                        ),
                        DetailFact(
                          label: '积分',
                          value: standing.points?.toString() ?? '暂无',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (overview.description != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(overview.description!),
              ],
              if (overview.nextMatch case final match?) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('下一场比赛', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                ScheduleMatchCard(match: match),
              ],
              if (overview.recentMatches.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('最近比赛', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final match in sortMatchesForDisplay(
                  overview.recentMatches,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ScheduleMatchCard(match: match),
                  ),
              ],
              if (overview.recentContents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('最新动态', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final content in overview.recentContents)
                  _ContentTile(content: content),
              ],
              if (overview.topScorers.isNotEmpty ||
                  overview.topAssists.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('队内榜单', style: Theme.of(context).textTheme.titleLarge),
                if (overview.topScorers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '射手榜',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final player in overview.topScorers)
                    _RosterTile(player: player, metric: '进球'),
                ],
                if (overview.topAssists.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '助攻榜',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final player in overview.topAssists)
                    _RosterTile(player: player, metric: '助攻'),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('球队荣誉', style: Theme.of(context).textTheme.titleLarge),
              _Honors(teamId: request.teamId),
            ],
          ),
        ),
      );
}

class _Honors extends ConsumerWidget {
  const _Honors({required this.teamId});
  final int teamId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teamHonorsProvider(teamId))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(teamHonorsProvider(teamId)),
            child: const Text('荣誉加载失败，点击重试'),
          ),
        ),
        data: (honors) => honors.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  '暂无球队荣誉',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              )
            : Column(
                children: [
                  for (final honor in honors)
                    ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(honor.name),
                      subtitle: Text(
                        honor.winningYears.isEmpty
                            ? honor.rawType ?? '荣誉'
                            : honor.winningYears.join('、'),
                      ),
                      trailing: Text(
                        '${honor.titleCount ?? honor.winningYears.length} 次',
                      ),
                    ),
                ],
              ),
      );
}

class _PlayersTab extends ConsumerStatefulWidget {
  const _PlayersTab({required this.request});
  final TeamDetailContext request;
  @override
  ConsumerState<_PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends ConsumerState<_PlayersTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(teamPlayersControllerProvider(widget.request)).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(teamPlayersControllerProvider(widget.request));
    final state = controller.state;
    String? previous;
    final children = <Widget>[];
    for (final player in _sortPlayers(state.records)) {
      final position = _positionLabel(player.position);
      if (position != previous) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              position,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
        previous = position;
      }
      children.add(_RosterTile(player: player));
    }
    return _pagedBody(
      state: state,
      title: '球员',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      children: children,
    );
  }
}

class _RosterTile extends ConsumerWidget {
  const _RosterTile({required this.player, this.metric});
  final TeamRosterPlayer player;
  final String? metric;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('team_player_${player.id}'),
    onTap: player.id > 0 ? () => context.push('/players/${player.id}') : null,
    leading: AppTeamLogo(
      identity: 'player:${player.id}',
      name: player.name,
      imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), player.avatarUrl),
      size: 42,
    ),
    title: Text(
      '${player.shirtNumber == null ? '' : '${player.shirtNumber} · '}${player.name}',
    ),
    subtitle: Text(
      [
        _positionLabel(player.position),
        _roleLabel(player.squadRole),
        if (player.captain) '队长',
        if (player.loan)
          player.loanFromTeamName == null
              ? '租借'
              : '租借自 ${player.loanFromTeamName}',
        if (player.appearances != null) '出场 ${player.appearances}',
        if (player.goals != null) '进球 ${player.goals}',
        if (player.assists != null) '助攻 ${player.assists}',
      ].join(' · '),
    ),
    trailing: metric == '进球' && player.goals != null
        ? Text('${player.goals} 球')
        : metric == '助攻' && player.assists != null
        ? Text('${player.assists} 次')
        : player.rating == null
        ? null
        : Text(_finiteDouble(player.rating)),
  );
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.request});
  final TeamDetailContext request;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teamStatsProvider(request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球队数据',
          message: '正在读取赛季统计…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球队数据',
          error: error,
          onRetry: () => ref.invalidate(teamStatsProvider(request)),
        ),
        data: (stats) => stats.hasData
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const Text(
                    '赛季数据',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatGrid(stats: stats),
                ],
              )
            : const AppStateView(
                kind: AppStateKind.empty,
                title: '暂无球队数据',
                message: '当前赛季或阶段没有可展示的统计。',
              ),
      );
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final TeamStats stats;
  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      ('当前排名', stats.standingRank == null ? '—' : '第 ${stats.standingRank} 名'),
      ('积分', _value(stats.points)),
      ('比赛', _value(stats.played)),
      ('进球', _value(stats.goalsFor)),
      ('失球', _value(stats.goalsAgainst)),
      ('净胜球', _value(stats.goalDifference)),
      ('助攻', _value(stats.assists)),
      ('射门', _value(stats.shots)),
      ('射正', _value(stats.shotsOnTarget)),
      ('射正率', _percent(stats.shotAccuracy)),
      ('角球', _value(stats.corners)),
      ('犯规', _value(stats.fouls)),
      ('黄牌', _value(stats.yellowCards)),
      ('红牌', _value(stats.redCards)),
      ('零封', _value(stats.cleanSheets)),
      ('平均评分', _finiteDouble(stats.averageRating, digits: 2)),
    ];
    final width =
        (MediaQuery.sizeOf(context).width - AppSpacing.lg * 2 - AppSpacing.sm) /
        2;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in values)
          SizedBox(
            width: width,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(item.$1),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab({required this.teamId});
  final int teamId;
  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(teamMatchesControllerProvider(widget.teamId)).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(teamMatchesControllerProvider(widget.teamId));
    final state = controller.state;
    return _pagedBody(
      state: state,
      title: '赛程',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      children: _matchChildren(state.records),
    );
  }
}

class _ContentsTab extends ConsumerStatefulWidget {
  const _ContentsTab({required this.teamId});
  final int teamId;
  @override
  ConsumerState<_ContentsTab> createState() => _ContentsTabState();
}

class _ContentsTabState extends ConsumerState<_ContentsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(teamContentsControllerProvider(widget.teamId)).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(teamContentsControllerProvider(widget.teamId));
    final state = controller.state;
    return _pagedBody(
      state: state,
      title: '动态',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      children: _contentChildren(context, state.records),
    );
  }
}

class _ContentTile extends ConsumerWidget {
  const _ContentTile({required this.content});
  final TeamContentSummary content;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      0,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('team_content_${content.id}'),
      onTap: content.id > 0
          ? () => context.push('/contents/${content.id}')
          : null,
      child: Row(
        children: [
          if (content.coverUrl?.trim().isNotEmpty == true)
            SizedBox(
              width: 104,
              child: AppContentImage(
                imageUrl: resolveMediaUrl(
                  ref.watch(appConfigProvider),
                  content.coverUrl,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (content.summary?.trim().isNotEmpty == true)
                    Text(
                      content.summary!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  Text(
                    '${_contentTypeLabel(content.rawType)} · ${content.likeCount} 赞 · ${content.commentCount} 评论',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  if (content.publishTime != null)
                    Text(
                      footballDate(content.publishTime),
                      style: const TextStyle(color: AppColors.inkMuted),
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

Widget _pagedBody<T>({
  required TeamPagedState<T> state,
  required String title,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
  Future<void> Function()? onRefresh,
  required List<Widget> children,
}) => switch (state.status) {
  TeamPagedStatus.loading => AppStateView(
    kind: AppStateKind.loading,
    title: '正在加载$title',
    message: '正在读取真实数据…',
  ),
  TeamPagedStatus.failure => AppStateView(
    kind: AppStateKind.error,
    title: '$title加载失败',
    message: state.message ?? '请稍后重试。',
    onRetry: onRetry,
  ),
  TeamPagedStatus.empty => AppStateView(
    kind: AppStateKind.empty,
    title: '暂无$title',
    message: '当前没有可展示的数据。',
    onRetry: onRetry,
  ),
  TeamPagedStatus.ready => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.extentAfter < 320) onLoadMore();
      return false;
    },
    child: RefreshIndicator(
      key: ValueKey('team_refresh_$title'),
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        key: PageStorageKey('team_$title'),
        children: [
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Material(
                color: AppColors.error.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.message!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(onPressed: onRefresh, child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ),
          ...children,
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : state.appendMessage != null
                  ? TextButton(
                      onPressed: onLoadMore,
                      child: Text('${state.appendMessage} 点击重试'),
                    )
                  : Text(
                      state.hasMore ? '继续上滑加载' : '已经到底了',
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
            ),
          ),
        ],
      ),
    ),
  ),
};

String _positionLabel(String? raw) => switch (raw) {
  'GOALKEEPER' => '门将',
  'DEFENDER' => '后卫',
  'MIDFIELDER' => '中场',
  'FORWARD' => '前锋',
  null => '位置未定',
  _ => raw.trim().isEmpty ? '位置未定' : '其他位置',
};

String _roleLabel(String? raw) => switch (raw) {
  'FIRST_TEAM' => '一线队',
  'ROTATION' => '轮换',
  'RESERVE' => '替补',
  'YOUTH' => '青年队',
  null => '角色未定',
  _ => raw.trim().isEmpty ? '角色未定' : '其他角色',
};

String _value(Object? value) =>
    value is double && !value.isFinite ? '—' : value?.toString() ?? '—';

String _contentTypeLabel(String raw) => switch (raw.trim().toUpperCase()) {
  'ARTICLE' => '文章',
  'POST' => '帖子',
  _ => '动态',
};

String _finiteDouble(double? value, {int digits = 1}) =>
    value == null || !value.isFinite ? '—' : value.toStringAsFixed(digits);

String _percent(double? value) {
  if (value == null || !value.isFinite) return '—';
  return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
}

List<Widget> _matchChildren(Iterable<FootballMatch> values) {
  final children = <Widget>[];
  DateTime? lastDate;
  var hasDateGroup = false;
  for (final match in sortMatchesForDisplay(values)) {
    final date = match.matchTime == null
        ? null
        : DateTime(
            match.matchTime!.year,
            match.matchTime!.month,
            match.matchTime!.day,
          );
    if (!hasDateGroup || date != lastDate) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            date == null ? '日期待定' : footballDate(date),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
      lastDate = date;
      hasDateGroup = true;
    }
    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: ScheduleMatchCard(match: match),
      ),
    );
  }
  return children;
}

List<TeamRosterPlayer> _sortPlayers(Iterable<TeamRosterPlayer> values) {
  const order = {'门将': 0, '后卫': 1, '中场': 2, '前锋': 3, '位置未定': 4, '其他位置': 5};
  final indexed = values.indexed.toList(growable: false);
  indexed.sort((a, b) {
    final compare = (order[_positionLabel(a.$2.position)] ?? 99).compareTo(
      order[_positionLabel(b.$2.position)] ?? 99,
    );
    return compare == 0 ? a.$1.compareTo(b.$1) : compare;
  });
  return List.unmodifiable(indexed.map((entry) => entry.$2));
}

List<Widget> _contentChildren(
  BuildContext context,
  List<TeamContentSummary> values,
) {
  if (MediaQuery.sizeOf(context).width < 380) {
    return [for (final value in values) _ContentTile(content: value)];
  }
  final left = <Widget>[];
  final right = <Widget>[];
  for (final entry in values.indexed) {
    (entry.$1.isEven ? left : right).add(_ContentTile(content: entry.$2));
  }
  return [
    Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(children: right)),
        ],
      ),
    ),
  ];
}

class FootballDetailError extends StatelessWidget {
  const FootballDetailError({
    required this.target,
    required this.error,
    required this.onRetry,
    super.key,
  });
  final String target;
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final message = error is AppNetworkException
        ? footballErrorMessage(error as AppNetworkException, target: target)
        : '$target加载失败，请稍后重试。';
    final missing =
        error is BusinessException &&
        (error as BusinessException).code == 40401;
    return AppStateView(
      kind: missing ? AppStateKind.empty : AppStateKind.error,
      title: missing ? '$target不存在' : '$target加载失败',
      message: message,
      onRetry: missing ? null : onRetry,
    );
  }
}
