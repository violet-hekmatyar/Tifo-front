import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../../user_center/data/user_center_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/match_display_sort.dart';
import '../../domain/player_detail_models.dart';
import '../../domain/team_detail_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/football_rankings_controller.dart';
import '../controllers/player_detail_controllers.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';
import 'team_detail_page.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  const PlayerDetailPage({
    required this.playerId,
    this.recommendationSource,
    super.key,
  });
  final int playerId;
  final RecommendationSourceContext? recommendationSource;

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  int _tab = 0;
  late final PlayerDetailContext _request;
  bool _detailReported = false;

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
            _PlayerTabs(
              selectedIndex: _tab,
              onChanged: (value) => setState(() => _tab = value),
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

class _PlayerTabs extends StatelessWidget {
  const _PlayerTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = <(String, String, IconData)>[
    ('player_tab_overview', '概览', Icons.info_outline),
    ('player_tab_contents', '动态', Icons.dynamic_feed_outlined),
    ('player_tab_stats', '数据', Icons.bar_chart_outlined),
    ('player_tab_matches', '比赛', Icons.calendar_month_outlined),
    ('player_tab_career', '生涯', Icons.history_rounded),
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

class _PlayerHeader extends ConsumerStatefulWidget {
  const _PlayerHeader({required this.player});
  final PlayerDetail player;

  @override
  ConsumerState<_PlayerHeader> createState() => _PlayerHeaderState();
}

class _PlayerHeaderState extends ConsumerState<_PlayerHeader> {
  late bool _followed = widget.player.followed;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy || widget.player.id <= 0) return;
    setState(() => _busy = true);
    try {
      final followed = await ref
          .read(userCenterRepositoryProvider)
          .toggleEntity('PLAYER', widget.player.id);
      if (mounted) setState(() => _followed = followed);
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.brandDark, AppColors.brand]),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPlayerAvatar(
          identity: 'player:${widget.player.id}',
          name: widget.player.name,
          imageUrl: resolveMediaUrl(
            ref.watch(appConfigProvider),
            widget.player.avatarUrl,
          ),
          size: 72,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.player.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.player.nameEn?.trim().isNotEmpty == true)
                Text(
                  widget.player.nameEn!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              Text(
                '${_positionLabel(widget.player.position)} · ${widget.player.retired ? '已退役' : '现役'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              if (widget.player.team case final team?)
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonal(
          key: const ValueKey('player_follow'),
          onPressed: _busy || widget.player.id <= 0 ? null : _toggle,
          child: Text(_followed ? '已关注' : '关注'),
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
        data: (player) => SingleChildScrollView(
          key: const PageStorageKey('player_overview'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonalCard(player: player),
              if (player.club case final club?) ...[
                const SizedBox(height: AppSpacing.lg),
                _TeamLinkCard(title: '当前俱乐部', team: club),
              ],
              const SizedBox(height: AppSpacing.md),
              if (player.nationalTeam case final nationalTeam?)
                _TeamLinkCard(title: '国家队', team: nationalTeam)
              else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.flag_outlined),
                    title: Text('国家队'),
                    subtitle: Text('暂无国家队信息'),
                  ),
                ),
              if (player.seasonStats.any((value) => value.hasData)) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  '当前赛季数据',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final stats in player.seasonStats)
                  if (stats.hasData) _SeasonSummaryCard(stats: stats),
              ],
              if (player.recentMatches.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('最近比赛', style: Theme.of(context).textTheme.titleLarge),
                ..._matchChildren(player.recentMatches),
              ],
              if (player.recentContents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('最近动态', style: Theme.of(context).textTheme.titleLarge),
                for (final content in player.recentContents)
                  _ContentCard(content: content),
              ],
            ],
          ),
        ),
      );
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({required this.player});
  final PlayerOverview player;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人资料', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _fact('位置', _positionLabel(player.position)),
              _fact('国籍', player.nationality),
              _fact('生日', _date(player.birthDate)),
              _fact('年龄', _number(player.age)),
              _fact('身高', _withUnit(player.height, 'cm')),
              _fact('体重', _withUnit(player.weight, 'kg')),
              _fact('惯用脚', player.preferredFoot),
              _fact('号码', _number(player.shirtNumber)),
              _fact('身份', player.retired ? '已退役' : '现役'),
              if (player.captain) _fact('队内身份', '队长'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _fact(String label, String? value) => SizedBox(
  width: 108,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value?.trim().isNotEmpty == true ? value! : '暂无'),
      Text(label, style: const TextStyle(color: AppColors.inkMuted)),
    ],
  ),
);

