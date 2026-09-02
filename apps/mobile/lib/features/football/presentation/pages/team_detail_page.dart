import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../user_center/data/user_center_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/team_detail_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/football_rankings_controller.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';

class TeamDetailPage extends ConsumerStatefulWidget {
  const TeamDetailPage({required this.teamId, super.key});
  final int teamId;
  @override
  ConsumerState<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends ConsumerState<TeamDetailPage> {
  int _tab = 0;
  late final TeamDetailContext _request;

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
            NavigationBar(
              height: 64,
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dynamic_feed_outlined),
                  label: '动态',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: '球员',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: '数据',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: '赛程',
                ),
              ],
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
    if (_busy) return;
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
              ],
            ),
          ),
          FilledButton.tonal(
            key: const ValueKey('team_follow'),
            onPressed: _busy ? null : _toggle,
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
        data: (overview) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    DetailFact(label: '赛事', value: overview.leagueName ?? '暂无'),
                    DetailFact(label: '赛季', value: overview.seasonName ?? '暂无'),
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
            if (overview.topScorers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('队内射手', style: Theme.of(context).textTheme.titleLarge),
              for (final player in overview.topScorers)
                _RosterTile(player: player),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('球队荣誉', style: Theme.of(context).textTheme.titleLarge),
            _Honors(teamId: request.teamId),
          ],
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
    for (final player in state.records) {
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
      children: children,
    );
  }
}

class _RosterTile extends ConsumerWidget {
  const _RosterTile({required this.player});
  final TeamRosterPlayer player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('team_player_${player.id}'),
    onTap: () => context.push('/players/${player.id}'),
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
        if (player.loan) '租借',
      ].join(' · '),
    ),
    trailing: player.rating == null
        ? null
        : Text(player.rating!.toStringAsFixed(1)),
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
                children: [_StatGrid(stats: stats)],
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
      ('助攻', _value(stats.assists)),
      ('射门', _value(stats.shots)),
      ('射正', _value(stats.shotsOnTarget)),
      ('射正率', stats.shotAccuracy == null ? '—' : '${stats.shotAccuracy}%'),
      ('角球', _value(stats.corners)),
      ('犯规', _value(stats.fouls)),
      ('黄牌', _value(stats.yellowCards)),
      ('红牌', _value(stats.redCards)),
      ('零封', _value(stats.cleanSheets)),
      ('平均评分', stats.averageRating?.toStringAsFixed(2) ?? '—'),
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
      children: [
        for (final match in state.records)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: ScheduleMatchCard(match: match),
          ),
      ],
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
      children: [
        for (final content in state.records) _ContentTile(content: content),
      ],
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
      onTap: () => context.push('/contents/${content.id}'),
      child: Row(
        children: [
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
                  Text(
                    '${content.rawType} · ${content.likeCount} 赞 · ${content.commentCount} 评论',
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
    child: ListView(
      key: PageStorageKey('team_$title'),
      children: [
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
};

String _positionLabel(String? raw) => switch (raw) {
  'GOALKEEPER' => '门将',
  'DEFENDER' => '后卫',
  'MIDFIELDER' => '中场',
  'FORWARD' => '前锋',
  null => '位置未定',
  _ => raw,
};

String _roleLabel(String? raw) => switch (raw) {
  'FIRST_TEAM' => '一线队',
  'ROTATION' => '轮换',
  'RESERVE' => '替补',
  'YOUTH' => '青年队',
  null => '角色未定',
  _ => raw,
};

String _value(Object? value) => value?.toString() ?? '—';

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
