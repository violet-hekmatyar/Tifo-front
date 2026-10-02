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
import 'package:tifo/features/football/presentation/pages/knockout_tree_placeholder_page.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/pages/followed_entities_page.dart';
import 'package:tifo/features/user_center/presentation/pages/my_profile_page.dart';

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
      expect(find.byKey(const ValueKey('match_header')), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('event_player_1')));
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

  testWidgets('knockout tree entry opens an honest placeholder', (
    tester,
  ) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/football/knockout-tree');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KnockoutTreePlaceholderPage), findsOneWidget);
    expect(find.text('淘汰树正在开发'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('页面不存在'), findsNothing);
  });

  testWidgets(
    'authenticated profile opens followed players and returns to profile',
    (tester) async {
      final auth = AuthController(_ReadyAuthRepository());
      await auth.initialize();
      final router = createAppRouter(auth)..go('/app/profile');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            footballRepositoryProvider.overrideWithValue(
              _RouterFootballRepository(),
            ),
            userCenterRepositoryProvider.overrideWithValue(
              _RouterUserCenterRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/app/profile');
      expect(find.byType(MyProfilePage), findsOneWidget);
      expect(find.text('看台'), findsOneWidget);
      expect(find.text('我关注的球队'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('my_stand_scroll')),
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
      expect(find.text('我关注的球星'), findsOneWidget);

      await tester.tap(find.text('我关注的球星'));
      await tester.pumpAndSettle();
      expect(find.byType(FollowedEntitiesPage), findsOneWidget);
      expect(find.text('关注的球员'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePage), findsOneWidget);
      expect(find.text('看台'), findsOneWidget);
    },
  );
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

final class _RouterUserCenterRepository
    implements UserCenterRepositoryContract {
  @override
  Future<MySummary> summary() async => const MySummary(
        userId: 1,
        username: 'ready',
        nickname: '就绪用户',
        bio: null,
        mainTeam: null,
        postCount: 0,
        favoriteCount: 0,
        commentCount: 0,
        followingCount: 0,
        followerCount: 0,
        teamFollowCount: 1,
        playerFollowCount: 1,
        avatarUrl: null,
      );
  @override
  Future<UserStand> stand() async => const UserStand(
        teams: [EntityBrief(id: 40, name: '测试球队')],
        players: [EntityBrief(id: 50, name: '测试球员')],
      );
  @override
  Future<UserProfile> profile(int userId) async =>
      throw UnimplementedError();
  @override
  Future<void> updateProfile({
    required String nickname,
    required String bio,
  }) async {}
  @override
  Future<void> setMainTeam(int teamId) async {}
  @override
  Future<UserProfile> follow(int userId, bool follow) async =>
      throw UnimplementedError();
  @override
  Future<bool> toggleEntity(String type, int id) async => false;
  @override
  Future<void> removeFavorite(int contentId) async {}
  @override
  Future<void> deleteComment(int commentId) async {}
  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) async =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) async =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) async =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) async =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) async => throw UnimplementedError();
  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) async => throw UnimplementedError();
  @override
  Future<UserPage<UserCommentItem>> userComments(
    int userId,
    int page,
    int size,
  ) async => throw UnimplementedError();
  @override
  Future<String> bindAvatar(int fileId) async => '';
  @override
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) async =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) async =>
      throw UnimplementedError();
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
