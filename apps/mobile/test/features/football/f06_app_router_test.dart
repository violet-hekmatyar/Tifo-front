import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/pages/match_detail_page.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';

void main() {
  testWidgets(
    'real app router opens match detail above shell and preserves data',
    (tester) async {
      final auth = AuthController(_ReadyAuthRepository());
      await auth.initialize();
      final router = createAppRouter(auth)..go('/app/data');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            footballRepositoryProvider.overrideWithValue(
              _RouterFootballRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('重要'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('schedule_match_50001')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchDetailPage), findsOneWidget);
      expect(find.text('比赛详情'), findsOneWidget);
      expect(find.text('南看台'), findsNothing);

      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/app/data');
      expect(find.text('重要'), findsOneWidget);
    },
  );

  testWidgets('match teams and real event player use root detail routes', (
    tester,
  ) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/matches/50001');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          footballRepositoryProvider.overrideWithValue(
            _RouterFootballRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match_team_30001')));
    await tester.pumpAndSettle();
    expect(find.byType(TeamDetailPage), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailPage), findsOneWidget);

    await tester.tap(find.byTooltip('查看球员详情'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerDetailPage), findsOneWidget);
  });

  testWidgets('invalid match id stays on an explicit error page', (
    tester,
  ) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/matches/not-a-number');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          footballRepositoryProvider.overrideWithValue(
            _RouterFootballRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/matches/not-a-number',
    );
    expect(find.text('比赛编号无效'), findsOneWidget);
    expect(find.text('南看台'), findsNothing);
  });
}

const _user = AuthUser(
  id: 1,
  username: 'ready',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

final class _ReadyAuthRepository implements AuthRepositoryContract {
  @override
  Future<AuthUser> currentUser() async => _user;
  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => _user;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => _user;
  @override
  Future<AuthUser> restore() async => _user;
  @override
  Future<String?> storedToken() async => 'stored';
}

final class _RouterFootballRepository implements FootballRepositoryContract {
  @override
  Future<List<League>> leagues() async => const [
    League(id: 10003, name: '测试联赛'),
  ];
  @override
  Future<FootballPage<FootballMatch>> importantMatches(
    int page,
    int size,
  ) async => _page;
  @override
  Future<FootballPage<FootballMatch>> followingMatches(
    int page,
    int size,
  ) async => _page;
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) async => _page;
  @override
  Future<FootballPage<FootballMatch>> teamMatches(
    int id,
    int page,
    int size,
  ) async => _page;
  @override
  Future<MatchDetail> matchDetail(int id) async => MatchDetail(
    match: _match,
    events: const [
      MatchEvent(
        id: 1,
        type: 'GOAL',
        minute: 12,
        playerId: 40001,
        playerName: '真实球员',
      ),
    ],
  );
  @override
  Future<TeamDetail> teamDetail(int id) async => TeamDetail(
    id: id,
    name: '测试球队',
    followed: false,
    followerCount: 0,
    recentMatches: const [],
    upcomingMatches: const [],
  );
  @override
  Future<PlayerDetail> playerDetail(int id) async => const PlayerDetail(
    id: 40001,
    name: '真实球员',
    retired: false,
    followed: false,
    followerCount: 0,
    team: PlayerTeam(id: 30001, name: '测试球队'),
  );
}

final _match = FootballMatch(
  id: 50001,
  leagueId: 10003,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 30001, name: '主队'),
  awayTeam: const FootballTeam(id: 30002, name: '客队'),
  status: 'SCHEDULED',
  matchTime: DateTime(2026, 7, 18, 20),
);
final _page = FootballPage<FootballMatch>(
  records: [_match],
  pageNum: 1,
  pages: 1,
  total: 1,
);
