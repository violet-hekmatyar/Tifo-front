import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_rankings_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/football_ranking_models.dart';
import 'package:tifo/features/football/presentation/controllers/football_rankings_controller.dart';
import 'package:tifo/features/football/presentation/widgets/football_rankings_widgets.dart';
import 'package:tifo/shared/widgets/app_player_avatar.dart';
import 'package:tifo/shared/widgets/app_team_logo.dart';

void main() {
  testWidgets('DAT-03 ranking filters fit narrow widths and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FootballRankingsController(_NoopRankingsRepository());
    addTearDown(controller.dispose);

    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 800);
      for (final view in FootballRankingView.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: Scaffold(
                  body: FootballRankingFilters(
                    state: FootballRankingsState(
                      status: FootballRankingsStatus.ready,
                      view: view,
                      leagues: const [
                        League(id: 1, name: '这是一个很长的赛事名称 Premier League'),
                      ],
                      seasons: const [
                        FootballSeason(
                          id: 2,
                          leagueId: 1,
                          name: '2025/26赛季',
                          current: true,
                        ),
                      ],
                      stages: const [
                        FootballStage(id: 3, name: '这是一个较长的联赛阶段名称'),
                      ],
                      selectedLeagueId: 1,
                      selectedSeasonId: 2,
                      selectedStageId: 3,
                    ),
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '$width $view overflowed',
        );
      }
    }
  });

  testWidgets('VR2-R2 season control owns stage selection and section order', (
    tester,
  ) async {
    final controller = FootballRankingsController(_NoopRankingsRepository());
    addTearDown(controller.dispose);
    const state = FootballRankingsState(
      status: FootballRankingsStatus.ready,
      seasons: [
        FootballSeason(id: 2, leagueId: 1, name: '2025/26赛季', current: true),
      ],
      stages: [FootballStage(id: 3, name: '联赛阶段')],
      selectedLeagueId: 1,
      selectedSeasonId: 2,
      selectedStageId: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RankingContextBar(
            state: state,
            controller: controller,
            trailing: [
              SectionButton(
                key: const ValueKey('data_section_schedule'),
                label: '赛程',
                selected: true,
                onTap: () {},
              ),
              SectionButton(
                key: const ValueKey('data_section_standings'),
                label: '积分榜',
                selected: false,
                onTap: () {},
              ),
              SectionButton(
                key: const ValueKey('data_section_players'),
                label: '球员榜',
                selected: false,
                onTap: () {},
              ),
              SectionButton(
                key: const ValueKey('data_section_teams'),
                label: '球队榜',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ranking_filter_season')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking_filter_stage')), findsNothing);
    final season = tester.getRect(
      find.byKey(const ValueKey('ranking_filter_season')),
    );
    final schedule = tester.getRect(
      find.byKey(const ValueKey('data_section_schedule')),
    );
    expect(season.left, lessThan(schedule.left));
    expect(find.text('赛程'), findsOneWidget);
    expect(find.text('积分榜'), findsOneWidget);
    expect(find.text('球员榜'), findsOneWidget);
    expect(find.text('球队榜'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ranking_filter_season')));
    await tester.pumpAndSettle();
    expect(find.text('选择赛季与阶段'), findsOneWidget);
    expect(find.text('2025/26赛季'), findsWidgets);
    expect(find.text('联赛阶段'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ranking_stage_option_all')),
      findsOneWidget,
    );
  });

  testWidgets('DAT-07 standings columns and player rows navigate correctly', (
    tester,
  ) async {
    var showPlayers = false;
    late StateSetter rebuild;
    final router = GoRouter(
      initialLocation: '/data',
      routes: [
        GoRoute(
          path: '/data',
          builder: (_, _) => StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: showPlayers
                    ? PlayerRankingList(
                        state: const FootballRankingsState(
                          status: FootballRankingsStatus.ready,
                          view: FootballRankingView.players,
                          playerRecords: [
                            PlayerRankRecord(
                              rank: 1,
                              playerId: 50,
                              playerName: '测试球员',
                              displayValue: '8',
                            ),
                          ],
                        ),
                        onLoadMore: () {},
                      )
                    : const StandingsList(table: _table),
              );
            },
          ),
        ),
        GoRoute(
          path: '/teams/:id',
          builder: (_, state) => Text('球队 ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/players/:id',
          builder: (_, state) => Text('球员 ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('standing_team_40')));
    await tester.pumpAndSettle();
    expect(find.text('球队 40'), findsOneWidget);
    router.go('/data');
    await tester.pumpAndSettle();
    rebuild(() => showPlayers = true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ranking_player_50')));
    await tester.pumpAndSettle();
    expect(find.text('球员 50'), findsOneWidget);
  });

  testWidgets('VR2 standings keep goals and points visible at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StandingsList(table: _table)),
        ),
      ),
    );
    await tester.pump();
    final header = tester.getRect(
      find.byKey(const ValueKey('standing_points_header')),
    );
    final points = tester.getRect(
      find.byKey(const ValueKey('standing_points_40')),
    );
    expect(find.text('进/失球'), findsOneWidget);
    expect(find.text('积分'), findsOneWidget);
    expect(header.right, lessThanOrEqualTo(360));
    expect(points.right, lessThanOrEqualTo(360));
  });

  testWidgets('VR2 ranking rows start directly below the header', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: PlayerRankingList(
                state: const FootballRankingsState(
                  status: FootballRankingsStatus.ready,
                  view: FootballRankingView.players,
                  playerRecords: [
                    PlayerRankRecord(
                      rank: 1,
                      playerId: 50,
                      playerName: '测试球员',
                      teamName: '测试球队',
                      displayValue: '8',
                    ),
                  ],
                ),
                onLoadMore: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final header = tester.getRect(find.byKey(const ValueKey('ranking_header')));
    final row = tester.getRect(find.byKey(const ValueKey('ranking_player_50')));
    expect(row.top, closeTo(header.bottom, 1));
  });

  testWidgets('VR2 player and team avatars use distinct fallbacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AppPlayerAvatar(identity: 'player:1', name: '球员'),
                AppTeamLogo(identity: 'team:1', name: '球队'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toSet();
    expect(assets, contains('assets/ui/football/neutral-player-avatar.png'));
    expect(assets, contains('assets/ui/home/neutral-team-crest.png'));
  });

  testWidgets('DAT-08 invalid ranking IDs render safely without navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: const StandingsList(
                    table: StandingTable(
                      leagueId: 1,
                      seasonId: 2,
                      records: [
                        StandingRecord(
                          rank: 1,
                          teamId: 0,
                          teamName: '缺少编号的球队',
                          played: 0,
                          won: 0,
                          drawn: 0,
                          lost: 0,
                          goalsFor: 0,
                          goalsAgainst: 0,
                          goalDifference: 0,
                          points: 0,
                          deductionPoints: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: PlayerRankingList(
                    state: const FootballRankingsState(
                      status: FootballRankingsStatus.ready,
                      view: FootballRankingView.players,
                      playerRecords: [
                        PlayerRankRecord(
                          rank: 1,
                          playerId: 0,
                          playerName: '缺少编号的球员',
                        ),
                      ],
                    ),
                    onLoadMore: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('缺少编号的球队'), findsOneWidget);
    expect(find.text('缺少编号的球员'), findsOneWidget);
  });
}

final class _NoopRankingsRepository
    implements FootballRankingsRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _table = StandingTable(
  leagueId: 10,
  seasonId: 20,
  records: [
    StandingRecord(
      rank: 1,
      teamId: 40,
      teamName: '测试球队',
      played: 3,
      won: 2,
      drawn: 1,
      lost: 0,
      goalsFor: 5,
      goalsAgainst: 1,
      goalDifference: 4,
      points: 7,
      deductionPoints: 0,
    ),
  ],
);
