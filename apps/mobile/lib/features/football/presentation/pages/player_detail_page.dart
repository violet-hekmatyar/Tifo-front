import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../../domain/player_detail_models.dart';
import '../../domain/team_detail_models.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/football_rankings_controller.dart';
import '../controllers/player_detail_controllers.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';
import 'team_detail_page.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  const PlayerDetailPage({required this.playerId, super.key});
  final int playerId;
  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  int _tab = 0;
  late final PlayerDetailContext _request;

  @override
  void initState() {
    super.initState();
    final ranking = ref.read(footballRankingsControllerProvider).state;
    _request = (
      playerId: widget.playerId,
      leagueId: ranking.selectedLeagueId,
      seasonId: ranking.selectedSeasonId,
      stageId: ranking.selectedStageId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(playerDetailProvider(widget.playerId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/app/data'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('球员详情'),
      ),
      body: detail.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员',
          message: '正在读取球员基础资料…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员',
          error: error,
          onRetry: () => ref.invalidate(playerDetailProvider(widget.playerId)),
        ),
        data: (player) => Column(
          children: [
            _PlayerHeader(player: player),
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
                  icon: Icon(Icons.bar_chart_outlined),
                  label: '数据',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: '比赛',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  label: '生涯',
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _OverviewTab(request: _request),
                  _ContentsTab(playerId: widget.playerId),
                  _StatsTab(request: _request),
                  _MatchesTab(playerId: widget.playerId),
                  _CareerTab(playerId: widget.playerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  const _PlayerHeader({required this.player});
  final PlayerDetail player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.brandDark, AppColors.brand]),
    ),
    child: Row(
      children: [
        AppPlayerAvatar(
          identity: 'player:${player.id}',
          name: player.name,
          imageUrl: resolveMediaUrl(
            ref.watch(appConfigProvider),
            player.avatarUrl,
          ),
          size: 76,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (player.nameEn != null)
                Text(
                  player.nameEn!,
                  style: const TextStyle(color: Colors.white70),
                ),
              Text(
                '${player.position ?? '位置暂无'} · ${player.retired ? '已退役' : '现役'} · ${player.followed ? '已关注' : '${player.followerCount} 人关注'}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.request});
  final PlayerDetailContext request;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(playerOverviewV1Provider(request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员总览',
          message: '正在读取俱乐部和国家队信息…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员总览',
          error: error,
          onRetry: () => ref.invalidate(playerOverviewV1Provider(request)),
        ),
        data: (player) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    DetailFact(label: '位置', value: player.position ?? '暂无'),
                    DetailFact(label: '国籍', value: player.nationality ?? '暂无'),
                    DetailFact(
                      label: '年龄',
                      value: player.age?.toString() ?? '暂无',
                    ),
                    DetailFact(
                      label: '身高',
                      value: player.height == null
                          ? '暂无'
                          : '${player.height} cm',
                    ),
                    DetailFact(
                      label: '体重',
                      value: player.weight == null
                          ? '暂无'
                          : '${player.weight} kg',
                    ),
                    DetailFact(
                      label: '惯用脚',
                      value: player.preferredFoot ?? '暂无',
                    ),
                    DetailFact(
                      label: '号码',
                      value: player.shirtNumber?.toString() ?? '暂无',
                    ),
                    DetailFact(
                      label: '状态',
                      value: player.retired ? '已退役' : '现役',
                    ),
                  ],
                ),
              ),
            ),
            if (player.club case final team?) ...[
              const SizedBox(height: AppSpacing.lg),
              _TeamLinkCard(title: '当前俱乐部', team: team),
            ],
            const SizedBox(height: AppSpacing.md),
            if (player.nationalTeam case final team?)
              _TeamLinkCard(title: '国家队', team: team)
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('国家队'),
                  subtitle: Text('暂无国家队信息'),
                ),
              ),
          ],
        ),
      );
}

