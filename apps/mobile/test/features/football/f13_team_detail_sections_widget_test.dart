import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/team_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';

void main() {
  testWidgets(
    'TEAM-07 TEAM-09 TEAM-11 TEAM-16 sections render and keep loaded tabs',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = _TeamFake();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
            footballRepositoryProvider.overrideWithValue(_FootballFake()),
            teamDetailRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: TeamDetailPage(teamId: 40)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('队内榜单'), findsOneWidget);
      expect(find.text('射手榜'), findsOneWidget);
      expect(find.text('助攻榜'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('team_tab_contents')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('team_content_80')), findsOneWidget);
      expect(find.byKey(const ValueKey('team_content_81')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('team_tab_players')));
      await tester.pumpAndSettle();
      expect(find.text('门将'), findsOneWidget);
      expect(find.text('前锋'), findsOneWidget);
      expect(find.textContaining('队长'), findsOneWidget);
      expect(find.textContaining('进球 8'), findsOneWidget);
      expect(find.text('位置未定'), findsOneWidget);
      expect(find.textContaining('其他角色'), findsOneWidget);
      expect(find.textContaining('租借'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('team_player_0')))
            .onTap,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('team_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('净胜球'), findsOneWidget);
      expect(find.text('射正率'), findsOneWidget);
      expect(find.text('52.5%'), findsOneWidget);
      expect(find.text('第 2 名'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('team_tab_contents')));
      await tester.pumpAndSettle();
      expect(repository.contentsCalls, 1);
      expect(find.byKey(const ValueKey('team_content_80')), findsOneWidget);

      final contentsList = find.byKey(const PageStorageKey('team_动态'));
      final scrollableFinder = find.descendant(
        of: contentsList,
        matching: find.byType(Scrollable),
      );
      final scrollable = tester.state<ScrollableState>(scrollableFinder);
      final initialContentOffset = scrollable.position.pixels;
      await tester.drag(contentsList, const Offset(0, -500));
      await tester.pumpAndSettle();
      final offsetBeforeSwitch = scrollable.position.pixels;
      expect(offsetBeforeSwitch, greaterThan(initialContentOffset));
      await tester.tap(find.byKey(const ValueKey('team_tab_players')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('team_tab_contents')));
      await tester.pumpAndSettle();
      final offsetAfterSwitch = scrollable.position.pixels;
      expect(offsetAfterSwitch, closeTo(offsetBeforeSwitch, 1));
      expect(repository.playersCalls, 1);
      expect(repository.matchesCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VR4-R1 data selector and leaderboard page expose real controls',
    (tester) async {
      await tester.pumpWidget(_teamApp(_TeamFake()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('查看全部').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('team_leaderboard_back')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('team_leaderboard_season')),
        findsOneWidget,
      );
      expect(find.text('射手榜'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('team_leaderboard_back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('team_tab_stats')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('team_stats_selector')));
      await tester.pumpAndSettle();
      expect(find.text('2026 赛季'), findsWidgets);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('TEAM-02 header exposes only the main-team action', (
    tester,
  ) async {
    final user = _UserFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          footballRepositoryProvider.overrideWithValue(_FootballFake()),
          teamDetailRepositoryProvider.overrideWithValue(_TeamFake()),
          userCenterRepositoryProvider.overrideWithValue(user),
        ],
        child: const MaterialApp(home: TeamDetailPage(teamId: 40)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team_main')), findsOneWidget);
    expect(find.text('加为主队'), findsOneWidget);
    expect(find.byKey(const ValueKey('team_follow')), findsNothing);
    expect(user.toggleCalls, 0);
  });

  testWidgets('VR4-R2 main-team success requires authoritative readback', (
    tester,
  ) async {
    final auth = AuthController(_AuthRepository());
    await auth.login(username: 'user', password: 'password');
    final user = _UserFake()
      ..summaryResult = const MySummary(
        userId: 1,
        username: 'user',
        nickname: '用户',
        postCount: 0,
        favoriteCount: 0,
        commentCount: 0,
        followingCount: 0,
        followerCount: 0,
        teamFollowCount: 0,
        playerFollowCount: 0,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          authControllerProvider.overrideWith((_) => auth),
          footballRepositoryProvider.overrideWithValue(_FootballFake()),
          teamDetailRepositoryProvider.overrideWithValue(_TeamFake()),
          userCenterRepositoryProvider.overrideWithValue(user),
        ],
        child: const MaterialApp(home: TeamDetailPage(teamId: 40)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('team_main')));
    await tester.pumpAndSettle();
    expect(find.text('服务端未确认主队设置，请重试'), findsOneWidget);
    expect(find.text('已设为主队'), findsNothing);
    expect(find.text('加为主队'), findsOneWidget);
    expect(user.setMainTeamCalls, 1);

    user.summaryResult = const MySummary(
      userId: 1,
      username: 'user',
      nickname: '用户',
      postCount: 0,
      favoriteCount: 0,
      commentCount: 0,
      followingCount: 0,
      followerCount: 0,
      teamFollowCount: 0,
      playerFollowCount: 0,
      mainTeam: EntityBrief(id: 40, name: '测试球队'),
    );
    await tester.tap(find.byKey(const ValueKey('team_main')));
    await tester.pumpAndSettle();
    expect(find.text('已是主队'), findsOneWidget);
    expect(user.setMainTeamCalls, 2);
    await tester.tap(find.byKey(const ValueKey('team_main')));
    await tester.pumpAndSettle();
    expect(user.setMainTeamCalls, 2);
  });

  testWidgets('TEAM-02 invalid team keeps main-team action disabled', (
    tester,
  ) async {
    final user = _UserFake();
    await tester.pumpWidget(_teamApp(_TeamFake(), user: user));
    await tester.pumpAndSettle();

    final invalidUser = _UserFake();
    await tester.pumpWidget(
      _teamApp(
        _TeamFake(),
        football: const _FootballFake(returnedId: 0),
        user: invalidUser,
      ),
    );
    await tester.pumpAndSettle();
    final mainTeam = tester.widget<FilledButton>(
      find.byKey(const ValueKey('team_main')),
    );
    expect(mainTeam.onPressed, isNull);
    expect(invalidUser.toggleCalls, 0);
  });

  testWidgets('TEAM-05 honors error retries in place', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _TeamFake()..honorsFail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          footballRepositoryProvider.overrideWithValue(_FootballFake()),
          teamDetailRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: TeamDetailPage(teamId: 40)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('荣誉加载失败，点击重试'), findsOneWidget);
    repository.honorsFail = false;
    await tester.tap(find.text('荣誉加载失败，点击重试'));
    await tester.pumpAndSettle();
    expect(find.text('测试冠军'), findsOneWidget);
    expect(repository.honorsCalls, greaterThanOrEqualTo(2));
  });

  testWidgets(
    'TEAM-03 detail recommendation is sent once across tab rebuilds',
    (tester) async {
      final recommendation = _RecommendationFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
            footballRepositoryProvider.overrideWithValue(_FootballFake()),
            teamDetailRepositoryProvider.overrideWithValue(_TeamFake()),
            recommendationBehaviorRepositoryProvider.overrideWithValue(
              recommendation,
            ),
          ],
          child: const MaterialApp(
            home: TeamDetailPage(
              teamId: 40,
              recommendationSource: RecommendationSourceContext(
                targetType: RecommendationTargetType.content,
                targetId: 80,
                attribution: RecommendationAttribution(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('team_tab_contents')));
      await tester.tap(find.byKey(const ValueKey('team_tab_stats')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(recommendation.batches.expand((batch) => batch).length, 1);
    },
  );

  testWidgets('TEAM-07 masonry and TEAM-14 ready refresh failure recover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _TeamFake()..contentsRefreshFail = true;
    await tester.pumpWidget(_teamApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team_tab_contents')));
    await tester.pumpAndSettle();

    final first = tester.getSize(find.byKey(const ValueKey('team_content_80')));
    final second = tester.getSize(
      find.byKey(const ValueKey('team_content_81')),
    );
    expect(first.width, second.width);
    expect(first.height, isNot(second.height));

    await tester.drag(
      find.byKey(const PageStorageKey('team_动态')),
      const Offset(0, 420),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsOneWidget);
    expect(find.byKey(const ValueKey('team_content_80')), findsOneWidget);

    repository.contentsRefreshFail = false;
    await tester.tap(find.widgetWithText(TextButton, '重试'));
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsNothing);
  });

  testWidgets('TEAM-14 unknown-date matches render one date placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _TeamFake()..includeNoDateMatches = true;
    await tester.pumpWidget(_teamApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team_tab_matches')));
    await tester.pumpAndSettle();
    expect(find.text('日期待定'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule_match_90')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule_match_91')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _teamApp(
  _TeamFake repository, {
  FootballRepositoryContract? football,
  UserCenterRepositoryContract? user,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    footballRepositoryProvider.overrideWithValue(
      football ?? const _FootballFake(),
    ),
    teamDetailRepositoryProvider.overrideWithValue(repository),
    if (user != null) userCenterRepositoryProvider.overrideWithValue(user),
  ],
  child: const MaterialApp(home: TeamDetailPage(teamId: 40)),
);

final class _UserFake implements UserCenterRepositoryContract {
  final result = Completer<bool>();
  int toggleCalls = 0;
  int setMainTeamCalls = 0;
  bool fail = false;
  MySummary? summaryResult;

  @override
  Future<bool> toggleEntity(String type, int id) {
    toggleCalls++;
    if (fail) return Future<bool>.error(const NetworkException('toggle down'));
    return result.future;
  }

  @override
  Future<MySummary> summary() async =>
      summaryResult ?? (throw UnimplementedError());
  @override
  Future<UserStand> stand() => throw UnimplementedError();
  @override
  Future<UserProfile> profile(int userId) => throw UnimplementedError();
  @override
  Future<void> updateProfile({required String nickname, required String bio}) =>
      throw UnimplementedError();
  @override
  Future<void> setMainTeam(int teamId) async => setMainTeamCalls++;
  @override
  Future<UserProfile> follow(int userId, bool follow) =>
      throw UnimplementedError();
  @override
  Future<void> removeFavorite(int contentId) => throw UnimplementedError();
  @override
  Future<void> deleteComment(int commentId) => throw UnimplementedError();
  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();
  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();
  @override
  Future<UserPage<UserCommentItem>> userComments(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();
  @override
  Future<String> bindAvatar(int fileId) => throw UnimplementedError();
  @override
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) =>
      throw UnimplementedError();
}

final class _RecommendationFake
    implements RecommendationBehaviorRepositoryContract {
  final batches = <List<RecommendationBehaviorEvent>>[];

  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> events,
  ) async {
    batches.add(events);
    return RecommendationBehaviorBatchResult(
      received: events.length,
      saved: events.length,
      duplicated: 0,
      rejected: 0,
    );
  }
}

final class _FootballFake implements FootballRepositoryContract {
  const _FootballFake({this.returnedId = 40});
  final int returnedId;

  @override
  Future<TeamDetail> teamDetail(int id) async => TeamDetail(
    id: returnedId,
    name: '测试球队',
    followed: false,
    followerCount: 2,
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

final class _TeamFake implements TeamDetailRepositoryContract {
  int contentsCalls = 0;
  int honorsCalls = 0;
  int playersCalls = 0;
  int matchesCalls = 0;
  bool honorsFail = false;
  bool contentsRefreshFail = false;
  bool includeNoDateMatches = false;

  @override
  Future<TeamOverview> overview(
    int teamId, {
    int? seasonId,
  }) async => TeamOverview(
    teamId: 40,
    teamName: '测试球队',
    leagueName: '测试联赛',
    seasonName: '2026 赛季',
    standing: const TeamStandingSummary(rank: 2, points: 20),
    competitionStandings: const [
      TeamCompetitionStanding(
        leagueId: 10,
        leagueName: '测试联赛',
        seasonId: 20,
        seasonName: '2026 赛季',
        stageId: 30,
        rank: 2,
        points: 20,
      ),
    ],
    leaderboards: const [
      TeamLeaderboard(
        rankType: 'GOALS',
        title: '射手榜',
        players: [
          TeamRosterPlayer(id: 50, name: '射手', position: 'FORWARD', goals: 8),
        ],
      ),
      TeamLeaderboard(
        rankType: 'ASSISTS',
        title: '助攻榜',
        players: [
          TeamRosterPlayer(
            id: 51,
            name: '助攻手',
            position: 'MIDFIELDER',
            assists: 5,
          ),
        ],
      ),
    ],
    topScorers: const [
      TeamRosterPlayer(id: 50, name: '射手', position: 'FORWARD', goals: 8),
    ],
    topAssists: const [
      TeamRosterPlayer(id: 51, name: '助攻手', position: 'MIDFIELDER', assists: 5),
    ],
  );

  @override
  Future<List<TeamHonor>> honors(int teamId) async {
    honorsCalls++;
    if (honorsFail) throw const NetworkException('honors down');
    return const [TeamHonor(id: 60, name: '测试冠军', titleCount: 1)];
  }

  @override
  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId}) async =>
      TeamStats(
        played: 10,
        goalsFor: 0,
        goalsAgainst: 9,
        goalDifference: -9,
        assists: 4,
        shots: 12,
        shotsOnTarget: 6,
        standingRank: 2,
        points: 20,
        shotAccuracy: 52.5,
        corners: 0,
        fouls: 15,
        yellowCards: 2,
        redCards: 0,
        cleanSheets: 3,
        averageRating: double.infinity,
      );

  @override
  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId,
    int page,
    int size, {
    int? seasonId,
  }) async {
    playersCalls++;
    return const FootballPage(
      records: [
        TeamRosterPlayer(id: 52, name: '门将球员', position: 'GOALKEEPER'),
        TeamRosterPlayer(
          id: 53,
          name: '前锋球员',
          position: 'FORWARD',
          captain: true,
          goals: 8,
        ),
        TeamRosterPlayer(
          id: 0,
          name: '未知球员的超长显示名称',
          position: null,
          squadRole: 'UNKNOWN_ROLE',
          loan: true,
        ),
      ],
      pageNum: 1,
      pages: 1,
      total: 2,
    );
  }

  @override
  Future<FootballPage<FootballMatch>> matches(
    int teamId,
    int page,
    int size,
  ) async {
    matchesCalls++;
    return includeNoDateMatches
        ? FootballPage(
            records: [_noDateMatch(90), _noDateMatch(91)],
            pageNum: 1,
            pages: 1,
            total: 2,
          )
        : const FootballPage(records: [], pageNum: 1, pages: 1, total: 0);
  }

  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int teamId,
    int page,
    int size,
  ) async {
    contentsCalls++;
    if (contentsRefreshFail && contentsCalls > 1) {
      throw const NetworkException('refresh down');
    }
    return FootballPage(
      records: [
        TeamContentSummary(
          id: 80,
          title: '动态一',
          rawType: 'POST',
          summary: '这是一段较长的动态摘要，用于验证内容卡片拥有独立的自然高度。',
        ),
        TeamContentSummary(id: 81, title: '动态二', rawType: 'ARTICLE'),
        for (var id = 82; id < 92; id++)
          TeamContentSummary(
            id: id,
            title: '动态$id',
            rawType: id.isEven ? 'POST' : 'ARTICLE',
            summary: '用于验证分页内容滚动位置恢复的较长摘要。',
          ),
      ],
      pageNum: 1,
      pages: 1,
      total: 12,
    );
  }
}

final class _AuthRepository implements AuthRepositoryContract {
  static const _user = AuthUser(
    id: 1,
    username: 'user',
    roleType: 'USER',
    status: 'ACTIVE',
    onboardingCompleted: true,
  );

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
  Future<String?> storedToken() async => null;
}

FootballMatch _noDateMatch(int id) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 40, name: '测试球队'),
  awayTeam: const FootballTeam(id: 41, name: '对手'),
  status: 'SCHEDULED',
);
