import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_state_illustration.dart';
import '../../../feed/data/feed_repository.dart';
import '../../../feed/domain/feed_page.dart';
import '../../../feed/presentation/widgets/followed_team_bar.dart';
import '../../domain/football_models.dart';
import '../../domain/football_ranking_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_rankings_controller.dart';
import '../widgets/football_widgets.dart';
import '../widgets/football_rankings_widgets.dart';

enum _DataSection { schedule, standings, players, teams }

final footballFollowedTeamsProvider =
    FutureProvider.autoDispose<List<FollowedTeam>>(
      (ref) => ref.watch(feedRepositoryProvider).loadFollowedTeams(),
    );

class FootballDataPage extends ConsumerStatefulWidget {
  const FootballDataPage({super.key});
  @override
  ConsumerState<FootballDataPage> createState() => _FootballDataPageState();
}

class _FootballDataPageState extends ConsumerState<FootballDataPage> {
  final _scrollController = ScrollController();
  _DataSection _section = _DataSection.schedule;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () => ref.read(footballDataControllerProvider).loadInitial(),
    );
  }

  void _onScroll() {
    final state = ref.read(footballDataControllerProvider).state;
    if (_scrollController.position.extentAfter < 360 &&
        state.appendMessage == null) {
      ref.read(footballDataControllerProvider).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(footballDataControllerProvider);
    final state = controller.state;
    final rankings = ref.watch(footballRankingsControllerProvider);
    final rankingState = rankings.state;
    final showFollowedTeams =
        state.source is FollowingSource || state.source is TeamSource;
    final followedTeams = showFollowedTeams
        ? ref
              .watch(footballFollowedTeamsProvider)
              .when(
                data: (teams) => teams,
                loading: () => const <FollowedTeam>[],
                error: (_, _) => const <FollowedTeam>[],
              )
        : const <FollowedTeam>[];
    final selectedTeamId = switch (state.source) {
      TeamSource(:final teamId) => teamId,
      _ => null,
    };
    final activeLeagueId = _section == _DataSection.schedule
        ? switch (state.source) {
            LeagueSource(:final leagueId) => leagueId,
            _ => null,
          }
        : rankingState.selectedLeagueId;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          _CompetitionNav(
            state: state,
            activeLeagueId: activeLeagueId,
            onImportant: () => controller.selectSource(const ImportantSource()),
            onFollowing: () => controller.selectSource(const FollowingSource()),
            onLeague: (league) {
              controller.selectSource(LeagueSource(league.id));
              unawaited(rankings.selectLeague(league.id));
            },
          ),
          if (showFollowedTeams)
            FollowedTeamBar(
              teams: followedTeams,
              selectedTeamId: selectedTeamId,
              onSelected: (teamId) => controller.selectSource(
                teamId == null ? const FollowingSource() : TeamSource(teamId),
              ),
            ),
          if (_section != _DataSection.schedule || state.source is LeagueSource)
            _SectionBar(
              section: _section,
              state: rankingState,
              controller: rankings,
              onSelected: _selectSection,
            ),
          if (_section == _DataSection.schedule &&
              state.source is! LeagueSource &&
              !showFollowedTeams)
            _ScheduleSourceHint(state: state),
          Expanded(
            child: _section == _DataSection.schedule
                ? switch (state.status) {
                    FootballDataStatus.loading => const AppStateView(
                      kind: AppStateKind.loading,
                      title: '正在加载赛程',
                      message: '正在读取联赛与比赛数据…',
                    ),
                    FootballDataStatus.failure => AppStateView(
                      kind: AppStateKind.error,
                      title: '赛程加载失败',
                      message: state.message ?? '请检查网络后重试。',
                      onRetry: controller.loadInitial,
                    ),
                    FootballDataStatus.empty => RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 420,
                            child: AppStateView(
                              kind: AppStateKind.empty,
                              title: '暂无比赛',
                              message: '当前范围还没有可展示的赛程，稍后再来看看。',
                              illustration: AppStateIllustrationType.noData,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FootballDataStatus.ready => _MatchList(
                      state: state,
                      controller: _scrollController,
                      onRefresh: controller.refresh,
                      onLoadMore: controller.loadMore,
                    ),
                  }
                : _rankingBody(rankingState, rankings),
          ),
        ],
      ),
    );
  }

  void _selectSection(_DataSection section) {
    if (section == _section) return;
    setState(() => _section = section);
    final view = switch (section) {
      _DataSection.standings => FootballRankingView.standings,
      _DataSection.players => FootballRankingView.players,
      _DataSection.teams => FootballRankingView.teams,
      _DataSection.schedule => null,
    };
    if (view != null) {
      ref.read(footballRankingsControllerProvider).selectView(view);
    }
  }

  Widget _rankingBody(
    FootballRankingsState state,
    FootballRankingsController controller,
  ) => switch (state.status) {
    FootballRankingsStatus.idle ||
    FootballRankingsStatus.loading => const AppStateView(
      kind: AppStateKind.loading,
      title: '正在加载榜单',
      message: '正在读取赛季、阶段与排名数据…',
    ),
    FootballRankingsStatus.failure => AppStateView(
      kind: AppStateKind.error,
      title: '榜单加载失败',
      message: state.message ?? '请检查网络后重试。',
      onRetry: controller.retry,
    ),
    FootballRankingsStatus.empty => AppStateView(
      kind: AppStateKind.empty,
      title: '暂无榜单数据',
      message: '当前赛事、赛季或阶段暂无可展示的排名。',
      onRetry: controller.retry,
      illustration: AppStateIllustrationType.noData,
    ),
    FootballRankingsStatus.ready => switch (state.view) {
      FootballRankingView.standings => StandingsList(table: state.standings!),
      FootballRankingView.players => PlayerRankingList(
        state: state,
        onLoadMore: controller.loadMore,
      ),
      FootballRankingView.teams => TeamRankingList(
        state: state,
        onLoadMore: controller.loadMore,
      ),
    },
  };
}

