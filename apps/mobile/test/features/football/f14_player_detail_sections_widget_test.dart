import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/player_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/player_detail_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';

void main() {
  testWidgets(
    'PLAYER-04 PLAYER-05 PLAYER-06 PLAYER-08 PLAYER-10 PLAYER-11 PLAYER-13 PLAYER-14 PLAYER-17 sections behave from real data',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = _PlayerFake();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('个人资料'), findsOneWidget);
      expect(find.text('未知位置'), findsNothing);
      expect(find.text('暂无国家队信息'), findsOneWidget);
      expect(find.text('已退役'), findsOneWidget);
      expect(find.text('队长'), findsOneWidget);
      expect(find.text('当前赛季数据'), findsNothing);
      expect(find.text('最近比赛'), findsNothing);
      expect(find.text('最近动态'), findsNothing);

      for (final key in const [
        'player_tab_overview',
        'player_tab_contents',
        'player_tab_stats',
        'player_tab_matches',
        'player_tab_career',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('player_tab_contents')));
      await tester.pumpAndSettle();
      final first = tester.getSize(
        find.byKey(const ValueKey('player_content_80')),
      );
      final second = tester.getSize(
        find.byKey(const ValueKey('player_content_81')),
      );
      expect(first.width, second.width);
      expect(first.height, isNot(second.height));
      final last = tester.getSize(
        find.byKey(const ValueKey('player_content_94')),
      );
      expect(last.width, first.width);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('player_content_94'))).dx,
        closeTo(
          tester.getTopLeft(find.byKey(const ValueKey('player_content_80'))).dx,
          1,
        ),
      );
      expect(find.text('动态'), findsWidgets);
      expect(repository.contentsCalls, 1);

      final contentsList = find.byKey(const PageStorageKey('player_动态'));
      final initialY = tester
          .getTopLeft(find.byKey(const ValueKey('player_content_80')))
          .dy;
      await tester.drag(contentsList, const Offset(0, -500));
      await tester.pumpAndSettle();
      final scrolledY = tester
          .getTopLeft(find.byKey(const ValueKey('player_content_80')))
          .dy;
      expect(scrolledY, lessThan(initialY));
      await tester.tap(find.byKey(const ValueKey('player_tab_stats')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player_tab_contents')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('player_content_80'))).dy,
        closeTo(scrolledY, 1),
      );
      expect(repository.contentsCalls, 1);

      await tester.tap(find.byKey(const ValueKey('player_tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('52.5%'), findsOneWidget);
      expect(find.text('-10'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(find.text('射正率'), findsOneWidget);
      expect(find.text('扑救'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('player_tab_matches')));
      await tester.pumpAndSettle();
      expect(find.text('日期待定'), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule_match_71')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule_match_72')), findsOneWidget);
      expect(find.text('战报摘要'), findsWidgets);
      expect(repository.matchesCalls, 1);

      await tester.tap(find.byKey(const ValueKey('player_tab_career')));
      await tester.pumpAndSettle();
      expect(find.text('测试俱乐部'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('career_team_40_null')),
      );
      final currentTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('career_team_40_null')),
      );
      final currentSubtitle = (currentTile.subtitle! as Text).data!;
      expect(currentSubtitle, contains('当前效力'));
      expect(currentSubtitle, isNot(contains('租借')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('career_team_41_null')),
      );
      final loanTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('career_team_41_null')),
      );
      final loanSubtitle = (loanTile.subtitle! as Text).data!;
      expect(loanSubtitle.split('租借').length - 1, 1);
      expect(loanSubtitle, contains('2023-2024'));
      expect(loanSubtitle, contains('出场 0'));
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('career_team_0_null')))
            .onTap,
        isNull,
      );
      final callsBeforeSeason = repository.careerCalls;
      await tester.tap(find.text('赛季').last);
      await tester.pumpAndSettle();
      expect(find.text('2025 赛季'), findsOneWidget);
      expect(repository.careerCalls, callsBeforeSeason);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PLAYER-02 follow failure, busy protection, and invalid ID', (
    tester,
  ) async {
    final user = _UserFake();
    await tester.pumpWidget(_app(_PlayerFake(), user: user));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player_follow')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('player_follow')));
    expect(user.toggleCalls, 1);
    user.result.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('已关注'), findsOneWidget);

    final failedUser = _UserFake()
      ..failure = const NetworkException('toggle down');
    await tester.pumpWidget(_app(_PlayerFake(), user: failedUser));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('player_follow')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('player_follow')))
          .onPressed,
      isNotNull,
    );

    final businessUser = _UserFake()
      ..failure = const BusinessException(
        'toggle business down',
        code: 40001,
        traceId: null,
      );
    await tester.pumpWidget(_app(_PlayerFake(), user: businessUser));
    await _pumpSettled(tester);
    await tester.tap(find.byKey(const ValueKey('player_follow')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);

    final invalidUser = _UserFake();
    await tester.pumpWidget(
      _app(
        _PlayerFake(),
        football: const _FootballFake(returnedId: 0),
        user: invalidUser,
      ),
    );
    await _pumpSettled(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('player_follow')))
          .onPressed,
      isNull,
    );
    expect(invalidUser.toggleCalls, 0);
  });

  testWidgets('VR5-R1 overview, tab spacing, and career geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_app(_PlayerFake()));
    await tester.pumpAndSettle();

    final overviewOrder = [
      'player_overview_team_pair',
      'player_overview_personal',
      'player_overview_career',
      'player_overview_ability',
      'player_overview_honors',
    ].map((key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy).toList();
    for (var i = 1; i < overviewOrder.length; i++) {
      expect(overviewOrder[i], greaterThan(overviewOrder[i - 1]));
    }

    await tester.tap(find.byKey(const ValueKey('player_tab_contents')));
    await tester.pumpAndSettle();
    final contentsGap =
        tester.getTopLeft(find.byKey(const ValueKey('player_content_80'))).dy -
        tester
            .getBottomRight(find.byKey(const ValueKey('player_tab_contents')))
            .dy;
    expect(contentsGap, lessThanOrEqualTo(24));

    await tester.tap(find.byKey(const ValueKey('player_tab_matches')));
    await tester.pumpAndSettle();
    final matchesGap =
        tester
            .getTopLeft(find.byKey(const ValueKey('player_match_date_first')))
            .dy -
        tester
            .getBottomRight(find.byKey(const ValueKey('player_tab_matches')))
            .dy;
    expect(matchesGap, lessThanOrEqualTo(24));

    await tester.tap(find.byKey(const ValueKey('player_tab_career')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('player_career_toggle'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('player_career_table'))).dy,
      ),
    );
    expect(find.text('职业生涯总计'), findsNothing);
    expect(find.text('国家队生涯'), findsOneWidget);
    expect(find.text('暂无国家队生涯数据'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('player_national_career_state')),
          )
          .dy,
      greaterThan(
        tester
            .getBottomRight(find.byKey(const ValueKey('player_career_table')))
            .dy,
      ),
    );
    await tester.tap(find.text('赛季').last);
    await tester.pumpAndSettle();
    expect(find.text('2025 赛季'), findsOneWidget);
    expect(find.byKey(const ValueKey('player_career_table')), findsOneWidget);
    expect(find.text('职业生涯总计'), findsNothing);
    expect(
      find.byKey(const ValueKey('player_national_career_state')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PLAYER-07 PLAYER-09 refresh errors preserve records and retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _PlayerFake()
      ..contentsRefreshFail = true
      ..matchesRefreshFail = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('player_tab_contents')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('player_动态')),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsOneWidget);
    expect(find.byKey(const ValueKey('player_content_80')), findsOneWidget);
    repository.contentsRefreshFail = false;
    await tester.tap(find.widgetWithText(TextButton, '重试'));
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('player_tab_matches')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('player_比赛')),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule_match_71')), findsOneWidget);
    repository.matchesRefreshFail = false;
    await tester.tap(find.widgetWithText(TextButton, '重试'));
    await tester.pumpAndSettle();
    expect(find.textContaining('网络连接失败'), findsNothing);
  });

  testWidgets('PLAYER-15 career and teams errors remain isolated', (
    tester,
  ) async {
    final repository = _PlayerFake()..careerFail = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player_tab_career')));
    await tester.pumpAndSettle();
    expect(find.text('效力球队'), findsOneWidget);
    expect(find.text('career down'), findsOneWidget);
    expect(find.text('测试俱乐部'), findsWidgets);
    repository.careerFail = false;
    await tester.tap(find.byKey(const ValueKey('player_career_retry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('player_national_career_state')),
      findsOneWidget,
    );
  });

  testWidgets('PLAYER-15 teams failure is isolated and retries independently', (
    tester,
  ) async {
    final repository = _PlayerFake()..teamsFail = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player_tab_career')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('player_national_career_state')),
      findsOneWidget,
    );
    final careerList = find.byKey(const PageStorageKey('player_career'));
    await tester.drag(careerList, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('player_teams_state')), findsOneWidget);
    expect(find.text('teams down'), findsOneWidget);
    expect(find.byKey(const ValueKey('career_team_40_null')), findsNothing);
    final careerCallsBeforeRetry = repository.careerCalls;
    final teamsCallsBeforeRetry = repository.teamsCalls;

    repository.teamsFail = false;
    await tester.tap(find.byKey(const ValueKey('player_teams_retry')));
    await tester.pumpAndSettle();
    expect(find.text('teams down'), findsNothing);
    expect(find.byKey(const ValueKey('career_team_40_null')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('player_national_career_state')),
      findsOneWidget,
    );
    expect(repository.careerCalls, careerCallsBeforeRetry);
    expect(repository.teamsCalls, greaterThan(teamsCallsBeforeRetry));
  });

  testWidgets(
    'PLAYER-15 simultaneous career and teams failures keep retry targets isolated',
    (tester) async {
      final repository = _PlayerFake()
        ..careerFail = true
        ..teamsFail = true;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player_tab_career')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('player_career_state')), findsOneWidget);
      final careerList = find.byKey(const PageStorageKey('player_career'));
      await tester.drag(careerList, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player_teams_state')), findsOneWidget);
      expect(find.text('career down'), findsOneWidget);
      expect(find.text('teams down'), findsOneWidget);
      expect(find.byKey(const ValueKey('player_career_retry')), findsOneWidget);
      expect(find.byKey(const ValueKey('player_teams_retry')), findsOneWidget);

      final careerCallsBeforeTeamsRetry = repository.careerCalls;
      repository.teamsFail = false;
      await tester.tap(find.byKey(const ValueKey('player_teams_retry')));
      await tester.pumpAndSettle();
      expect(find.text('career down'), findsOneWidget);
      expect(find.text('teams down'), findsNothing);
      expect(find.byKey(const ValueKey('career_team_40_null')), findsOneWidget);
      expect(repository.careerCalls, careerCallsBeforeTeamsRetry);

      repository.careerFail = false;
      await tester.drag(careerList, const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player_career_retry')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player_career_retry')));
      await tester.pumpAndSettle();
      expect(find.text('career down'), findsNothing);
      expect(
        find.byKey(const ValueKey('player_national_career_state')),
        findsOneWidget,
      );
      await tester.drag(careerList, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('career_team_40_null')), findsOneWidget);
      expect(repository.careerCalls, careerCallsBeforeTeamsRetry + 1);
    },
  );

  testWidgets(
    'PLAYER-03 detail recommendation is sent once across tab rebuilds',
    (tester) async {
      final recommendation = _RecommendationFake();
      await tester.pumpWidget(
        _app(
          _PlayerFake(),
          recommendation: recommendation,
          recommendationSource: const RecommendationSourceContext(
            targetType: RecommendationTargetType.content,
            targetId: 80,
            attribution: RecommendationAttribution(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('player_tab_contents')));
      await tester.tap(find.byKey(const ValueKey('player_tab_career')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(recommendation.events, hasLength(1));
    },
  );
}

Future<void> _pumpSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _app(
  _PlayerFake repository, {
  FootballRepositoryContract? football,
  UserCenterRepositoryContract? user,
  RecommendationBehaviorRepositoryContract? recommendation,
  RecommendationSourceContext? recommendationSource,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    footballRepositoryProvider.overrideWithValue(
      football ?? const _FootballFake(),
    ),
    playerDetailRepositoryProvider.overrideWithValue(repository),
    if (user != null) userCenterRepositoryProvider.overrideWithValue(user),
    if (recommendation != null)
      recommendationBehaviorRepositoryProvider.overrideWithValue(
        recommendation,
      ),
  ],
  child: MaterialApp(
    home: PlayerDetailPage(
      playerId: 50,
      recommendationSource: recommendationSource,
    ),
  ),
);

final class _RecommendationFake
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

final class _FootballFake implements FootballRepositoryContract {
  const _FootballFake({this.returnedId = 50});
  final int returnedId;

  @override
  Future<PlayerDetail> playerDetail(int id) async => PlayerDetail(
    id: returnedId,
    name: '一个非常长的测试球员名称用于窄屏安全',
    nameEn: 'A Very Long Player Name',
    retired: true,
    followed: false,
    followerCount: 3,
    position: 'UNKNOWN_POSITION',
    team: const PlayerTeam(id: 40, name: '测试俱乐部'),
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

final class _PlayerFake implements PlayerDetailRepositoryContract {
  int contentsCalls = 0;
  int matchesCalls = 0;
  int careerCalls = 0;
  int teamsCalls = 0;
  bool contentsRefreshFail = false;
  bool matchesRefreshFail = false;
  bool careerFail = false;
  bool teamsFail = false;

  @override
  Future<PlayerOverview> overview(int playerId, {int? seasonId}) async =>
      PlayerOverview(
        id: 50,
        name: '测试球员',
        retired: true,
        position: 'UNKNOWN_POSITION',
        nationality: '中国',
        birthDate: DateTime(1990, 1, 2),
        height: 180,
        weight: 70,
        preferredFoot: '右脚',
        shirtNumber: 7,
        captain: true,
        club: const PlayerTeamLink(
          id: 40,
          name: '测试俱乐部',
          rawType: '职业队',
          shirtNumber: 7,
        ),
        seasonStats: const [
          PlayerSeasonStats(
            leagueName: '测试联赛',
            seasonName: '2025 赛季',
            teamName: '测试俱乐部',
            appearances: 0,
            goals: -1,
          ),
        ],
        recentMatches: [_match(70, DateTime(2026, 1, 2))],
        recentContents: const [
          TeamContentSummary(id: 80, title: '总览动态', rawType: 'UNKNOWN'),
        ],
      );

  @override
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  }) async => [
    const PlayerSeasonStats(
      leagueName: '测试联赛',
      seasonName: '2025 赛季',
      teamName: '测试俱乐部',
      appearances: 0,
      starts: 2,
      minutes: -10,
      goals: 3,
      assists: 4,
      yellowCards: 0,
      redCards: 1,
      shots: 12,
      shotsOnTarget: 6,
      shotAccuracy: 52.5,
      saves: 0,
      rating: double.infinity,
    ),
    const PlayerSeasonStats(teamName: '另一条统计', assists: 0),
  ];

  @override
  Future<List<PlayerTeamHistory>> teams(int playerId) async {
    teamsCalls++;
    if (teamsFail) {
      throw const BusinessException('teams down', code: 40002, traceId: null);
    }
    return [
      PlayerTeamHistory(
        teamId: 40,
        teamName: '测试俱乐部',
        seasonName: '2024-2025',
        startDate: DateTime(2024, 8),
        shirtNumber: 7,
        position: 'FW',
        appearances: 20,
        goals: 3,
        assists: 2,
        current: true,
      ),
      PlayerTeamHistory(
        teamId: 41,
        teamName: '租借俱乐部',
        seasonName: '2023-2024',
        endDate: DateTime(2024, 6),
        position: '租借',
        loan: true,
        appearances: 0,
      ),
      const PlayerTeamHistory(teamId: 0, teamName: '未知球队'),
    ];
  }

  @override
  Future<PlayerCareer> career(int playerId) async {
    careerCalls++;
    if (careerFail) {
      throw const BusinessException('career down', code: 40001, traceId: null);
    }
    return const PlayerCareer(
      totalAppearances: 20,
      totalStarts: 10,
      totalMinutes: 1000,
      totalGoals: 3,
      totalAssists: 4,
      totalYellowCards: 2,
      totalRedCards: 0,
      totalShots: 30,
      totalShotsOnTarget: 12,
      averageRating: 7.25,
      totalSaves: 0,
      teamCount: 2,
      seasonCount: 3,
      byTeam: [PlayerCareerGroup(id: 40, name: '球队生涯', goals: 3)],
      bySeason: [PlayerCareerGroup(id: 2025, name: '2025 赛季', appearances: 10)],
    );
  }

  @override
  Future<FootballPage<FootballMatch>> matches(
    int playerId,
    int page,
    int size,
  ) async {
    matchesCalls++;
    if (matchesRefreshFail && matchesCalls > 1) {
      throw const NetworkException('matches down');
    }
    return FootballPage(
      records: [
        _match(71, null),
        _match(72, null),
        _match(70, DateTime(2026, 1, 2)),
      ],
      pageNum: 1,
      pages: 1,
      total: 3,
    );
  }

  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId,
    int page,
    int size,
  ) async {
    contentsCalls++;
    if (contentsRefreshFail && contentsCalls > 1) {
      throw const NetworkException('contents down');
    }
    return FootballPage(
      records: [
        const TeamContentSummary(
          id: 80,
          title: '没有封面的动态',
          rawType: 'UNKNOWN',
          summary: '一段很长的摘要，用于验证自然高度布局和滚动位置恢复。',
        ),
        const TeamContentSummary(id: 81, title: '短动态', rawType: 'POST'),
        for (var id = 82; id < 95; id++)
          TeamContentSummary(
            id: id,
            title: '连续动态 $id',
            rawType: id.isEven ? 'ARTICLE' : 'POST',
            summary: '用于验证分页、滚动和独立列高度的测试摘要。',
          ),
      ],
      pageNum: 1,
      pages: 1,
      total: 15,
    );
  }
}

FootballMatch _match(int id, DateTime? time) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 40, name: '主队'),
  awayTeam: const FootballTeam(id: 41, name: '客队'),
  status: id == 70 ? 'FINISHED' : 'UNKNOWN',
  matchTime: time,
  eventSummary: id == 70 ? '战报摘要' : null,
  hasReport: id == 70,
  reportContentId: id == 70 ? 80 : null,
);

final class _UserFake implements UserCenterRepositoryContract {
  final result = Completer<bool>();
  int toggleCalls = 0;
  AppNetworkException? failure;

  @override
  Future<bool> toggleEntity(String type, int id) {
    toggleCalls++;
    if (failure case final error?) return Future<bool>.error(error);
    return result.future;
  }

  @override
  Future<MySummary> summary() => throw UnimplementedError();
  @override
  Future<UserStand> stand() => throw UnimplementedError();
  @override
  Future<UserProfile> profile(int userId) => throw UnimplementedError();
  @override
  Future<void> updateProfile({required String nickname, required String bio}) =>
      throw UnimplementedError();
  @override
  Future<void> setMainTeam(int teamId) => throw UnimplementedError();
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
