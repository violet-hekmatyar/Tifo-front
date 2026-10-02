import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../user_center/data/user_center_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user_center/presentation/controllers/user_center_controllers.dart';
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

  static const _tabs = <(String, String)>[
    ('team_tab_overview', '总览'),
    ('team_tab_contents', '帖子'),
    ('team_tab_players', '球员'),
    ('team_tab_stats', '数据'),
    ('team_tab_matches', '赛程'),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xffa3184c)),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: InkWell(
                key: ValueKey(_tabs[i].$1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 11,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            _tabs[i].$2,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          if (_tabs[i].$1 == 'team_tab_contents')
                            const Text(
                              '动态',
                              style: TextStyle(
                                color: Colors.transparent,
                                fontSize: 1,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          color: i == selectedIndex
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
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
  bool _isMainTeam = false;
  bool _busy = false;

  Future<void> _setMainTeam() async {
    if (_busy || widget.team.id <= 0 || _isMainTeam) return;
    final auth = ref.read(authControllerProvider).state;
    if (auth.status != AuthStatus.authenticatedReady) {
      if (mounted) context.go('/login');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(userCenterRepositoryProvider).setMainTeam(widget.team.id);
      ref.invalidate(mySummaryProvider);
      final summary = await ref.read(userCenterRepositoryProvider).summary();
      final confirmed = summary.mainTeam?.id == widget.team.id;
      if (confirmed && mounted) {
        setState(() => _isMainTeam = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已设为主队')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('服务端未确认主队设置，请重试')));
      }
    } on AppNetworkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(footballErrorMessage(error, target: '主队'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider).state;
    final summary = auth.status == AuthStatus.authenticatedReady
        ? ref.watch(mySummaryProvider).value
        : null;
    final mainTeamId = summary?.mainTeam?.id ?? auth.user?.mainTeamId;
    if (mainTeamId == widget.team.id && !_isMainTeam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isMainTeam = true);
      });
    }
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            MediaQuery.paddingOf(context).top + 10,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff78123f), Color(0xffb51e58)],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('team_back'),
                tooltip: '返回',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/app/data'),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
              AppTeamLogo(
                identity: 'team:${widget.team.id}',
                name: widget.team.name,
                imageUrl: resolveMediaUrl(config, widget.team.logoUrl),
                size: 64,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.team.nameEn ?? '球队详情',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (widget.team.city != null)
                      Text(
                        widget.team.city!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              FilledButton(
                key: const ValueKey('team_main'),
                onPressed: _busy || widget.team.id <= 0 ? null : _setMainTeam,
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xffa3184c),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(_isMainTeam ? '已是主队' : '加为主队'),
              ),
            ],
          ),
        ),
        Positioned(
          right: -8,
          bottom: -22,
          child: IgnorePointer(
            child: Opacity(
              opacity: .08,
              child: AppTeamLogo(
                identity: 'team-watermark:${widget.team.id}',
                name: widget.team.name,
                imageUrl: resolveMediaUrl(config, widget.team.logoUrl),
                size: 150,
              ),
            ),
          ),
        ),
      ],
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
        data: (overview) {
          final leaderboards = overview.leaderboards.isNotEmpty
              ? overview.leaderboards
              : [
                  if (overview.topScorers.isNotEmpty)
                    TeamLeaderboard(
                      rankType: 'GOALS',
                      title: '射手榜',
                      players: overview.topScorers,
                    ),
                  if (overview.topAssists.isNotEmpty)
                    TeamLeaderboard(
                      rankType: 'ASSISTS',
                      title: '助攻榜',
                      players: overview.topAssists,
                    ),
                ];
          return SingleChildScrollView(
            key: const PageStorageKey('team_overview'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (overview.nextMatch case final match?)
                  _NextMatchHero(match: match),
                if (overview.competitionStandings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionTitle(title: '赛事排名'),
                  const SizedBox(height: AppSpacing.sm),
                  _CompetitionStandings(
                    standings: overview.competitionStandings,
                  ),
                ],
                if (overview.recentContents.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionTitle(title: '最新资讯'),
                  const SizedBox(height: AppSpacing.sm),
                  _ContentMasonry(
                    contents: overview.recentContents.take(4).toList(),
                    compact: true,
                  ),
                ],
                if (leaderboards.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _OverviewLeaderboards(
                    teamId: request.teamId,
                    leaderboards: leaderboards,
                    seasons: overview.competitionStandings,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(title: '基本信息'),
                _BasicInfo(overview: overview),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(title: '球队荣誉'),
                overview.honors.isNotEmpty
                    ? _HonorList(honors: overview.honors)
                    : _Honors(teamId: request.teamId),
              ],
            ),
          );
        },
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
  );
}