class _CompetitionNav extends StatelessWidget {
  const _CompetitionNav({
    required this.state,
    required this.activeLeagueId,
    required this.onImportant,
    required this.onFollowing,
    required this.onLeague,
  });

  final FootballDataState state;
  final int? activeLeagueId;
  final VoidCallback onImportant;
  final VoidCallback onFollowing;
  final ValueChanged<League> onLeague;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Row(
                  children: [
                    _NavItem(
                      key: const ValueKey('data_source_important'),
                      label: '重要',
                      selected: state.source is ImportantSource,
                      onTap: onImportant,
                    ),
                    _NavItem(
                      key: const ValueKey('data_source_following'),
                      label: '关注',
                      selected:
                          state.source is FollowingSource ||
                          state.source is TeamSource,
                      onTap: onFollowing,
                    ),
                    const _NavDivider(),
                    for (final category in _CompetitionCategoryType.values)
                      _CompetitionCategory(
                        type: category,
                        leagues: state.leagues,
                        activeLeagueId: activeLeagueId,
                        onLeague: onLeague,
                      ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('knockout_tree_entry'),
              tooltip: '更多数据',
              icon: const Icon(Icons.menu_rounded, size: 28),
              onSelected: (value) {
                if (value == 'knockout') {
                  context.push('/football/knockout-tree');
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'knockout', child: Text('淘汰树')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    child: Container(
      constraints: const BoxConstraints(minWidth: 46),
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppColors.brand : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.ink : AppColors.inkMuted,
          fontSize: 15,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _NavDivider extends StatelessWidget {
  const _NavDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.only(right: 5),
    color: AppColors.border,
  );
}

enum _CompetitionCategoryType { league, champions, cup }

class _CompetitionCategory extends StatelessWidget {
  const _CompetitionCategory({
    required this.type,
    required this.leagues,
    required this.activeLeagueId,
    required this.onLeague,
  });

  final _CompetitionCategoryType type;
  final List<League> leagues;
  final int? activeLeagueId;
  final ValueChanged<League> onLeague;

  String get label => switch (type) {
    _CompetitionCategoryType.league => '联赛',
    _CompetitionCategoryType.champions => '欧冠',
    _CompetitionCategoryType.cup => '杯赛',
  };

  IconData get icon => switch (type) {
    _CompetitionCategoryType.league => Icons.sports_soccer_rounded,
    _CompetitionCategoryType.champions => Icons.stars_rounded,
    _CompetitionCategoryType.cup => Icons.emoji_events_outlined,
  };

  List<League> get options => leagues.where(_belongs).toList();

  bool _belongs(League league) {
    final name = league.name.toLowerCase();
    final isChampions =
        name.contains('champions league') ||
        name.contains('欧冠') ||
        name.contains('欧洲冠军联赛');
    final isCup = !isChampions && (name.contains('cup') || name.contains('杯'));
    return switch (type) {
      _CompetitionCategoryType.champions => isChampions,
      _CompetitionCategoryType.cup => isCup,
      _CompetitionCategoryType.league => !isChampions && !isCup,
    };
  }

  @override
  Widget build(BuildContext context) {
    final categories = options;
    final selected = categories.any((league) => league.id == activeLeagueId);
    return InkWell(
      key: ValueKey('data_competition_${type.name}'),
      onTap: categories.isEmpty ? null : () => _select(context, categories),
      child: Container(
        height: 48,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.brand : AppColors.inkMuted,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.ink : AppColors.inkMuted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, List<League> categories) async {
    if (categories.length == 1 && type != _CompetitionCategoryType.league) {
      onLeague(categories.single);
      return;
    }
    final selected = await showModalBottomSheet<League>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                '选择$label',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final league in categories)
              ListTile(
                key: ValueKey('data_league_${league.id}'),
                title: Text(league.name),
                trailing: league.id == activeLeagueId
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(league),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onLeague(selected);
  }
}

class _ScheduleSourceHint extends StatelessWidget {
  const _ScheduleSourceHint({required this.state});
  final FootballDataState state;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    alignment: Alignment.centerLeft,
    child: Text(
      state.source is FollowingSource ? '关注球队赛程' : '重要比赛',
      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
    ),
  );
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({
    required this.section,
    required this.state,
    required this.controller,
    required this.onSelected,
  });
  final _DataSection section;
  final FootballRankingsState state;
  final FootballRankingsController controller;
  final ValueChanged<_DataSection> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: RankingContextBar(
      state: state,
      controller: controller,
      trailing: [
        const SizedBox(width: AppSpacing.xs),
        SectionButton(
          key: const ValueKey('data_section_schedule'),
          label: '赛程',
          selected: section == _DataSection.schedule,
          onTap: () => onSelected(_DataSection.schedule),
        ),
        const SizedBox(width: AppSpacing.xs),
        SectionButton(
          key: const ValueKey('data_section_standings'),
          label: '积分榜',
          selected: section == _DataSection.standings,
          onTap: () => onSelected(_DataSection.standings),
        ),
        const SizedBox(width: AppSpacing.xs),
        SectionButton(
          key: const ValueKey('data_section_players'),
          label: '球员榜',
          selected: section == _DataSection.players,
          onTap: () => onSelected(_DataSection.players),
        ),
        const SizedBox(width: AppSpacing.xs),
        SectionButton(
          key: const ValueKey('data_section_teams'),
          label: '球队榜',
          selected: section == _DataSection.teams,
          onTap: () => onSelected(_DataSection.teams),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    ),
  );
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onLoadMore,
  });
  final FootballDataState state;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    String? previousDate;
    final children = <Widget>[];
    if (state.message != null && state.matches.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: MaterialBanner(
            key: const ValueKey('schedule_refresh_error'),
            content: Text(state.message!),
            leading: const Icon(Icons.info_outline_rounded),
            actions: [
              TextButton(onPressed: onRefresh, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    for (final match in state.matches) {
      final date = footballDate(match.matchTime);
      if (date != previousDate) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        );
        previousDate = date;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: ScheduleMatchCard(match: match),
        ),
      );
    }
    children.add(
      SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: state.isLoadingMore
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('正在加载更多…'),
                  ],
                )
              : state.appendMessage != null
              ? Center(
                  child: TextButton.icon(
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('${state.appendMessage} 点击重试'),
                  ),
                )
              : Center(
                  child: Text(
                    state.hasMore ? '继续上滑加载' : '已经到底了',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
        ),
      ),
    );
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('football_data_list'),
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: children,
      ),
    );
  }
}
