import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/match_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/match_detail_page.dart';

void main() {
  testWidgets('five real match tabs render and player links navigate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/matches/70',
      routes: [
        GoRoute(
          path: '/matches/:id',
          builder: (_, state) =>
              MatchDetailPage(matchId: int.parse(state.pathParameters['id']!)),
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
    addTearDown(router.dispose);
    final matchRepository = _MatchRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          footballRepositoryProvider.overrideWithValue(_BaseRepository()),
          matchDetailRepositoryProvider.overrideWithValue(matchRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('比赛事件'), findsOneWidget);
    expect(find.text('进球 · 1:0'), findsOneWidget);
    expect(find.text('比赛战报'), findsOneWidget);
    expect(find.textContaining('后端尚未提供'), findsNothing);

    await tester.tap(find.text('阵容'));
    await tester.pumpAndSettle();
    expect(find.text('首发'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lineup_player_50')));
    await tester.pumpAndSettle();
    expect(find.text('球员 50'), findsOneWidget);

    router.go('/matches/70');
    await tester.pumpAndSettle();
    await tester.tap(find.text('当前排名'));
    await tester.pumpAndSettle();
    expect(find.text('当前排名'), findsWidgets);
    expect(find.textContaining('赛前排名'), findsNothing);

    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    expect(find.text('控球率'), findsOneWidget);

    await tester.tap(find.text('评分'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rate_player_50')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rate_player_50')));
    await tester.pumpAndSettle();
    expect(find.text('7.5'), findsOneWidget);
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    expect(matchRepository.lastSubmitted, 7.5);
  });
}

final class _BaseRepository implements FootballRepositoryContract {
  @override
  Future<MatchDetail> matchDetail(int id) async => MatchDetail(
    match: _match,
    events: const [
      MatchEvent(
        id: 71,
        type: 'GOAL',
        minute: 10,
        playerId: 50,
        playerName: '测试球员',
        scoreAfter: '1:0',
      ),
    ],
    report: const MatchReport(contentId: 80, title: '比赛战报'),
  );
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

final class _MatchRepository implements MatchDetailRepositoryContract {
  double? lastSubmitted;
  @override
  Future<MatchOverviewV1> overview(int matchId) async => MatchOverviewV1(
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
    ranking: const MatchRanking(
      snapshotType: 'CURRENT_STANDING',
      leagueName: '测试联赛',
      home: MatchStandingSnapshot(
        teamId: 40,
        teamName: '主队',
        rank: 1,
        played: 10,
        points: 25,
      ),
      away: MatchStandingSnapshot(
        teamId: 41,
        teamName: '客队',
        rank: 2,
        played: 10,
        points: 22,
      ),
    ),
  );
  @override
  Future<MatchLineups> lineups(int matchId) async => _lineups;
  @override
  Future<List<MatchTeamStatItem>> stats(int matchId) async => const [
    MatchTeamStatItem(
      rawType: 'POSSESSION',
      displayName: '控球率',
      homeValue: 55,
      awayValue: 45,
      unit: '%',
    ),
  ];
  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size,
  ) async => const FootballPage(
    records: [
      MatchPlayerStat(
        playerId: 50,
        playerName: '测试球员',
        teamId: 40,
        teamName: '主队',
        officialRating: 7.4,
      ),
    ],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
  @override
  Future<List<MatchRatingSummary>> ratings(int matchId) async => const [
    MatchRatingSummary(
      playerId: 50,
      playerName: '测试球员',
      teamId: 40,
      officialRating: 7.5,
    ),
  ];
  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) async {
    lastSubmitted = rating;
    return MatchRatingResult(
      matchId: matchId,
      playerId: playerId,
      myRating: rating,
      averageRating: rating,
      ratingCount: 1,
    );
  }

  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) async =>
      MatchRatingResult(matchId: matchId, playerId: playerId);
}

const _lineups = MatchLineups(
  home: MatchTeamLineup(
    teamId: 40,
    teamName: '主队',
    starters: [MatchLineupPlayer(playerId: 50, playerName: '测试球员')],
  ),
  away: MatchTeamLineup(teamId: 41, teamName: '客队'),
);
final _match = FootballMatch(
  id: 70,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 40, name: '主队', score: 2),
  awayTeam: const FootballTeam(id: 41, name: '客队', score: 1),
  status: 'FINISHED',
  matchTime: DateTime(2026, 1, 1),
);