class _NextMatchHero extends StatelessWidget {
  const _NextMatchHero({required this.match});
  final FootballMatch match;
  @override
  Widget build(BuildContext context) =>
      ScheduleMatchCard(match: match, header: '下一场比赛');
}

class _CompetitionStandings extends StatelessWidget {
  const _CompetitionStandings({required this.standings});
  final List<TeamCompetitionStanding> standings;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final entry in standings.indexed) ...[
          if (entry.$1 > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xfff5dbe6),
                  child: Text(
                    '${entry.$2.rank ?? '—'}',
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.$2.leagueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${entry.$2.points ?? '—'} 分',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _BasicInfo extends StatelessWidget {
  const _BasicInfo({required this.overview});
  final TeamOverview overview;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _InfoCell(label: '城市', value: overview.city),
          _InfoCell(label: '主场', value: overview.stadium),
          _InfoCell(label: '成立', value: overview.foundedYear?.toString()),
        ],
      ),
    ),
  );
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value?.trim().isNotEmpty == true ? value! : '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _HonorList extends StatelessWidget {
  const _HonorList({required this.honors});
  final List<TeamHonor> honors;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final honor in honors)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xffc99632),
          ),
          title: Text(
            honor.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            honor.winningYears.isEmpty
                ? honor.rawType ?? '荣誉'
                : honor.winningYears.join('、'),
          ),
          trailing: Text('${honor.titleCount ?? honor.winningYears.length} 次'),
        ),
    ],
  );
}