class _TeamLinkCard extends ConsumerWidget {
  const _TeamLinkCard({required this.title, required this.team});
  final String title;
  final PlayerTeamLink team;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      key: ValueKey('player_team_${team.id}'),
      onTap: team.id > 0 ? () => context.push('/teams/${team.id}') : null,
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
          if (team.rawType?.trim().isNotEmpty == true) team.rawType!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: team.id > 0 ? const Icon(Icons.chevron_right_rounded) : null,
    ),
  );
}

class _SeasonSummaryCard extends StatelessWidget {
  const _SeasonSummaryCard({required this.stats});
  final PlayerSeasonStats stats;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: AppSpacing.sm),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statsContext(stats),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: _statMetrics(stats),
          ),
        ],
      ),
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
        data: (stats) {
          final visible = stats.where((value) => value.hasData).toList();
          return visible.isEmpty
              ? const AppStateView(
                  kind: AppStateKind.empty,
                  title: '暂无球员数据',
                  message: '当前赛季或阶段没有可展示的统计。',
                )
              : ListView(
                  key: const PageStorageKey('player_stats'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    for (final value in visible) _StatsCard(stats: value),
                  ],
                );
        },
      );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final PlayerSeasonStats stats;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statsContext(stats),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: _statMetrics(stats),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _statMetrics(PlayerSeasonStats stats) => [
  if (stats.appearances != null) _metric('出场', stats.appearances),
  if (stats.starts != null) _metric('首发', stats.starts),
  if (stats.minutes != null) _metric('分钟', stats.minutes),
  if (stats.goals != null) _metric('进球', stats.goals),
  if (stats.assists != null) _metric('助攻', stats.assists),
  if (stats.yellowCards != null) _metric('黄牌', stats.yellowCards),
  if (stats.redCards != null) _metric('红牌', stats.redCards),
  if (stats.shots != null) _metric('射门', stats.shots),
  if (stats.shotsOnTarget != null) _metric('射正', stats.shotsOnTarget),
  if (stats.shotAccuracy != null) _metric('射正率', _percent(stats.shotAccuracy)),
  if (stats.rating != null)
    _metric('评分', _finiteDouble(stats.rating, digits: 2)),
  if (stats.saves != null) _metric('扑救', stats.saves),
];

