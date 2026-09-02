import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/team_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';

void main() {
  testWidgets('real team tabs replace placeholders and navigate', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/teams/40',
      routes: [
        GoRoute(
          path: '/teams/:id',
          builder: (_, state) =>
              TeamDetailPage(teamId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/players/:id',
          builder: (_, state) => Text('球员 ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/matches/:id',
          builder: (_, state) => Text('比赛 ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/contents/:id',
          builder: (_, state) => Text('内容 ${state.pathParameters['id']}'),
        ),
        GoRoute(path: '/app/data', builder: (_, _) => const Text('数据')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          footballRepositoryProvider.overrideWithValue(_BaseRepository()),
          teamDetailRepositoryProvider.overrideWithValue(_TeamRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前排名'), findsOneWidget);
    expect(find.text('测试冠军'), findsOneWidget);
    expect(find.textContaining('当前后端尚未提供'), findsNothing);

    await tester.tap(find.text('球员'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('team_player_50')));
    await tester.pumpAndSettle();
    expect(find.text('球员 50'), findsOneWidget);

    router.go('/teams/40');
    await tester.pumpAndSettle();
    await tester.tap(find.text('动态'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('team_content_80')));
    await tester.pumpAndSettle();
    expect(find.text('内容 80'), findsOneWidget);

    router.go('/teams/40');
    await tester.pumpAndSettle();
    await tester.tap(find.text('赛程'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule_match_70')));
    await tester.pumpAndSettle();
    expect(find.text('比赛 70'), findsOneWidget);
  });
}

final class _BaseRepository implements FootballRepositoryContract {
  @override
  Future<TeamDetail> teamDetail(int id) async => const TeamDetail(
    id: 40,
    name: '测试球队',
    followed: false,
    followerCount: 3,
    recentMatches: [],
    upcomingMatches: [],
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
  Future<MatchDetail> matchDetail(int id) => throw UnimplementedError();
  @override
  Future<PlayerDetail> playerDetail(int id) => throw UnimplementedError();
}

final class _TeamRepository implements TeamDetailRepositoryContract {
  @override
  Future<TeamOverview> overview(int teamId, {int? seasonId}) async =>
      const TeamOverview(
        teamId: 40,
        teamName: '测试球队',
        leagueName: '测试联赛',
        seasonName: '当前赛季',
        standing: TeamStandingSummary(rank: 1, points: 20),
      );
  @override
  Future<List<TeamHonor>> honors(int teamId) async => const [
    TeamHonor(id: 60, name: '测试冠军', titleCount: 1),
  ];
  @override
  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId}) async =>
      const TeamStats(played: 10, standingRank: 1, points: 20);
  @override
  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId,
    int page,
    int size, {
    int? seasonId,
  }) async => const FootballPage(
    records: [
      TeamRosterPlayer(
        id: 50,
        name: '测试球员',
        position: 'FORWARD',
        squadRole: 'FIRST_TEAM',
      ),
    ],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
  @override
  Future<FootballPage<FootballMatch>> matches(
    int teamId,
    int page,
    int size,
  ) async => FootballPage(records: [_match], pageNum: 1, pages: 1, total: 1);
  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int teamId,
    int page,
    int size,
  ) async => const FootballPage(
    records: [TeamContentSummary(id: 80, title: '球队动态', rawType: 'ARTICLE')],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
}

final _match = FootballMatch(
  id: 70,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 40, name: '测试球队'),
  awayTeam: const FootballTeam(id: 41, name: '对手'),
  status: 'SCHEDULED',
  matchTime: DateTime(2026, 1, 1),
);
