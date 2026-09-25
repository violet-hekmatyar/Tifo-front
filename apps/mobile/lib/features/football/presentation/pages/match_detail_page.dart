import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../../interaction/presentation/widgets/comment_section.dart';
import '../../../interaction/presentation/controllers/comment_controller.dart';
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
                _LineupsTab(matchId: widget.matchId, events: detail.events),
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
    return SizedBox(
      key: const ValueKey('match_header'),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/ui/home/neutral-football-cover.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x9906131d), Color(0xf506131d)],
                ),
              ),
            ),
          ),
          Padding(
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
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/app/data'),
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            [
                                  match.leagueName,
                                  detail.roundName ?? detail.season,
                                ]
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
                        imageUrl: resolveMediaUrl(
                          config,
                          match.homeTeam.logoUrl,
                        ),
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
                        imageUrl: resolveMediaUrl(
                          config,
                          match.awayTeam.logoUrl,
                        ),
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width - AppSpacing.xs * 2,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: InkWell(
                  key: ValueKey(_tabs[i].$1),
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _tabs[i].$2,
                            maxLines: 1,
                            style: TextStyle(
                              color: i == selectedIndex
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
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
              ),
          ],
        ),
      ),
    ),
  );
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({required this.detail, required this.controller});
  final MatchDetail detail;
  final MatchResourceController<MatchDetail> controller;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchContentsControllerProvider(widget.detail.match.id)).load();
      ref.read(matchTeamStatsControllerProvider(widget.detail.match.id)).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentController = ref.watch(
      matchContentsControllerProvider(widget.detail.match.id),
    );
    final statsController = ref.watch(
      matchTeamStatsControllerProvider(widget.detail.match.id),
    );
    final contents = contentController.state.value?.records ?? const [];
    final stats = statsController.state.value ?? const <MatchTeamStatItem>[];
    return RefreshIndicator(
      key: const ValueKey('match_overview_refresh'),
      onRefresh: () => Future.wait([
        widget.controller.refresh(),
        contentController.refresh(),
        statsController.refresh(),
      ]),
      child: SingleChildScrollView(
        key: const PageStorageKey('match_overview_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            if (widget.controller.state.message != null)
              _RefreshError(
                key: const ValueKey('match_overview_refresh_error'),
                message: widget.controller.state.message!,
                onRetry: widget.controller.refresh,
                retryKey: const ValueKey('match_overview_refresh_retry'),
              ),
            if (contents.isNotEmpty) ...[
              const _SectionTitle('最新资讯'),
              _MatchContentGrid(contents: contents),
            ],
            if (widget.detail.report case final report?)
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
            if (stats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const _SectionTitle('简要统计'),
              _MatchBriefStats(stats: stats),
            ],
            const SizedBox(height: AppSpacing.sm),
            const _SectionTitle('比赛事件'),
            if (widget.detail.events.isEmpty)
              const CapabilityEmpty(title: '暂无比赛事件', message: '本场比赛暂未记录事件。')
            else
              _MatchEventTimeline(
                events: _sortedEvents(widget.detail.events),
                homeTeamId: widget.detail.match.homeTeam.id,
              ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchContentGrid extends ConsumerWidget {
  const _MatchContentGrid({required this.contents});
  final List<MatchRelatedContent> contents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = contents.take(2).toList(growable: false);
    final hero = contents.length > 2 ? contents[2] : contents.first;
    return LayoutBuilder(
      key: const ValueKey('match_related_contents'),
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Column(
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final content in compact)
                  SizedBox(
                    width: cardWidth,
                    child: _CompactMatchContentCard(content: content),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _MatchHeroContentCard(content: hero),
          ],
        );
      },
    );
  }
}

class _CompactMatchContentCard extends ConsumerWidget {
  const _CompactMatchContentCard({required this.content});
  final MatchRelatedContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('match_content_${content.contentId}'),
      onTap: content.contentId > 0
          ? () => context.push('/contents/${content.contentId}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppContentImage(
            imageUrl: resolveMediaUrl(
              ref.watch(appConfigProvider),
              content.coverUrl,
            ),
            aspectRatio: 1.55,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '比赛资讯 · ${content.commentCount} 评论',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _MatchHeroContentCard extends ConsumerWidget {
  const _MatchHeroContentCard({required this.content});
  final MatchRelatedContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    key: ValueKey('match_hero_content_${content.contentId}'),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: content.contentId > 0
          ? () => context.push('/contents/${content.contentId}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppContentImage(
            imageUrl: resolveMediaUrl(
              ref.watch(appConfigProvider),
              content.coverUrl,
            ),
            aspectRatio: 1.78,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '比赛集锦',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MatchBriefStats extends StatelessWidget {
  const _MatchBriefStats({required this.stats});
  final List<MatchTeamStatItem> stats;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (final item in stats.take(5)) ...[
            _BriefStatRow(item: item),
            if (item != stats.take(5).last)
              const Divider(height: AppSpacing.md),
          ],
        ],
      ),
    ),
  );
}

class _BriefStatRow extends StatelessWidget {
  const _BriefStatRow({required this.item});
  final MatchTeamStatItem item;

  @override
  Widget build(BuildContext context) {
    final home = _statNumber(item.homeValue);
    final away = _statNumber(item.awayValue);
    final max = home.abs() > away.abs() ? home.abs() : away.abs();
    final homeRatio = max == 0 ? .5 : home.abs() / max;
    final awayRatio = max == 0 ? .5 : away.abs() / max;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 40, child: Text(_formatStat(home))),
            Expanded(
              child: Column(
                children: [
                  Text(item.displayName, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: homeRatio,
                            child: const SizedBox(
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FractionallySizedBox(
                          widthFactor: awayRatio,
                          child: const SizedBox(
                            height: 5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(_formatStat(away), textAlign: TextAlign.end),
            ),
          ],
        ),
      ],
    );
  }
}

class _LineupsTab extends ConsumerStatefulWidget {
  const _LineupsTab({required this.matchId, required this.events});
  final int matchId;
  final List<MatchEvent> events;
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
      child: SingleChildScrollView(
        key: const PageStorageKey('match_lineups_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
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
              if (value.home case final home?)
                if (value.away case final away?)
                  _MatchPitch(home: home, away: away, events: widget.events),
              const SizedBox(height: AppSpacing.sm),
              const _SectionTitle('教练与替补'),
              if (value.home case final team?)
                _TeamLineupCard(team: team, side: '主队'),
              if (value.away case final team?)
                _TeamLineupCard(team: team, side: '客队'),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _MatchPitch extends StatelessWidget {
  const _MatchPitch({
    required this.home,
    required this.away,
    required this.events,
  });
  final MatchTeamLineup home;
  final MatchTeamLineup away;
  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width * 2.15).clamp(780.0, 980.0);
        final homePlacements = _pitchPlacements(
          home.starters,
          homeSide: true,
          width: width,
          height: height,
        );
        final awayPlacements = _pitchPlacements(
          away.starters,
          homeSide: false,
          width: width,
          height: height,
        );
        return Card(
          key: const ValueKey('match_lineup_pitch'),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                key: const ValueKey('match_lineup_pitch_field'),
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff12a46a), Color(0xff078653)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _PitchLinesPainter()),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _PitchTeamBadge(team: home, label: '主队'),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _PitchTeamBadge(team: away, label: '客队'),
                    ),
                    for (final player in home.starters)
                      _PitchPlayer(
                        player: player,
                        placement: homePlacements[player.playerId]!,
                        event: _playerEvent(events, player.playerId),
                      ),
                    for (final player in away.starters)
                      _PitchPlayer(
                        player: player,
                        placement: awayPlacements[player.playerId]!,
                        event: _playerEvent(events, player.playerId),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: const [
                    _PitchLegend(icon: Icons.sports_soccer, label: '进球'),
                    _PitchLegend(icon: Icons.crop_square, label: '牌类'),
                    _PitchLegend(icon: Icons.swap_horiz_rounded, label: '换人'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _PitchPlacement {
  const _PitchPlacement({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;
}

Map<int, _PitchPlacement> _pitchPlacements(
  List<MatchLineupPlayer> players, {
  required bool homeSide,
  required double width,
  required double height,
}) {
  if (players.isEmpty) return const {};
  final rows = <List<(int, MatchLineupPlayer, double)>>[];
  final indexed = players.asMap().entries.map((entry) {
    final player = entry.value;
    final fallbackY = _fallbackPitchY(entry.key, players.length);
    final rawY = ((player.fieldY ?? fallbackY) / 100).clamp(0.04, 0.96);
    final displayedY = homeSide ? rawY : 1 - rawY;
    return (entry.key, player, displayedY);
  }).toList()..sort((a, b) => a.$3.compareTo(b.$3));

  for (final item in indexed) {
    if (rows.isEmpty || (item.$3 - _rowAverage(rows.last)).abs() > .105) {
      rows.add([item]);
    } else {
      rows.last.add(item);
    }
  }

  final largestRow = rows.fold<int>(
    1,
    (largest, row) => row.length > largest ? row.length : largest,
  );
  final nodeWidth = ((width - 20 - (largestRow - 1) * 4) / largestRow).clamp(
    62.0,
    86.0,
  );
  const nodeHeight = 82.0;
  final placements = <int, _PitchPlacement>{};
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex]
      ..sort((a, b) {
        final aX = (a.$2.fieldX ?? (a.$1 + 1) * 100 / (players.length + 1));
        final bX = (b.$2.fieldX ?? (b.$1 + 1) * 100 / (players.length + 1));
        return aX.compareTo(bX);
      });
    final rowProgress = rows.length == 1 ? .5 : rowIndex / (rows.length - 1);
    final start = homeSide ? .11 : .57;
    final end = homeSide ? .43 : .89;
    final centerY = height * (start + (end - start) * rowProgress);
    final gap = row.length == 1
        ? 0.0
        : (width - 20 - row.length * nodeWidth) / (row.length - 1);
    for (var index = 0; index < row.length; index++) {
      final left = 10 + index * (nodeWidth + gap);
      placements[row[index].$2.playerId] = _PitchPlacement(
        left: left,
        top: centerY - nodeHeight / 2,
        width: nodeWidth,
      );
    }
  }
  return placements;
}

double _rowAverage(List<(int, MatchLineupPlayer, double)> row) =>
    row.map((item) => item.$3).reduce((a, b) => a + b) / row.length;

double _fallbackPitchY(int index, int total) {
  if (total == 11) {
    const values = [
      92.0,
      72.0,
      72.0,
      72.0,
      72.0,
      52.0,
      52.0,
      52.0,
      32.0,
      32.0,
      32.0,
    ];
    return values[index.clamp(0, values.length - 1)];
  }
  return 12 + (index % 4) * 24;
}

class _PitchTeamBadge extends StatelessWidget {
  const _PitchTeamBadge({required this.team, required this.label});
  final MatchTeamLineup team;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .28),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '$label · ${team.formation ?? '阵型待定'}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _PitchPlayer extends ConsumerWidget {
  const _PitchPlayer({
    required this.player,
    required this.placement,
    this.event,
  });
  final MatchLineupPlayer player;
  final _PitchPlacement placement;
  final MatchEvent? event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marker = event;
    return Positioned(
      left: placement.left,
      top: placement.top,
      child: SizedBox(
        width: placement.width,
        height: 82,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: placement.width,
            child: InkWell(
              key: ValueKey('lineup_player_${player.playerId}'),
              onTap: player.playerId > 0
                  ? () => context.push('/players/${player.playerId}')
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppPlayerAvatar(
                        identity: 'player:${player.playerId}',
                        name: player.playerName,
                        imageUrl: resolveMediaUrl(
                          ref.watch(appConfigProvider),
                          player.avatarUrl,
                        ),
                        size: 46,
                      ),
                      if (player.captain)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (marker != null)
                        Positioned(
                          left: -7,
                          top: -5,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                _eventIcon(marker.type),
                                size: 12,
                                color: _eventColor(marker.type),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        '${player.shirtNumber ?? '—'} ${player.playerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PitchLegend extends StatelessWidget {
  const _PitchLegend({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.inkMuted),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
      ),
    ],
  );
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, paint);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 28, paint);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .2, 0, size.width * .6, size.height * .2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .2,
        size.height * .8,
        size.width * .6,
        size.height * .2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    key: ValueKey('lineup_roster_player_${player.playerId}'),
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
          Card(
            key: const ValueKey('match_knockout_tree_entry'),
            margin: const EdgeInsets.only(top: AppSpacing.md),
            child: ListTile(
              onTap: () => context.push('/football/knockout-tree'),
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('淘汰树'),
              subtitle: const Text('完整淘汰树正在开发，当前仅保留入口'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
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
    final grouped = <String, List<MatchTeamStatItem>>{};
    for (final item in values) {
      final group = _statGroup(item.rawType);
      grouped.putIfAbsent(group, () => <MatchTeamStatItem>[]).add(item);
    }
    final groupOrder = const ['进攻', '组织', '防守', '其他'];
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
              for (final group in groupOrder)
                if (grouped[group]?.isNotEmpty == true)
                  _StatGroupCard(
                    title: group,
                    items: grouped[group]!,
                    homeName: detail.match.homeTeam.name,
                    awayName: detail.match.awayTeam.name,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatGroupCard extends StatelessWidget {
  const _StatGroupCard({
    required this.title,
    required this.items,
    required this.homeName,
    required this.awayName,
  });
  final String title;
  final List<MatchTeamStatItem> items;
  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  homeName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Expanded(child: Text('指标', textAlign: TextAlign.center)),
              Expanded(
                child: Text(
                  awayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        for (final item in items) _TeamStatRow(item: item),
      ],
    ),
  );
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
                onOpenDetails: () =>
                    _showRatingDetail(context, controller, rating),
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
    _ratingComment = '';
    var selected = _safeRating(
      rating.currentUserRating ?? rating.averageRating ?? rating.officialRating,
    );
    final result = await showModalBottomSheet<_RatingInputValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bottom = MediaQuery.viewInsetsOf(context).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: FractionallySizedBox(
              heightFactor: .78,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            AppPlayerAvatar(
                              identity: 'player:${rating.playerId}',
                              name: rating.playerName,
                              imageUrl: resolveMediaUrl(
                                ref.read(appConfigProvider),
                                rating.avatarUrl,
                              ),
                              size: 82,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rating.playerName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '本场球员 · ${rating.ratingCount} 人参与',
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: Text(
                            selected.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var index = 1; index <= 5; index++)
                              IconButton(
                                key: ValueKey('match_rating_star_$index'),
                                iconSize: 34,
                                icon: Icon(
                                  selected >= index * 2
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: const Color(0xffffbf00),
                                ),
                                onPressed: () => setDialogState(
                                  () => selected = index * 2.0,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            key: const ValueKey('match_rating_comment_input'),
                            autofocus: true,
                            maxLength: 200,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: '快来发布你的评论吧',
                              filled: true,
                              fillColor: AppColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => _ratingComment = value,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              key: const ValueKey('match_rating_cancel_input'),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FilledButton(
                              key: const ValueKey('match_rating_submit_input'),
                              onPressed: () => Navigator.pop(
                                context,
                                _RatingInputValue(
                                  selected,
                                  _ratingComment.trim(),
                                ),
                              ),
                              child: const Text('发布'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      await controller.submit(rating.playerId, result.rating);
      if (result.comment.isNotEmpty && rating.ratingTargetId != null) {
        await ref
            .read(playerRatingCommentControllerProvider(rating.ratingTargetId!))
            .submit(result.comment);
      }
    }
  }

  String _ratingComment = '';

  Future<void> _showRatingDetail(
    BuildContext context,
    MatchRatingsController controller,
    MatchRatingSummary rating,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RatingDetailSheet(
      matchId: widget.matchId,
      rating: rating,
      detail: widget.detail,
      onOpenInput: () {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _chooseRating(this.context, controller, rating);
        });
      },
    ),
  );
}

final class _RatingInputValue {
  const _RatingInputValue(this.rating, this.comment);
  final double rating;
  final String comment;
}

class _RatingTile extends ConsumerWidget {
  const _RatingTile({
    required this.rating,
    required this.busy,
    required this.onOpenDetails,
    required this.onRate,
    required this.onCancel,
  });
  final MatchRatingSummary rating;
  final bool busy;
  final VoidCallback onOpenDetails;
  final VoidCallback? onRate;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    key: ValueKey('rating_player_${rating.playerId}'),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: rating.playerId > 0 ? onOpenDetails : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppPlayerAvatar(
              identity: 'player:${rating.playerId}',
              name: rating.playerName,
              imageUrl: resolveMediaUrl(
                ref.watch(appConfigProvider),
                rating.avatarUrl,
              ),
              size: 72,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var index = 0; index < 5; index++)
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color:
                              index <
                                  (_safeRating(rating.averageRating) / 2)
                                      .round()
                              ? const Color(0xffffbf00)
                              : AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '官方 ${_finiteDisplay(rating.officialRating, digits: 1)} · 用户 ${_finiteDisplay(rating.averageRating, digits: 1)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  Text(
                    '${rating.ratingCount} 人评分${rating.currentUserRating == null ? '' : ' · 我的 ${_finiteDisplay(rating.currentUserRating, digits: 1)}'}',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('媒体评分', style: TextStyle(color: AppColors.inkMuted)),
                Text(
                  '${_finiteDisplay(rating.officialRating, digits: 1)} 分',
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (busy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (onRate != null)
                  IconButton(
                    key: ValueKey('rate_player_${rating.playerId}'),
                    tooltip: '提交评分',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRate,
                    icon: const Icon(Icons.star_outline_rounded),
                  ),
                if (onCancel != null)
                  IconButton(
                    key: ValueKey('cancel_rating_${rating.playerId}'),
                    tooltip: '撤销评分',
                    visualDensity: VisualDensity.compact,
                    onPressed: onCancel,
                    icon: const Icon(Icons.undo_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RatingDetailSheet extends ConsumerStatefulWidget {
  const _RatingDetailSheet({
    required this.matchId,
    required this.rating,
    required this.detail,
    required this.onOpenInput,
  });
  final int matchId;
  final MatchRatingSummary rating;
  final MatchDetail detail;
  final VoidCallback onOpenInput;

  @override
  ConsumerState<_RatingDetailSheet> createState() => _RatingDetailSheetState();
}

class _RatingDetailSheetState extends ConsumerState<_RatingDetailSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(matchPlayerStatsControllerProvider(widget.matchId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsController = ref.watch(
      matchPlayerStatsControllerProvider(widget.matchId),
    );
    MatchPlayerStat? playerStat;
    for (final item in statsController.state.records) {
      if (item.playerId == widget.rating.playerId) {
        playerStat = item;
        break;
      }
    }
    final match = widget.detail.match;
    final config = ref.watch(appConfigProvider);
    return FractionallySizedBox(
      heightFactor: .96,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  8,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff06131d),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('rating_detail_back'),
                          tooltip: '返回评分列表',
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            '评分详情',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    Row(
                      children: [
                        AppTeamLogo(
                          identity: 'team:${match.homeTeam.id}',
                          name: match.homeTeam.name,
                          imageUrl: resolveMediaUrl(
                            config,
                            match.homeTeam.logoUrl,
                          ),
                          size: 32,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${match.homeTeam.score ?? '—'} : ${match.awayTeam.score ?? '—'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        AppTeamLogo(
                          identity: 'team:${match.awayTeam.id}',
                          name: match.awayTeam.name,
                          imageUrl: resolveMediaUrl(
                            config,
                            match.awayTeam.logoUrl,
                          ),
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              AppPlayerAvatar(
                                identity: 'player:${widget.rating.playerId}',
                                name: widget.rating.playerName,
                                imageUrl: resolveMediaUrl(
                                  config,
                                  widget.rating.avatarUrl,
                                ),
                                size: 82,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.rating.playerName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '本场评分详情 · ${widget.rating.ratingCount} 人参与',
                                      style: const TextStyle(
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RatingMatchStatsCard(
                        player: playerStat,
                        loading:
                            statsController.state.status ==
                            TeamPagedStatus.loading,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: Text(
                                  '我的评分',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Center(
                                child: Text(
                                  _finiteDisplay(
                                    widget.rating.averageRating,
                                    digits: 1,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < 5; i++)
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xffffbf00),
                                      size: 25,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                '球迷评分分布',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              for (final entry
                                  in widget.rating.distribution.entries)
                                _RatingDistributionBar(
                                  label: entry.key,
                                  count: entry.value,
                                  total: widget.rating.ratingCount,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (widget.rating.ratingTargetId == null)
                        const CapabilityEmpty(
                          title: '暂无评分讨论',
                          message: '当前评分暂未开放讨论。',
                        )
                      else
                        CommentSection(
                          contentId: widget.rating.ratingTargetId!,
                          targetType: 'PLAYER_RATING',
                          currentUserId: null,
                          key: ValueKey(
                            'rating_comments_${widget.rating.ratingTargetId}',
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        key: const ValueKey('rating_detail_input_entry'),
                        onPressed: widget.onOpenInput,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('评分评论'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingMatchStatsCard extends StatelessWidget {
  const _RatingMatchStatsCard({required this.player, required this.loading});
  final MatchPlayerStat? player;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && player == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (player == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('暂无单场关键统计'),
        ),
      );
    }
    final values = <({String label, String value})>[
      if (player!.goals != null) (label: '进球', value: '${player!.goals}'),
      if (player!.assists != null) (label: '助攻', value: '${player!.assists}'),
      if (player!.minutes != null)
        (label: '出场时间', value: '${player!.minutes}′'),
      if (player!.shots != null) (label: '射门', value: '${player!.shots}'),
      if (player!.shotsOnTarget != null)
        (label: '射正', value: '${player!.shotsOnTarget}'),
      if (player!.passes != null) (label: '传球', value: '${player!.passes}'),
      if (player!.tackles != null) (label: '抢断', value: '${player!.tackles}'),
      if (player!.interceptions != null)
        (label: '拦截', value: '${player!.interceptions}'),
      if (player!.saves != null && player!.saves! > 0)
        (label: '扑救', value: '${player!.saves}'),
    ];
    return Card(
      key: const ValueKey('rating_match_stats'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('单场关键统计', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in values)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 88) / 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.value,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          item.label,
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingDistributionBar extends StatelessWidget {
  const _RatingDistributionBar({
    required this.label,
    required this.count,
    required this.total,
  });
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: AppColors.brand,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      ),
    );
  }
}

class _MatchEventTimeline extends StatelessWidget {
  const _MatchEventTimeline({required this.events, required this.homeTeamId});
  final List<MatchEvent> events;
  final int homeTeamId;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('match_event_timeline'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++) ...[
            if (index > 0 &&
                events[index - 1].minute < 45 &&
                events[index].minute >= 45)
              const _MatchHalfMarker(label: '半场'),
            _EventTile(event: events[index], homeTeamId: homeTeamId),
          ],
          const _MatchHalfMarker(label: '全场'),
        ],
      ),
    ),
  );
}

class _MatchHalfMarker extends StatelessWidget {
  const _MatchHalfMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(label),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, this.homeTeamId});
  final MatchEvent event;
  final int? homeTeamId;

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
    final isHome = homeTeamId == null || event.teamId == homeTeamId;
    final detail = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isHome) ...[
          Expanded(child: _eventCard(context, actors)),
          const SizedBox(width: 46),
        ] else ...[
          const SizedBox(width: 46),
          Expanded(child: _eventCard(context, actors)),
        ],
      ],
    );
    return Stack(
      key: ValueKey('match_event_${event.id}'),
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Center(child: Container(width: 1, color: AppColors.border)),
          ),
        ),
        detail,
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                '${event.minute}′',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(BuildContext context, List<Widget> actors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _eventColor(event.type).withValues(alpha: .14),
              child: Icon(
                _eventIcon(event.type),
                size: 17,
                color: _eventColor(event.type),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_eventType(event.type)}${event.scoreAfter == null ? '' : ' · ${event.scoreAfter}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Wrap(spacing: AppSpacing.xs, runSpacing: 2, children: actors),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _eventColor(String value) => switch (value.trim().toUpperCase()) {
  'GOAL' || 'OWN_GOAL' || 'PENALTY_GOAL' => AppColors.brand,
  'YELLOW_CARD' => const Color(0xffe0a000),
  'RED_CARD' => AppColors.error,
  'SUBSTITUTION' => AppColors.accent,
  _ => AppColors.inkMuted,
};

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

MatchEvent? _playerEvent(List<MatchEvent> events, int playerId) {
  for (final event in events) {
    if (event.playerId == playerId) return event;
  }
  return null;
}

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

double _statNumber(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : 0;
}

String _formatStat(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _statGroup(String rawType) {
  final type = rawType.trim().toUpperCase();
  if (type.contains('PASS') ||
      type.contains('POSSESSION') ||
      type.contains('KEY')) {
    return '组织';
  }
  if (type.contains('SHOT') ||
      type.contains('GOAL') ||
      type.contains('ATTACK') ||
      type.contains('CORNER') ||
      type.contains('OFFSIDE') ||
      type.contains('EXPECTED')) {
    return '进攻';
  }
  if (type.contains('TACKLE') ||
      type.contains('FOUL') ||
      type.contains('CARD') ||
      type.contains('DEF') ||
      type.contains('SAVE')) {
    return '防守';
  }
  return '其他';
}

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