Widget _metric(String label, Object? value) => SizedBox(
  width: 76,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _display(value),
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
      onRefresh: controller.refresh,
      children: _matchChildren(controller.state.records),
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
      onRefresh: controller.refresh,
      children: _contentChildren(context, controller.state.records),
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
      onTap: content.id > 0
          ? () => context.push('/contents/${content.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.coverUrl?.trim().isNotEmpty == true)
            SizedBox(
              width: double.infinity,
              child: AppContentImage(
                imageUrl: resolveMediaUrl(
                  ref.watch(appConfigProvider),
                  content.coverUrl,
                ),
              ),
            ),
          Padding(
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                Text(
                  '${_contentTypeLabel(content.rawType)} · ${content.likeCount} 赞 · ${content.commentCount} 评论',
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                if (content.publishTime != null)
                  Text(
                    _date(content.publishTime),
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CareerTab extends ConsumerStatefulWidget {
  const _CareerTab({required this.playerId});
  final int playerId;

  @override
  ConsumerState<_CareerTab> createState() => _CareerTabState();
}

class _CareerTabState extends ConsumerState<_CareerTab> {
  var _view = _CareerView.team;

  @override
  Widget build(BuildContext context) {
    final career = ref.watch(playerCareerV1Provider(widget.playerId));
    final teams = ref.watch(playerTeamsV1Provider(widget.playerId));
    return ListView(
      key: const PageStorageKey('player_career'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _AsyncCareerSection(
          value: career,
          title: '职业生涯总计',
          onRetry: () =>
              ref.invalidate(playerCareerV1Provider(widget.playerId)),
          builder: (value) => [
            if (value.hasData) _CareerTotals(career: value),
            if (value.byTeam.isNotEmpty || value.bySeason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _CareerToggle(
                view: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
              const SizedBox(height: AppSpacing.md),
              ...(_view == _CareerView.team ? value.byTeam : value.bySeason)
                  .map((group) => _CareerGroupTile(group: group)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _AsyncTeamsSection(
          value: teams,
          onRetry: () => ref.invalidate(playerTeamsV1Provider(widget.playerId)),
        ),
      ],
    );
  }
}

enum _CareerView { team, season }

class _AsyncCareerSection extends StatelessWidget {
  const _AsyncCareerSection({
    required this.value,
    required this.title,
    required this.onRetry,
    required this.builder,
  });
  final AsyncValue<PlayerCareer> value;
  final String title;
  final VoidCallback onRetry;
  final List<Widget> Function(PlayerCareer value) builder;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => _subsectionState(
      title,
      key: const ValueKey('player_career_state'),
      loading: true,
    ),
    error: (error, _) => _subsectionState(
      title,
      key: const ValueKey('player_career_state'),
      retryKey: const ValueKey('player_career_retry'),
      message: _errorText(error),
      onRetry: onRetry,
    ),
    data: (career) =>
        career.hasData || career.byTeam.isNotEmpty || career.bySeason.isNotEmpty
        ? Column(
            key: const ValueKey('player_career_state'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              ...builder(career),
            ],
          )
        : _subsectionState(
            title,
            key: const ValueKey('player_career_state'),
            message: '暂无生涯总计',
          ),
  );
}

class _AsyncTeamsSection extends StatelessWidget {
  const _AsyncTeamsSection({required this.value, required this.onRetry});
  final AsyncValue<List<PlayerTeamHistory>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      loading: true,
    ),
    error: (error, _) => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      retryKey: const ValueKey('player_teams_retry'),
      message: _errorText(error),
      onRetry: onRetry,
    ),
    data: (history) => Card(
      key: const ValueKey('player_teams_state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: history.isEmpty
            ? const Text('暂无历史效力球队')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '效力球队',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final item in _uniqueHistory(history))
                    _HistoryTile(history: item),
                ],
              ),
      ),
    ),
  );
}

Widget _subsectionState(
  String title, {
  Key? key,
  bool loading = false,
  String? message,
  VoidCallback? onRetry,
  Key? retryKey,
}) => Card(
  key: key,
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: loading
        ? Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              const CircularProgressIndicator(),
            ],
          )
        : Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(message ?? '暂无数据'),
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

class _CareerTotals extends StatelessWidget {
  const _CareerTotals({required this.career});
  final PlayerCareer career;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          if (career.totalAppearances != null)
            _metric('出场', career.totalAppearances),
          if (career.totalStarts != null) _metric('首发', career.totalStarts),
          if (career.totalMinutes != null) _metric('分钟', career.totalMinutes),
          if (career.totalGoals != null) _metric('进球', career.totalGoals),
          if (career.totalAssists != null) _metric('助攻', career.totalAssists),
          if (career.totalYellowCards != null)
            _metric('黄牌', career.totalYellowCards),
          if (career.totalRedCards != null) _metric('红牌', career.totalRedCards),
          if (career.totalShots != null) _metric('射门', career.totalShots),
          if (career.totalShotsOnTarget != null)
            _metric('射正', career.totalShotsOnTarget),
          if (career.totalSaves != null) _metric('扑救', career.totalSaves),
          if (career.averageRating != null)
            _metric('平均评分', _finiteDouble(career.averageRating, digits: 2)),
          if (career.teamCount != null) _metric('球队数', career.teamCount),
          if (career.seasonCount != null) _metric('赛季数', career.seasonCount),
        ],
      ),
    ),
  );
}

class _CareerToggle extends StatelessWidget {
  const _CareerToggle({required this.view, required this.onChanged});
  final _CareerView view;
  final ValueChanged<_CareerView> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<_CareerView>(
    segments: const [
      ButtonSegment(value: _CareerView.team, label: Text('球队')),
      ButtonSegment(value: _CareerView.season, label: Text('赛季')),
    ],
    selected: {view},
    onSelectionChanged: (values) => onChanged(values.first),
  );
}