class _ContentMasonry extends StatelessWidget {
  const _ContentMasonry({required this.contents, this.compact = false});
  final List<TeamContentSummary> contents;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (final item in contents.indexed) {
      (item.$1.isEven ? left : right).add(
        _ContentTile(content: item.$2, compact: compact),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 8),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

class _OverviewLeaderboards extends StatelessWidget {
  const _OverviewLeaderboards({
    required this.teamId,
    required this.leaderboards,
    required this.seasons,
  });
  final int teamId;
  final List<TeamLeaderboard> leaderboards;
  final List<TeamCompetitionStanding> seasons;
  @override
  Widget build(BuildContext context) {
    final values = leaderboards.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '队内榜单'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final leaderboard in values.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: leaderboard.$1 == 0 ? 4 : 0,
                    left: leaderboard.$1 == 1 ? 4 : 0,
                  ),
                  child: _LeaderboardCard(
                    teamId: teamId,
                    leaderboard: leaderboard.$2,
                    leaderboards: leaderboards,
                    seasons: seasons,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LeaderboardCard extends ConsumerWidget {
  const _LeaderboardCard({
    required this.teamId,
    required this.leaderboard,
    required this.leaderboards,
    required this.seasons,
  });
  final int teamId;
  final TeamLeaderboard leaderboard;
  final List<TeamLeaderboard> leaderboards;
  final List<TeamCompetitionStanding> seasons;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    color: const Color(0xffa3184c),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leaderboard.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final player in leaderboard.players.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AppPlayerAvatar(
                    identity: 'player:${player.id}',
                    name: player.name,
                    imageUrl: resolveMediaUrl(
                      ref.watch(appConfigProvider),
                      player.avatarUrl,
                    ),
                    size: 24,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${player.goals ?? player.assists ?? player.appearances ?? player.rating?.toStringAsFixed(1) ?? '—'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showLeaderboard(
                context,
                teamId: teamId,
                leaderboards: leaderboards,
                seasons: seasons,
              ),
              child: const Text('查看全部', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showLeaderboard(
  BuildContext context, {
  required int teamId,
  required List<TeamLeaderboard> leaderboards,
  required List<TeamCompetitionStanding> seasons,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => _LeaderboardAllPage(
      teamId: teamId,
      leaderboards: leaderboards,
      seasons: seasons,
    ),
  ),
);

class _LeaderboardAllPage extends ConsumerStatefulWidget {
  const _LeaderboardAllPage({
    required this.teamId,
    required this.leaderboards,
    required this.seasons,
  });
  final int teamId;
  final List<TeamLeaderboard> leaderboards;
  final List<TeamCompetitionStanding> seasons;
  @override
  ConsumerState<_LeaderboardAllPage> createState() =>
      _LeaderboardAllPageState();
}

class _LeaderboardAllPageState extends ConsumerState<_LeaderboardAllPage> {
  late TeamCompetitionStanding? _season = widget.seasons.firstOrNull;
  late String _metric = widget.leaderboards.firstOrNull?.rankType ?? 'GOALS';

  @override
  Widget build(BuildContext context) {
    final overview = ref
        .watch(
          teamOverviewProvider((
            teamId: widget.teamId,
            seasonId: _season?.seasonId,
            stageId: _season?.stageId,
          )),
        )
        .value;
    final boards = overview?.leaderboards.isNotEmpty == true
        ? overview!.leaderboards
        : widget.leaderboards;
    final board =
        boards.where((item) => item.rankType == _metric).firstOrNull ??
        boards.firstOrNull;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xffa3184c),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          key: const ValueKey('team_leaderboard_back'),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(overview?.teamName ?? '球队榜单'),
      ),
      body: board == null
          ? const AppStateView(
              kind: AppStateKind.empty,
              title: '暂无榜单',
              message: '当前没有可展示的排行数据。',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (widget.seasons.isNotEmpty)
                  DropdownButtonFormField<TeamCompetitionStanding>(
                    key: const ValueKey('team_leaderboard_season'),
                    initialValue: _season,
                    decoration: const InputDecoration(labelText: '赛季与赛事'),
                    items: [
                      for (final season in widget.seasons)
                        DropdownMenuItem(
                          value: season,
                          child: Text(
                            '${season.seasonName ?? '赛季'} ${season.leagueName}',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _season = value),
                  ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in boards)
                      ChoiceChip(
                        label: Text(item.title),
                        selected: item.rankType == board.rankType,
                        onSelected: (_) =>
                            setState(() => _metric = item.rankType),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final player in board.players.indexed)
                  Card(
                    key: ValueKey('team_leaderboard_row_${player.$2.id}'),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${player.$1 + 1}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppPlayerAvatar(
                            identity: 'player:${player.$2.id}',
                            name: player.$2.name,
                            imageUrl: resolveMediaUrl(
                              ref.watch(appConfigProvider),
                              player.$2.avatarUrl,
                            ),
                            size: 40,
                          ),
                        ],
                      ),
                      title: Text(
                        player.$2.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(_positionLabel(player.$2.position)),
                      trailing: Text(
                        _leaderboardValue(board.rankType, player.$2),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

String _leaderboardValue(String type, TeamRosterPlayer player) =>
    switch (type) {
      'GOALS' => '${player.goals ?? 0} 球',
      'ASSISTS' => '${player.assists ?? 0} 次',
      'APPEARANCES' => '${player.appearances ?? 0} 场',
      'RATING' => _finiteDouble(player.rating),
      _ => '—',
    };

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
    final children = <Widget>[];
    final grouped = <String, List<TeamRosterPlayer>>{};
    for (final player in _sortPlayers(state.records)) {
      grouped
          .putIfAbsent(_positionLabel(player.position), () => [])
          .add(player);
    }
    for (final entry in grouped.entries) {
      children.add(_PlayerGroup(title: entry.key, players: entry.value));
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

class _PlayerGroup extends StatelessWidget {
  const _PlayerGroup({required this.title, required this.players});
  final String title;
  final List<TeamRosterPlayer> players;
  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.sizeOf(context).width - AppSpacing.lg * 2 - 8) / 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final player in players)
                SizedBox(
                  width: width,
                  child: player.id <= 0
                      ? _RosterTile(player: player)
                      : _PlayerCard(player: player),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RosterTile extends ConsumerWidget {
  const _RosterTile({required this.player});
  final TeamRosterPlayer player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: ValueKey('team_player_${player.id}'),
    onTap: player.id > 0 ? () => context.push('/players/${player.id}') : null,
    leading: AppPlayerAvatar(
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
    trailing: player.rating == null ? null : Text(_finiteDouble(player.rating)),
  );
}

class _PlayerCard extends ConsumerWidget {
  const _PlayerCard({required this.player});
  final TeamRosterPlayer player;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    key: ValueKey('team_player_${player.id}'),
    color: const Color(0xfffff6d9),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: player.id > 0 ? () => context.push('/players/${player.id}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            width: double.infinity,
            color: const Color(0xffffdf83),
            child: AppPlayerAvatar(
              identity: 'player:${player.id}',
              name: player.name,
              imageUrl: resolveMediaUrl(
                ref.watch(appConfigProvider),
                player.avatarUrl,
              ),
              size: 92,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.shirtNumber?.toString() ?? '—',
                  style: const TextStyle(
                    color: Color(0xff936c00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        _roleLabel(player.squadRole),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (player.captain)
                        const Text(
                          '队长',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (player.appearances != null || player.goals != null)
                        Text(
                          '${player.appearances ?? 0} 场 · ${player.goals ?? 0} 球',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      if (player.goals != null)
                        Text(
                          '进球 ${player.goals}',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab({required this.request});
  final TeamDetailContext request;
  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  var _mode = 'total';
  TeamDetailContext? _selectedRequest;
  @override
  Widget build(BuildContext context) => ref
      .watch(teamStatsProvider(_selectedRequest ?? widget.request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球队数据',
          message: '正在读取赛季统计…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球队数据',
          error: error,
          onRetry: () => ref.invalidate(
            teamStatsProvider(_selectedRequest ?? widget.request),
          ),
        ),
        data: (stats) => stats.hasData
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _StatsSelector(
                    request: _selectedRequest ?? widget.request,
                    onSelected: (option) => setState(() {
                      _selectedRequest = (
                        teamId: widget.request.teamId,
                        seasonId: option.seasonId,
                        stageId: option.stageId,
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StatsModeSelector(
                    mode: _mode,
                    onChanged: (value) => setState(() => _mode = value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatGroups(stats: stats, average: _mode == 'average'),
                ],
              )
            : const AppStateView(
                kind: AppStateKind.empty,
                title: '暂无球队数据',
                message: '当前赛季或阶段没有可展示的统计。',
              ),
      );
}

class _StatsModeSelector extends StatelessWidget {
  const _StatsModeSelector({required this.mode, required this.onChanged});
  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('team_stats_mode'),
    height: 42,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        for (final option in const [('total', '总计'), ('average', '场均')])
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => onChanged(option.$1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mode == option.$1
                      ? AppColors.brand
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    option.$2,
                    style: TextStyle(
                      color: mode == option.$1
                          ? Colors.white
                          : AppColors.inkMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _StatsSelector extends ConsumerWidget {
  const _StatsSelector({required this.request, required this.onSelected});
  final TeamDetailContext request;
  final ValueChanged<TeamCompetitionStanding> onSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(teamOverviewProvider(request)).value;
    final options =
        overview?.competitionStandings ?? const <TeamCompetitionStanding>[];
    final selected = options
        .where(
          (option) =>
              option.seasonId == request.seasonId &&
              option.stageId == request.stageId,
        )
        .firstOrNull;
    final current = selected ?? options.firstOrNull;
    final label = options.isEmpty
        ? (overview?.seasonName ?? '当前赛季')
        : '${current?.seasonName ?? overview?.seasonName ?? '当前赛季'} ${current?.leagueName}';
    return InkWell(
      key: const ValueKey('team_stats_selector'),
      onTap: options.isEmpty
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '选择赛季与赛事',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    for (final group in _groupStandings(options)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: Text(
                          group.$1,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      for (final option in group.$2)
                        ListTile(
                          key: ValueKey(
                            'team_selector_${option.leagueId}_${option.seasonId}',
                          ),
                          title: Text(option.leagueName),
                          subtitle: Text(option.seasonName ?? '赛季'),
                          trailing:
                              option.leagueId == current?.leagueId &&
                                  option.seasonId == current?.seasonId &&
                                  option.stageId == current?.stageId
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.brand,
                                )
                              : Text('${option.points ?? '—'} 分'),
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGroups extends StatelessWidget {
  const _StatGroups({required this.stats, this.average = false});
  final TeamStats stats;
  final bool average;
  @override
  Widget build(BuildContext context) {
    final divisor = average ? (stats.played ?? 0) : 1;
    String number(int? value) =>
        divisor <= 0 ? '—' : _number(value == null ? null : value / divisor);
    String decimal(double? value) =>
        divisor <= 0 || value == null || !value.isFinite
        ? '—'
        : (value / divisor).toStringAsFixed(2);
    final groups = <(String, List<(String, String)>)>[
      (
        '进攻',
        [
          ('进球', number(stats.goalsFor)),
          ('射门', number(stats.shots)),
          ('射正', number(stats.shotsOnTarget)),
          ('射正率', _percent(stats.shotAccuracy)),
          ('角球', number(stats.corners)),
        ],
      ),
      (
        '组织',
        [
          ('助攻', number(stats.assists)),
          ('比赛', _value(stats.played)),
          ('积分', number(stats.points)),
          ('净胜球', number(stats.goalDifference)),
        ],
      ),
      (
        '防守',
        [
          ('失球', number(stats.goalsAgainst)),
          ('零封', number(stats.cleanSheets)),
          (
            '当前排名',
            stats.standingRank == null ? '—' : '第 ${stats.standingRank} 名',
          ),
        ],
      ),
      (
        '纪律',
        [
          ('犯规', number(stats.fouls)),
          ('黄牌', number(stats.yellowCards)),
          ('红牌', number(stats.redCards)),
          ('平均评分', decimal(stats.averageRating)),
        ],
      ),
    ];
    return Column(
      children: [
        for (final group in groups)
          _StatSection(title: group.$1, values: group.$2),
      ],
    );
  }
}

class _StatSection extends StatelessWidget {
  const _StatSection({required this.title, required this.values});
  final String title;
  final List<(String, String)> values;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surfaceMuted,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 7,
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final item in values)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                5,
                AppSpacing.md,
                5,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item.$1)),
                  Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

List<(String, List<TeamCompetitionStanding>)> _groupStandings(
  List<TeamCompetitionStanding> values,
) {
  final groups = <String, List<TeamCompetitionStanding>>{};
  for (final value in values) {
    groups.putIfAbsent(value.seasonName ?? '其他赛季', () => []).add(value);
  }
  return groups.entries.map((entry) => (entry.key, entry.value)).toList();
}

String _number(double? value) => value == null || !value.isFinite
    ? '—'
    : value.truncateToDouble() == value
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

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
  const _ContentTile({required this.content, this.compact = false});
  final TeamContentSummary content;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: EdgeInsets.only(
      top: compact ? 0 : AppSpacing.sm,
      bottom: compact ? 6 : 0,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('team_content_${content.id}'),
      onTap: content.id > 0
          ? () => context.push('/contents/${content.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.coverUrl?.trim().isNotEmpty == true)
            AspectRatio(
              aspectRatio: compact ? 1.5 : 1.35,
              child: AppContentImage(
                imageUrl: resolveMediaUrl(
                  ref.watch(appConfigProvider),
                  content.coverUrl,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? 7 : AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (!compact && content.summary?.trim().isNotEmpty == true)
                  Text(
                    content.summary!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                Text(
                  '${_contentTypeLabel(content.rawType)} · ${content.likeCount} 赞 · ${content.commentCount} 评论',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
                if (content.publishTime != null)
                  Text(
                    footballDate(content.publishTime),
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
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
        padding: EdgeInsets.zero,
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
