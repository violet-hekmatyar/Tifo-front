import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/match_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/match_detail_page.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/recommendation/presentation/recommendation_behavior_dispatcher.dart';

void main() {
  testWidgets(
    'MATCH-01 MATCH-05 MATCH-06 MATCH-07 MATCH-08 MATCH-10 MATCH-12 MATCH-13 MATCH-16 sections render real fields',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _DetailRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('match_header')), findsOneWidget);
      expect(find.text('测试联赛 · 半决赛'), findsOneWidget);
      expect(find.text('2 : 1'), findsOneWidget);
      expect(find.text('已结束'), findsOneWidget);
      for (final key in const [
        'match_tab_ratings',
        'match_tab_overview',
        'match_tab_lineups',
        'match_tab_ranking',
        'match_tab_stats',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(find.text('进球 · 1:0'), findsOneWidget);
      expect(find.text('未知事件'), findsWidgets);
      expect(find.byKey(const ValueKey('event_assist_72')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('match_event_71'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('match_event_72'))).dy,
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('match_event_72'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('match_event_73'))).dy,
        ),
      );
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('event_team_73')))
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('event_player_73')))
            .onTap,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('match_tab_lineups')));
      await tester.pumpAndSettle();
      expect(find.text('主队 · 切尔西测试长名称'), findsOneWidget);
      expect(find.text('客队 · 莱斯特测试长名称'), findsOneWidget);
      expect(find.text('4-3-3'), findsOneWidget);
      expect(find.text('首发'), findsWidgets);
      expect(find.text('替补'), findsWidgets);
      expect(find.text('替补席'), findsOneWidget);
      expect(find.text('球场坐标'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('match_tab_ranking')));
      await tester.pumpAndSettle();
      expect(find.text('当前排名'), findsWidgets);
      expect(find.textContaining('积分'), findsWidgets);
      expect(find.textContaining('进 30'), findsOneWidget);
      expect(find.byKey(const ValueKey('standing_team_40')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('球队统计'), findsOneWidget);
      expect(find.text('控球率'), findsOneWidget);
      expect(find.text('POSSESSION'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('match_team_stat_EXTREME')),
          matching: find.text('—'),
        ),
        findsNWidgets(2),
      );
      expect(find.text('球员统计'), findsOneWidget);
      expect(find.textContaining('88.5'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_player_filter_team_40')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('match_player_filter_position_FORWARD')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('match_tab_ratings')));
      await tester.pumpAndSettle();
      expect(find.textContaining('官方 8.0'), findsOneWidget);
      expect(find.textContaining('用户 8.5'), findsOneWidget);
      expect(find.textContaining('我的 7.5'), findsOneWidget);
      expect(find.textContaining('8.5-10.0: 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('MATCH-02 invalid match id makes zero business requests', (
    tester,
  ) async {
    final repository = _DetailRepository();
    await tester.pumpWidget(_app(repository, matchId: 0));
    await tester.pumpAndSettle();
    expect(repository.baseCalls, 0);
    expect(find.text('比赛编号无效'), findsOneWidget);
  });

  testWidgets(
    'MATCH-03 valid detail recommendation is recorded once across rebuild and tab switches',
    (tester) async {
      final repository = _DetailRepository();
      final recommendationRepository = _RecommendationRepository();
      final dispatcher = RecommendationBehaviorDispatcher(
        recommendationRepository,
        batchDelay: const Duration(days: 1),
      );
      addTearDown(dispatcher.dispose);
      const source = RecommendationSourceContext(
        targetType: RecommendationTargetType.match,
        targetId: 70,
        attribution: RecommendationAttribution(impressionId: 'match-detail'),
      );
      final app = _app(
        repository,
        recommendationSource: source,
        dispatcher: dispatcher,
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_lineups')));
      await tester.pumpAndSettle();
      await dispatcher.flush();
      expect(recommendationRepository.events, hasLength(1));
      expect(
        recommendationRepository.events.single.behaviorType,
        RecommendationBehaviorType.detail,
      );
    },
  );

  testWidgets(
    'MATCH-04 MATCH-09 MATCH-11 MATCH-15 MATCH-18 resource errors and retries stay isolated',
    (tester) async {
      final repository = _DetailRepository()
        ..lineupsFail = true
        ..teamStatsFail = true
        ..ratingsFail = true;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('match_tab_lineups')));
      await tester.pumpAndSettle();
      expect(find.text('lineups down'), findsOneWidget);
      expect(find.byKey(const ValueKey('match_lineups_retry')), findsOneWidget);
      repository.lineupsFail = false;
      await tester.tap(find.byKey(const ValueKey('match_lineups_retry')));
      await tester.pumpAndSettle();
      expect(find.text('lineups down'), findsNothing);
      expect(find.byKey(const ValueKey('lineup_team_40')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('team stats down'), findsOneWidget);
      expect(find.text('球员 甲'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_team_stats_retry')),
        findsOneWidget,
      );
      repository.teamStatsFail = false;
      await tester.tap(find.byKey(const ValueKey('match_team_stats_retry')));
      await tester.pumpAndSettle();
      expect(find.text('team stats down'), findsNothing);
      expect(find.text('控球率'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('match_tab_ratings')));
      await tester.pumpAndSettle();
      expect(find.text('ratings down'), findsOneWidget);
      expect(find.byKey(const ValueKey('match_ratings_retry')), findsOneWidget);
      repository.ratingsFail = false;
      await tester.tap(find.byKey(const ValueKey('match_ratings_retry')));
      await tester.pumpAndSettle();
      expect(find.text('ratings down'), findsNothing);
      expect(find.byKey(const ValueKey('rating_player_50')), findsOneWidget);
    },
  );

  testWidgets(
    'MATCH-04 ready overview refresh preserves records and exposes retry',
    (tester) async {
      final repository = _DetailRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      repository.baseRefreshFail = true;
      await tester.drag(
        find.byKey(const PageStorageKey('match_overview_scroll')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('match_event_71')), findsOneWidget);
      expect(find.text('网络连接失败，请检查后重试。'), findsOneWidget);
      repository.baseRefreshFail = false;
      await tester.tap(
        find.byKey(const ValueKey('match_overview_refresh_retry')),
      );
      await tester.pumpAndSettle();
      expect(find.text('网络连接失败，请检查后重试。'), findsNothing);
      expect(find.byKey(const ValueKey('match_event_71')), findsOneWidget);
    },
  );

  testWidgets(
    'MATCH-20 tab scroll offsets and resource calls survive tab switches',
    (tester) async {
      tester.view.physicalSize = const Size(412, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _DetailRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      final overviewList = find.byKey(
        const PageStorageKey('match_overview_scroll'),
      );
      final overviewScrollable = find.descendant(
        of: overviewList,
        matching: find.byType(Scrollable),
      );
      final overviewState = tester.state<ScrollableState>(overviewScrollable);
      await tester.drag(overviewList, const Offset(0, -180));
      await tester.pumpAndSettle();
      final offset = overviewState.position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_overview')));
      await tester.pumpAndSettle();
      expect(overviewState.position.pixels, closeTo(offset, 0.1));
      expect(repository.baseCalls, 1);
      expect(repository.lineupsCalls, 1);
      expect(repository.teamStatsCalls, 1);
      expect(repository.playerStatsCalls, 1);
      expect(repository.ratingsCalls, 1);
    },
  );

  testWidgets(
    'MATCH-09 lineup refresh failure preserves old teams and retries in place',
    (tester) async {
      final repository = _DetailRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_lineups')));
      await tester.pumpAndSettle();
      repository.lineupsRefreshFail = true;
      await tester.drag(
        find.byKey(const PageStorageKey('match_lineups_scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(find.text('主队 · 切尔西测试长名称'), findsOneWidget);
      expect(find.text('lineups down'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_lineups_refresh_retry')),
        findsOneWidget,
      );
      final callsBeforeRetry = repository.lineupsCalls;
      repository.lineupsRefreshFail = false;
      repository.lineupsVersion = 2;
      await tester.tap(
        find.byKey(const ValueKey('match_lineups_refresh_retry')),
      );
      await tester.pumpAndSettle();
      expect(repository.lineupsCalls, callsBeforeRetry + 1);
      expect(find.text('主队 · 切尔西测试长名称'), findsNothing);
      expect(find.text('主队 · 主队更新'), findsOneWidget);
      expect(find.text('lineups down'), findsNothing);
    },
  );

  testWidgets(
    'MATCH-11 ranking failure and refresh stay independent with visible retry',
    (tester) async {
      final failed = _DetailRepository()..overviewFail = true;
      await tester.pumpWidget(_app(failed));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_ranking')));
      await tester.pumpAndSettle();
      expect(find.text('ranking down'), findsOneWidget);
      expect(find.byKey(const ValueKey('match_ranking_retry')), findsOneWidget);
      final otherCalls = (
        failed.lineupsCalls,
        failed.teamStatsCalls,
        failed.playerStatsCalls,
        failed.ratingsCalls,
      );
      failed.overviewFail = false;
      await tester.tap(find.byKey(const ValueKey('match_ranking_retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('standing_team_40')), findsOneWidget);
      expect(failed.lineupsCalls, otherCalls.$1);
      expect(failed.teamStatsCalls, otherCalls.$2);
      expect(failed.playerStatsCalls, otherCalls.$3);
      expect(failed.ratingsCalls, otherCalls.$4);

      failed.overviewFail = true;
      await tester.drag(
        find.byKey(const PageStorageKey('match_ranking_scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('standing_team_40')), findsOneWidget);
      expect(find.text('ranking down'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_ranking_refresh_retry')),
        findsOneWidget,
      );
      failed.overviewFail = false;
      failed.rankingRank = 3;
      final callsBeforeRetry = failed.overviewCalls;
      await tester.tap(
        find.byKey(const ValueKey('match_ranking_refresh_retry')),
      );
      await tester.pumpAndSettle();
      expect(failed.overviewCalls, callsBeforeRetry + 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('standing_team_40')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.text('ranking down'), findsNothing);
    },
  );

  testWidgets(
    'MATCH-15 team stats failure leaves player stats visible and retries only team',
    (tester) async {
      final repository = _DetailRepository()..teamStatsFail = true;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('球员 甲'), findsOneWidget);
      expect(find.text('team stats down'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_team_stats_retry')),
        findsOneWidget,
      );
      final playerCalls = repository.playerStatsCalls;
      repository.teamStatsFail = false;
      await tester.tap(find.byKey(const ValueKey('match_team_stats_retry')));
      await tester.pumpAndSettle();
      expect(find.text('控球率'), findsOneWidget);
      expect(find.text('team stats down'), findsNothing);
      expect(repository.playerStatsCalls, playerCalls);
    },
  );

  testWidgets(
    'MATCH-15 player stats failure leaves team stats visible and retries only player',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _DetailRepository()..playerStatsFail = true;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('控球率'), findsOneWidget);
      for (
        var i = 0;
        i < 5 &&
            find
                .byKey(const ValueKey('match_player_stats_state'))
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.drag(
          find.byKey(const PageStorageKey('match_stats_scroll')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('player stats down'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match_player_stats_retry')),
        findsOneWidget,
      );
      final teamCalls = repository.teamStatsCalls;
      repository.playerStatsFail = false;
      await tester.tap(find.byKey(const ValueKey('match_player_stats_retry')));
      await tester.pumpAndSettle();
      expect(find.text('球员 甲'), findsOneWidget);
      expect(find.text('player stats down'), findsNothing);
      expect(repository.teamStatsCalls, teamCalls);
    },
  );

  testWidgets('MATCH-15 simultaneous stats failures recover independently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _DetailRepository()
      ..teamStatsFail = true
      ..playerStatsFail = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match_tab_stats')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('match_team_stats_retry')),
      findsOneWidget,
    );
    repository.teamStatsFail = false;
    await tester.tap(find.byKey(const ValueKey('match_team_stats_retry')));
    await tester.pumpAndSettle();
    expect(find.text('控球率'), findsOneWidget);
    for (
      var i = 0;
      i < 5 &&
          find
              .byKey(const ValueKey('match_player_stats_state'))
              .evaluate()
              .isEmpty;
      i++
    ) {
      await tester.drag(
        find.byKey(const PageStorageKey('match_stats_scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('player stats down'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('match_player_stats_retry')),
      findsOneWidget,
    );
    repository.playerStatsFail = false;
    await tester.ensureVisible(
      find.byKey(const ValueKey('match_player_stats_retry')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match_player_stats_retry')));
    await tester.pumpAndSettle();
    expect(find.text('球员 甲'), findsOneWidget);
    expect(find.text('player stats down'), findsNothing);
  });

  testWidgets(
    'MATCH-16 ratings filters send real team ids and refresh preserves old rows',
    (tester) async {
      final repository = _DetailRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match_tab_ratings')));
      await tester.pumpAndSettle();
      expect(repository.ratingTeamFilters, [null]);
      await tester.tap(find.byKey(const ValueKey('match_ratings_team_40')));
      await tester.pumpAndSettle();
      expect(repository.ratingTeamFilters.last, 40);
      expect(find.byKey(const ValueKey('rating_player_50')), findsOneWidget);
      expect(find.byKey(const ValueKey('rating_player_51')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('match_ratings_team_41')));
      await tester.pumpAndSettle();
      expect(repository.ratingTeamFilters.last, 41);
      expect(find.byKey(const ValueKey('rating_player_51')), findsOneWidget);
      expect(find.byKey(const ValueKey('rating_player_50')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('match_ratings_team_all')));
      await tester.pumpAndSettle();
      expect(repository.ratingTeamFilters.last, isNull);
      expect(find.byKey(const ValueKey('rating_player_50')), findsOneWidget);

      repository.ratingsRefreshFail = true;
      await tester.drag(
        find.byKey(const PageStorageKey('match_ratings_scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rating_player_50')), findsOneWidget);
      expect(find.text('ratings refresh down'), findsOneWidget);
      repository.ratingsRefreshFail = false;
      repository.ratingsVersion = 2;
      await tester.tap(
        find.byKey(const ValueKey('match_ratings_refresh_retry')),
      );
      await tester.pumpAndSettle();
      expect(find.text('球员 甲更新'), findsOneWidget);
      expect(find.text('ratings refresh down'), findsNothing);
    },
  );
}

Widget _app(
  _DetailRepository repository, {
  int matchId = 70,
  RecommendationSourceContext? recommendationSource,
  RecommendationBehaviorDispatcher? dispatcher,
}) {
  final router = GoRouter(
    initialLocation: '/matches/70',
    routes: [
      GoRoute(
        path: '/matches/:id',
        builder: (_, _) => MatchDetailPage(
          matchId: matchId,
          recommendationSource: recommendationSource,
        ),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (_, state) => Text('球员 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/teams/:id',
        builder: (_, state) => Text('球队 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/contents/:id',
        builder: (_, state) => Text('内容 ${state.pathParameters['id']}'),
      ),
      GoRoute(path: '/app/data', builder: (_, _) => const Text('数据入口')),
    ],
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
      ),
      footballRepositoryProvider.overrideWithValue(_BaseRepository(repository)),
      matchDetailRepositoryProvider.overrideWithValue(repository),
      if (dispatcher != null)
        recommendationBehaviorDispatcherProvider.overrideWithValue(dispatcher),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

final class _BaseRepository implements FootballRepositoryContract {
  _BaseRepository(this.value);
  final _DetailRepository value;
  @override
  Future<MatchDetail> matchDetail(int id) async {
    value.baseCalls++;
    if (value.baseRefreshFail && value.baseCalls > 1) {
      throw const NetworkException('base refresh down');
    }
    return _detail;
  }

  @override
  Future<List<League>> leagues() => throw UnimplementedError();
  @override
  Future<FootballPage<FootballMatch>> importantMatches(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<FootballPage<FootballMatch>> followingMatches(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) => throw UnimplementedError();
  @override
  Future<FootballPage<FootballMatch>> teamMatches(int id, int page, int size) =>
      throw UnimplementedError();
  @override
  Future<TeamDetail> teamDetail(int id) => throw UnimplementedError();
  @override
  Future<PlayerDetail> playerDetail(int id) => throw UnimplementedError();
}

final class _RecommendationRepository
    implements RecommendationBehaviorRepositoryContract {
  final events = <RecommendationBehaviorEvent>[];

  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> values,
  ) async {
    events.addAll(values);
    return RecommendationBehaviorBatchResult(
      received: values.length,
      saved: values.length,
      duplicated: 0,
      rejected: 0,
    );
  }
}

final class _DetailRepository implements MatchDetailRepositoryContract {
  bool lineupsFail = false;
  bool lineupsRefreshFail = false;
  int lineupsVersion = 1;
  bool teamStatsFail = false;
  bool playerStatsFail = false;
  bool ratingsFail = false;
  bool ratingsRefreshFail = false;
  int ratingsVersion = 1;
  final ratingTeamFilters = <int?>[];
  bool overviewFail = false;
  int overviewCalls = 0;
  int rankingRank = 1;
  bool baseRefreshFail = false;
  int baseCalls = 0;
  int lineupsCalls = 0;
  int teamStatsCalls = 0;
  int playerStatsCalls = 0;
  int ratingsCalls = 0;
  @override
  Future<MatchOverviewV1> overview(int matchId) async {
    overviewCalls++;
    if (overviewFail) {
      throw const BusinessException('ranking down', code: 4, traceId: null);
    }
    return MatchOverviewV1(
      matchId: 70,
      lineups: _lineups,
      teamStats: const [],
      playerStats: const FootballPage(
        records: [],
        pageNum: 1,
        pages: 0,
        total: 0,
      ),
      ratings: const [],
      ranking: MatchRanking(
        snapshotType: 'CURRENT_STANDING',
        leagueName: '测试联赛',
        seasonName: '2025',
        stageName: '常规赛',
        home: MatchStandingSnapshot(
          teamId: 40,
          teamName: '主队',
          rank: rankingRank,
          played: 10,
          won: 8,
          drawn: 1,
          lost: 1,
          goalsFor: 30,
          goalsAgainst: 8,
          goalDifference: 22,
          points: 25,
        ),
        away: const MatchStandingSnapshot(
          teamId: 41,
          teamName: '客队',
          rank: 2,
          played: 10,
          won: 7,
          drawn: 2,
          lost: 1,
          goalsFor: 22,
          goalsAgainst: 9,
          goalDifference: 13,
          points: 23,
        ),
      ),
    );
  }

  @override
  Future<MatchLineups> lineups(int matchId) async {
    lineupsCalls++;
    if (lineupsFail || lineupsRefreshFail) {
      throw const BusinessException('lineups down', code: 1, traceId: null);
    }
    return lineupsVersion == 1 ? _lineups : _updatedLineups;
  }

  @override
  Future<List<MatchTeamStatItem>> stats(int matchId) async {
    teamStatsCalls++;
    if (teamStatsFail) {
      throw const BusinessException('team stats down', code: 2, traceId: null);
    }
    return const [
      MatchTeamStatItem(
        rawType: 'POSSESSION',
        displayName: '控球率',
        homeValue: 55,
        awayValue: 45,
        unit: '%',
      ),
      MatchTeamStatItem(
        rawType: 'TEXT',
        displayName: '状态描述',
        homeValue: '高压',
        awayValue: null,
      ),
      MatchTeamStatItem(
        rawType: 'NEGATIVE',
        displayName: '净失球',
        homeValue: -1,
        awayValue: 0,
      ),
      MatchTeamStatItem(
        rawType: 'EXTREME',
        displayName: '异常数值',
        homeValue: double.nan,
        awayValue: double.infinity,
        unit: '%',
      ),
    ];
  }

  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size, {
    int? teamId,
    String? position,
  }) async {
    playerStatsCalls++;
    if (playerStatsFail) {
      throw const BusinessException(
        'player stats down',
        code: 5,
        traceId: null,
      );
    }
    final values = const [
      MatchPlayerStat(
        playerId: 50,
        playerName: '球员 甲',
        teamId: 40,
        teamName: '主队',
        position: 'FORWARD',
        minutes: 90,
        goals: 1,
        assists: 1,
        passes: 40,
        successfulPasses: 35,
        passAccuracy: 88.5,
        officialRating: 8.0,
      ),
      MatchPlayerStat(
        playerId: 51,
        playerName: '球员 乙',
        teamId: 41,
        teamName: '客队',
        position: 'MIDFIELDER',
        minutes: 80,
        shots: 2,
        shotsOnTarget: 1,
      ),
    ];
    final filtered = values
        .where(
          (value) =>
              (teamId == null || value.teamId == teamId) &&
              (position == null || value.position == position),
        )
        .toList();
    return FootballPage(
      records: filtered,
      pageNum: page,
      pages: 1,
      total: filtered.length,
    );
  }

  @override
  Future<List<MatchRatingSummary>> ratings(int matchId, {int? teamId}) async {
    ratingsCalls++;
    ratingTeamFilters.add(teamId);
    if (ratingsFail) {
      throw const BusinessException('ratings down', code: 3, traceId: null);
    }
    if (ratingsRefreshFail) {
      throw const BusinessException(
        'ratings refresh down',
        code: 3,
        traceId: null,
      );
    }
    final firstName = ratingsVersion == 1 ? '球员 甲' : '球员 甲更新';
    final secondName = ratingsVersion == 1 ? '球员 乙' : '球员 乙更新';
    return [
      MatchRatingSummary(
        playerId: 50,
        playerName: firstName,
        teamId: 40,
        officialRating: 8,
        averageRating: 8.5,
        ratingCount: 3,
        currentUserRating: 7.5,
        distribution: {'8.5-10.0': 2},
      ),
      if (teamId == null || teamId == 41)
        MatchRatingSummary(
          playerId: 51,
          playerName: secondName,
          teamId: 41,
          officialRating: 7.2,
        ),
    ].where((value) => teamId == null || value.teamId == teamId).toList();
  }

  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) async => MatchRatingResult(
    matchId: matchId,
    playerId: playerId,
    myRating: rating,
    averageRating: rating,
    ratingCount: 4,
  );
  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) async =>
      MatchRatingResult(matchId: matchId, playerId: playerId);
}

const _lineups = MatchLineups(
  home: MatchTeamLineup(
    teamId: 40,
    teamName: '切尔西测试长名称',
    formation: '4-3-3',
    starters: [
      MatchLineupPlayer(
        playerId: 50,
        playerName: '球员 甲',
        position: 'FORWARD',
        shirtNumber: 9,
        started: true,
        captain: true,
      ),
    ],
    substitutes: [
      MatchLineupPlayer(
        playerId: 51,
        playerName: '球员 乙',
        position: 'MIDFIELDER',
        shirtNumber: 8,
      ),
    ],
    bench: [MatchLineupPlayer(playerId: 51, playerName: '球员 乙重复')],
  ),
  away: MatchTeamLineup(
    teamId: 41,
    teamName: '莱斯特测试长名称',
    starters: [MatchLineupPlayer(playerId: 52, playerName: '球员 丙')],
  ),
);

const _updatedLineups = MatchLineups(
  home: MatchTeamLineup(
    teamId: 40,
    teamName: '主队更新',
    formation: '3-5-2',
    starters: [MatchLineupPlayer(playerId: 50, playerName: '球员 甲更新')],
  ),
  away: MatchTeamLineup(
    teamId: 41,
    teamName: '客队更新',
    starters: [MatchLineupPlayer(playerId: 52, playerName: '球员 丙')],
  ),
);

final _detail = MatchDetail(
  match: FootballMatch(
    id: 70,
    leagueId: 10,
    leagueName: '测试联赛',
    homeTeam: const FootballTeam(id: 40, name: '切尔西测试长名称', score: 2),
    awayTeam: const FootballTeam(id: 41, name: '莱斯特测试长名称', score: 1),
    status: 'FINISHED',
    matchTime: DateTime(2026, 5, 21, 3, 30),
  ),
  roundName: '半决赛',
  events: const [
    MatchEvent(
      id: 73,
      type: 'UNKNOWN_EVENT',
      minute: 12,
      teamId: 0,
      teamName: '未知球队',
      playerId: 0,
      playerName: '未知球员',
      assistPlayerId: 0,
      assistPlayerName: '未知助攻',
    ),
    MatchEvent(
      id: 72,
      type: 'UNKNOWN_EVENT',
      minute: 10,
      extraMinute: 2,
      teamId: 41,
      teamName: '莱斯特测试长名称',
      playerId: 51,
      playerName: '球员 乙',
      assistPlayerId: 50,
      assistPlayerName: '球员 甲',
      period: '下半场',
    ),
    MatchEvent(
      id: 71,
      type: 'GOAL',
      minute: 10,
      teamId: 40,
      teamName: '切尔西测试长名称',
      playerId: 50,
      playerName: '球员 甲',
      scoreAfter: '1:0',
    ),
  ],
  report: const MatchReport(contentId: 80, title: '比赛战报'),
);