class _CareerGroupTile extends StatelessWidget {
  const _CareerGroupTile({required this.group});
  final PlayerCareerGroup group;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: AppSpacing.sm),
    child: ListTile(
      title: Text(group.name),
      subtitle: Text(
        [
          if (group.appearances != null) '出场 ${_display(group.appearances)}',
          if (group.starts != null) '首发 ${_display(group.starts)}',
          if (group.minutes != null) '分钟 ${_display(group.minutes)}',
          if (group.goals != null) '进球 ${_display(group.goals)}',
          if (group.assists != null) '助攻 ${_display(group.assists)}',
          if (group.averageRating != null)
            '评分 ${_finiteDouble(group.averageRating, digits: 2)}',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.history});
  final PlayerTeamHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = history.position?.trim();
    final positionIsLoanMarker = position == '租借';
    return ListTile(
      key: ValueKey('career_team_${history.teamId}_${history.seasonId}'),
      onTap: history.teamId > 0
          ? () => context.push('/teams/${history.teamId}')
          : null,
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
          if (history.seasonName?.trim().isNotEmpty == true)
            history.seasonName!,
          if (history.current) '当前效力',
          if (history.loan) '租借',
          if (history.startDate != null || history.endDate != null)
            '${_date(history.startDate)} - ${history.endDate == null ? '现在' : _date(history.endDate)}',
          if (history.shirtNumber != null) '${history.shirtNumber} 号',
          if (position?.isNotEmpty == true && !positionIsLoanMarker) position!,
          if (history.appearances != null) '出场 ${history.appearances}',
          if (history.goals != null) '进球 ${history.goals}',
          if (history.assists != null) '助攻 ${history.assists}',
        ].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

Widget _pagedBody<T>({
  required TeamPagedState<T> state,
  required String title,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
  required Future<void> Function() onRefresh,
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
      key: ValueKey('player_refresh_$title'),
      onRefresh: onRefresh,
      child: ListView(
        key: PageStorageKey('player_$title'),
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

List<Widget> _contentChildren(
  BuildContext context,
  List<TeamContentSummary> values,
) {
  final narrow =
      MediaQuery.sizeOf(context).width < 380 ||
      MediaQuery.textScalerOf(context).scale(1) > 1.2;
  if (narrow) return [for (final value in values) _ContentCard(content: value)];
  final left = <Widget>[];
  final right = <Widget>[];
  for (final entry in values.indexed) {
    (entry.$1.isEven ? left : right).add(_ContentCard(content: entry.$2));
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

List<PlayerTeamHistory> _uniqueHistory(List<PlayerTeamHistory> values) {
  final unique = <String, PlayerTeamHistory>{};
  for (final item in values) {
    unique['${item.teamId}:${item.seasonId}'] = item;
  }
  return unique.values.toList(growable: false);
}

String _statsContext(PlayerSeasonStats stats) {
  final value = [
    stats.leagueName,
    stats.seasonName,
    stats.teamName,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
  return value.isEmpty ? '赛季数据' : value;
}

String _positionLabel(String? raw) => switch (raw?.trim().toUpperCase()) {
  'GK' || 'GOALKEEPER' => '门将',
  'DF' || 'DEFENDER' => '后卫',
  'MF' || 'MIDFIELDER' => '中场',
  'FW' || 'FORWARD' || 'STRIKER' => '前锋',
  null || '' => '位置未定',
  _ => '其他位置',
};

String _contentTypeLabel(String raw) => switch (raw.trim().toUpperCase()) {
  'ARTICLE' => '文章',
  'POST' => '帖子',
  _ => '动态',
};

String _number(num? value) => value == null ? '—' : _display(value);

String _display(Object? value) {
  if (value is num && !value.isFinite) return '—';
  return value?.toString() ?? '—';
}

String _withUnit(num? value, String unit) =>
    value == null ? '—' : '${_display(value)} $unit';

String _date(DateTime? value) => value == null ? '—' : footballDate(value);

String _finiteDouble(double? value, {int digits = 1}) =>
    value == null || !value.isFinite ? '—' : value.toStringAsFixed(digits);

String _percent(double? value) {
  if (value == null || !value.isFinite) return '—';
  return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
}

String _errorText(Object error) => error is AppNetworkException
    ? footballErrorMessage(error, target: '球员生涯')
    : '加载失败，请稍后重试。';
