import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/domain/football_ranking_models.dart';
import 'package:tifo/features/football/presentation/controllers/football_rankings_controller.dart';
import 'package:tifo/features/football/presentation/widgets/football_rankings_widgets.dart';

void main() {
  testWidgets('standing and player rows navigate to entity details', (
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
