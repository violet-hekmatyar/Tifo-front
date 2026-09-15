import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/data/match_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_detail_models.dart';
import 'package:tifo/features/football/presentation/pages/match_detail_page.dart';

void main() {
  testWidgets('MATCH-02 MATCH-21 every tab renders at 360/412 and 1.4x', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(_app(width));
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('match_tab_overview')),
      );
      for (final key in const [
        'match_tab_ratings',
        'match_tab_overview',
        'match_tab_lineups',
        'match_tab_ranking',
        'match_tab_stats',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(find.byKey(ValueKey(key)));
        await _pumpSettled(tester);
        expect(find.byKey(ValueKey(key)), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

Future<void> _pumpSettled(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Widget _app(double width) => ProviderScope(
  key: ValueKey('responsive_match_scope_$width'),
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    footballRepositoryProvider.overrideWithValue(_Football()),
    matchDetailRepositoryProvider.overrideWithValue(_Details()),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.4)),
      child: child!,
    ),
    home: MatchDetailPage(
      key: ValueKey('responsive_match_page_$width'),
      matchId: 70,
    ),
  ),
);

final class _Football implements FootballRepositoryContract {
  @override
  Future<MatchDetail> matchDetail(int id) async => MatchDetail(
    match: FootballMatch(
      id: id,
      leagueId: 1,
      leagueName: '超长赛事名称',
      homeTeam: const FootballTeam(id: 40, name: '主队超长名称'),
      awayTeam: const FootballTeam(id: 41, name: '客队超长名称'),
      status: 'FINISHED',
      matchTime: DateTime(2026, 1, 1),
    ),
    events: const [],
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
  Future<TeamDetail> teamDetail(int id) => throw UnimplementedError();
  @override
  Future<PlayerDetail> playerDetail(int id) => throw UnimplementedError();
}

final class _Details implements MatchDetailRepositoryContract {
  @override
  Future<MatchOverviewV1> overview(int id) async => const MatchOverviewV1(
    matchId: 70,
    lineups: MatchLineups(),
    teamStats: [],
    playerStats: FootballPage(records: [], pageNum: 1, pages: 0, total: 0),
    ratings: [],
  );
  @override
  Future<MatchLineups> lineups(int id) async => const MatchLineups();
  @override
  Future<List<MatchTeamStatItem>> stats(int id) async => const [];
  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int id,
    int page,
    int size, {
    int? teamId,
    String? position,
  }) async => const FootballPage(records: [], pageNum: 1, pages: 0, total: 0);
  @override
  Future<List<MatchRatingSummary>> ratings(int id, {int? teamId}) async =>
      const [];
  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) => throw UnimplementedError();
  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) =>
      throw UnimplementedError();
}
