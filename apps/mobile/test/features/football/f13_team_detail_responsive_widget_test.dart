import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/team_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';

void main() {
  testWidgets('TEAM-01 TEAM-15 responsive team detail has stable tabs', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 915);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
            footballRepositoryProvider.overrideWithValue(_FootballFake()),
            teamDetailRepositoryProvider.overrideWithValue(_TeamFake()),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: const TeamDetailPage(teamId: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('team_tab_overview')), findsOneWidget);
      expect(find.byKey(const ValueKey('team_tab_contents')), findsOneWidget);
      expect(find.byKey(const ValueKey('team_tab_players')), findsOneWidget);
      expect(find.byKey(const ValueKey('team_tab_stats')), findsOneWidget);
      expect(find.byKey(const ValueKey('team_tab_matches')), findsOneWidget);
      expect(find.text('一个很长的球队名称用于验证窄屏布局'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final tabs = <(String, Finder)>[
        ('team_tab_overview', find.text('赛事排名')),
        ('team_tab_contents', find.byKey(const ValueKey('team_content_80'))),
        ('team_tab_players', find.byKey(const ValueKey('team_player_50'))),
        ('team_tab_stats', find.text('射正率')),
        ('team_tab_matches', find.byKey(const ValueKey('schedule_match_70'))),
      ];
      for (final tab in tabs) {
        final tabFinder = find.byKey(ValueKey(tab.$1));
        await tester.ensureVisible(tabFinder);
        await tester.tap(tabFinder);
        await tester.pumpAndSettle();
        expect(tab.$2, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

final class _FootballFake implements FootballRepositoryContract {
  @override
  Future<TeamDetail> teamDetail(int id) async => const TeamDetail(
    id: 40,
    name: '一个很长的球队名称用于验证窄屏布局',
    nameEn: 'A Very Long Team Name',
    followed: false,
    followerCount: 12,
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
  @override
  Future<TeamOverview> overview(int teamId, {int? seasonId}) async =>
      TeamOverview(
        teamId: 40,
        teamName: '测试球队',
        leagueName: '测试联赛',
        seasonName: '2026 赛季',
        competitionStandings: const [
          TeamCompetitionStanding(
            leagueId: 10,
            leagueName: '测试联赛',
            seasonId: 20,
            stageId: 30,
            rank: 2,
            points: 20,
          ),
        ],
        city: '上海',
        stadium: '测试体育场',
        standing: TeamStandingSummary(
          rank: 2,
          played: 10,
          won: 6,
          drawn: 2,
          lost: 2,
          goalsFor: 18,
          goalsAgainst: 9,
          goalDifference: 9,
          points: 20,
        ),
        topScorers: [
          TeamRosterPlayer(
            id: 50,
            name: '长名字球员',
            position: 'FORWARD',
            goals: 8,
          ),
        ],
        topAssists: [
          TeamRosterPlayer(
            id: 51,
            name: '助攻球员',
            position: 'MIDFIELDER',
            assists: 5,
          ),
        ],
        recentMatches: [_match],
        recentContents: [
          TeamContentSummary(id: 80, title: '一条很长的球队动态标题', rawType: 'ARTICLE'),
        ],
      );

  @override
  Future<List<TeamHonor>> honors(int teamId) async => const [
    TeamHonor(id: 60, name: '测试冠军', titleCount: 2, winningYears: [2024]),
  ];

  @override
  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId}) async =>
      const TeamStats(
        played: 10,
        goalsFor: 18,
        goalsAgainst: 9,
        goalDifference: 9,
        standingRank: 2,
        points: 20,
        shotAccuracy: 52.5,
        averageRating: 7.25,
      );

  @override
  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId,
    int page,
    int size, {
    int? seasonId,
  }) async => const FootballPage(
    records: [TeamRosterPlayer(id: 50, name: '长名字球员', position: 'FORWARD')],
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