class _TeamLinkCard extends ConsumerWidget {
  const _TeamLinkCard({required this.title, required this.team});
  final String title;
  final PlayerTeamLink team;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      key: ValueKey('player_team_${team.id}'),
      onTap: () => context.push('/teams/${team.id}'),
      leading: AppTeamLogo(
        identity: 'team:${team.id}',
        name: team.name,
        imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), team.logoUrl),
        size: 44,
      ),
      title: Text(title),
      subtitle: Text(
        [
          team.name,
          if (team.shirtNumber != null) '${team.shirtNumber} 号',
          if (team.rawType != null) team.rawType!,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.request});
  final PlayerDetailContext request;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(playerStatsV1Provider(request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员数据',
          message: '正在读取赛季统计…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员数据',
          error: error,
          onRetry: () => ref.invalidate(playerStatsV1Provider(request)),
        ),
        data: (stats) => stats.isEmpty
            ? const AppStateView(
                kind: AppStateKind.empty,
                title: '暂无球员数据',
                message: '当前赛季或阶段没有可展示的统计。',
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [for (final value in stats) _StatsCard(stats: value)],
              ),
      );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final PlayerSeasonStats stats;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              stats.leagueName,
              stats.seasonName,
              stats.teamName,
            ].whereType<String>().join(' · '),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _metric('出场', stats.appearances),
              _metric('首发', stats.starts),
              _metric('分钟', stats.minutes),
              _metric('进球', stats.goals),
              _metric('助攻', stats.assists),
              _metric('射门', stats.shots),
              _metric('射正', stats.shotsOnTarget),
              _metric('扑救', stats.saves),
              _metric('评分', stats.rating?.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _metric(String label, Object? value) => SizedBox(
  width: 64,
  child: Column(
    children: [
      Text(
        value?.toString() ?? '—',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      Text(label, style: const TextStyle(color: AppColors.inkMuted)),
    ],
  ),
);

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab({required this.playerId});
  final int playerId;
  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(playerMatchesV1ControllerProvider(widget.playerId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      playerMatchesV1ControllerProvider(widget.playerId),
    );
    return _pagedBody(
      state: controller.state,
      title: '比赛',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      children: [
        for (final match in controller.state.records)
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
  const _ContentsTab({required this.playerId});
  final int playerId;
  @override
  ConsumerState<_ContentsTab> createState() => _ContentsTabState();
}

class _ContentsTabState extends ConsumerState<_ContentsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(playerContentsV1ControllerProvider(widget.playerId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      playerContentsV1ControllerProvider(widget.playerId),
    );
    return _pagedBody(
      state: controller.state,
      title: '动态',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      children: [
        for (final content in controller.state.records)
          _ContentCard(content: content),
      ],
    );
  }
}

class _ContentCard extends ConsumerWidget {
  const _ContentCard({required this.content});
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
      key: ValueKey('player_content_${content.id}'),
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

class _CareerTab extends ConsumerWidget {
  const _CareerTab({required this.playerId});
  final int playerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(playerCareerV1Provider(playerId));
    final teams = ref.watch(playerTeamsV1Provider(playerId));
    if (career.isLoading || teams.isLoading) {
      return const AppStateView(
        kind: AppStateKind.loading,
        title: '正在加载球员生涯',
        message: '正在读取历史效力球队…',
      );
    }
    if (career.hasError || teams.hasError) {
      return AppStateView(
        kind: AppStateKind.error,
        title: '球员生涯加载失败',
        message: '请稍后重试。',
        onRetry: () {
          ref.invalidate(playerCareerV1Provider(playerId));
          ref.invalidate(playerTeamsV1Provider(playerId));
        },
      );
    }
    final value = career.value!;
    final history = teams.value!;
    if (!value.hasData && history.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: '暂无生涯数据',
        message: '当前没有可展示的职业生涯记录。',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _metric('出场', value.totalAppearances),
                _metric('首发', value.totalStarts),
                _metric('进球', value.totalGoals),
                _metric('助攻', value.totalAssists),
                _metric('球队', value.teamCount),
                _metric('赛季', value.seasonCount),
                _metric('评分', value.averageRating?.toStringAsFixed(2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('效力球队', style: Theme.of(context).textTheme.titleLarge),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              '暂无历史效力球队',
              style: TextStyle(color: AppColors.inkMuted),
            ),
          )
        else
          for (final item in history) _HistoryTile(history: item),
      ],
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.history});
  final PlayerTeamHistory history;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('career_team_${history.teamId}_${history.seasonId}'),
    onTap: () => context.push('/teams/${history.teamId}'),
    leading: AppTeamLogo(
      identity: 'team:${history.teamId}',
      name: history.teamName,
      imageUrl: resolveMediaUrl(
        ref.watch(appConfigProvider),
        history.teamLogoUrl,
      ),
      size: 42,
    ),
    title: Text(history.teamName),
    subtitle: Text(
      [
        history.seasonName,
        history.position,
        if (history.current) '当前效力',
        if (history.loan) '租借',
      ].whereType<String>().join(' · '),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
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
      key: PageStorageKey('player_$title'),
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
