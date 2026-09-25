import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/player_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/player_detail_models.dart';
import 'package:tifo/features/football/domain/team_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';

void main() {
  testWidgets(
    'PLAYER-01 PLAYER-06 PLAYER-18 all tabs render at 360/412 and 1.4x',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in [360.0, 412.0]) {
        tester.view.physicalSize = Size(width, 915);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey('responsive_scope_$width'),
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
              ),
              footballRepositoryProvider.overrideWithValue(
                const _FootballFake(),
              ),
              playerDetailRepositoryProvider.overrideWithValue(_PlayerFake()),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: PlayerDetailPage(
                key: ValueKey('responsive_player_$width'),
                playerId: 50,
              ),
            ),
          ),
        );
        await _pumpSettled(tester);

        expect(find.text('一个很长的球员名称用于响应式验证'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('player_tab_overview')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('player_tab_contents')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('player_tab_stats')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('player_tab_matches')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('player_tab_career')), findsOneWidget);

        final tabs = <(String, Finder)>[
          ('player_tab_overview', find.text('个人资料')),
          (
            'player_tab_contents',
            find.byKey(const ValueKey('player_content_80')),
          ),
          ('player_tab_stats', find.text('射正率')),
          (
            'player_tab_matches',
            find.byKey(const ValueKey('schedule_match_70')),
          ),
          (
            'player_tab_career',
            find.byKey(const ValueKey('player_national_career_state')),
          ),
        ];
        for (final tab in tabs) {
          final tabFinder = find.byKey(ValueKey(tab.$1));
          await tester.ensureVisible(tabFinder);
          await tester.tap(tabFinder);
          await _pumpSettled(tester);
          expect(tab.$2, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

Future<void> _pumpSettled(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final class _FootballFake implements FootballRepositoryContract {
  const _FootballFake();

  @override
  Future<PlayerDetail> playerDetail(int id) async => const PlayerDetail(
    id: 50,
    name: '一个很长的球员名称用于响应式验证',
    nameEn: 'A Very Long Player Name',
    retired: false,
    followed: false,
    followerCount: 2,
    position: 'UNKNOWN_POSITION',
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
  @override
  Future<PlayerOverview> overview(int playerId, {int? seasonId}) async =>
      const PlayerOverview(
        id: 50,
        name: '测试球员',
        retired: false,
        position: 'FW',
        club: PlayerTeamLink(id: 40, name: '测试俱乐部'),
      );

  @override
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  }) async => const [PlayerSeasonStats(shotAccuracy: 50, appearances: 1)];

  @override
  Future<List<PlayerTeamHistory>> teams(int playerId) async => const [
    PlayerTeamHistory(teamId: 40, teamName: '测试俱乐部', current: true),
  ];

  @override
  Future<PlayerCareer> career(int playerId) async => const PlayerCareer(
    totalAppearances: 1,
    byTeam: [PlayerCareerGroup(id: 40, name: '球队生涯')],
  );

  @override
  Future<FootballPage<FootballMatch>> matches(
    int playerId,
    int page,
    int size,
  ) async => FootballPage(
    records: [
      FootballMatch(
        id: 70,
        leagueId: 10,
        leagueName: '测试联赛',
        homeTeam: const FootballTeam(id: 40, name: '主队'),
        awayTeam: const FootballTeam(id: 41, name: '客队'),
        status: 'SCHEDULED',
      ),
    ],
    pageNum: 1,
    pages: 1,
    total: 1,
  );

  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId,
    int page,
    int size,
  ) async => const FootballPage(
    records: [
      TeamContentSummary(
        id: 80,
        title: '动态',
        rawType: 'UNKNOWN',
        summary: '内容摘要',
      ),
    ],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
}
