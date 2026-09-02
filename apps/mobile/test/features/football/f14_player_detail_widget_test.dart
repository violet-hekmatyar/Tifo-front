import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/player_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/player_detail_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';

void main() {
  testWidgets('player tabs use real models and navigate to related entities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/players/50',
      routes: [
        GoRoute(
          path: '/players/:id',
          builder: (_, state) => PlayerDetailPage(
            playerId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/teams/:id',
          builder: (_, state) => Text('球队 ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/matches/:id',
          builder: (_, state) => Text('比赛 ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/contents/:id',
          builder: (_, state) => Text('内容 ${state.pathParameters['id']}'),
        ),
        GoRoute(path: '/app/data', builder: (_, _) => const Text('数据入口')),
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
          playerDetailRepositoryProvider.overrideWithValue(_PlayerRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无国家队信息'), findsOneWidget);
    expect(find.textContaining('后端尚未提供'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player_team_40')));
    await tester.pumpAndSettle();
    expect(find.text('球队 40'), findsOneWidget);

    router.go('/players/50');
    await tester.pumpAndSettle();
    await tester.tap(find.text('动态'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('player_content_80')));
    await tester.pumpAndSettle();
    expect(find.text('内容 80'), findsOneWidget);

    router.go('/players/50');
    await tester.pumpAndSettle();
    await tester.tap(find.text('比赛'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule_match_70')));
    await tester.pumpAndSettle();
    expect(find.text('比赛 70'), findsOneWidget);

    router.go('/players/50');
    await tester.pumpAndSettle();
    await tester.tap(find.text('生涯'));
    await tester.pumpAndSettle();
    expect(find.text('效力球队'), findsOneWidget);
  });
}

final class _BaseRepository implements FootballRepositoryContract {
  @override
  Future<PlayerDetail> playerDetail(int id) async => const PlayerDetail(
    id: 50,
    name: '测试球员',
    retired: false,
    followed: false,
    followerCount: 2,
    position: 'FW',
  );
  @override
  Future<TeamDetail> teamDetail(int id) => throw UnimplementedError();
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
}

final class _PlayerRepository implements PlayerDetailRepositoryContract {
  @override
  Future<PlayerOverview> overview(int playerId, {int? seasonId}) async =>
      const PlayerOverview(
        id: 50,
        name: '测试球员',
        retired: false,
        club: PlayerTeamLink(id: 40, name: '测试球队'),
      );
  @override
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  }) async => const [
    PlayerSeasonStats(leagueName: '测试联赛', appearances: 12, goals: 3),
  ];
  @override
  Future<List<PlayerTeamHistory>> teams(int playerId) async => const [
    PlayerTeamHistory(
      teamId: 40,
      teamName: '测试球队',
      current: true,
      appearances: 12,
    ),
  ];
  @override
  Future<PlayerCareer> career(int playerId) async =>
      const PlayerCareer(totalAppearances: 12, totalGoals: 3, teamCount: 1);
  @override
  Future<FootballPage<FootballMatch>> matches(
    int playerId,
    int page,
    int size,
  ) async => FootballPage(records: [_match], pageNum: 1, pages: 1, total: 1);
  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId,
    int page,
    int size,
  ) async => const FootballPage(
    records: [TeamContentSummary(id: 80, title: '球员动态', rawType: 'REPORT')],
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
