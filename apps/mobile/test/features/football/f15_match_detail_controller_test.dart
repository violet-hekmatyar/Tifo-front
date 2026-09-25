import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/data/match_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_detail_models.dart';
import 'package:tifo/features/football/presentation/controllers/match_detail_controllers.dart';

void main() {
  test(
    'MATCH-04 resource refresh keeps old detail on failure and retries',
    () async {
      var calls = 0;
      var fail = false;
      final controller = MatchResourceController<MatchDetail>(
        target: '比赛概览',
        loader: () async {
          calls++;
          if (fail) throw const NetworkException('refresh down');
          return _detail(calls);
        },
      );
      await controller.load();
      expect(controller.state.value?.match.id, 1);
      fail = true;
      await controller.refresh();
      expect(controller.state.value?.match.id, 1);
      expect(controller.state.message, contains('网络连接失败'));
      fail = false;
      await controller.refresh();
      expect(controller.state.value?.match.id, 3);
    },
  );

  test(
    'MATCH-13 MATCH-14 player stats filter, dedupe, pagination and append retry',
    () async {
      var appendFail = false;
      final calls = <(int, int?, String?)>[];
      final controller = MatchPlayerStatsController(
        target: '球员统计',
        loader: (page, size, teamId, position) async {
          calls.add((page, teamId, position));
          if (page == 2 && appendFail) {
            throw const NetworkException('append down');
          }
          return FootballPage(
            records: page == 1
                ? const [
                    MatchPlayerStat(playerId: 50, playerName: '甲', teamId: 40),
                    MatchPlayerStat(
                      playerId: 50,
                      playerName: '甲重复',
                      teamId: 40,
                    ),
                  ]
                : const [
                    MatchPlayerStat(
                      playerId: 50,
                      playerName: '甲更新',
                      teamId: 40,
                    ),
                    MatchPlayerStat(playerId: 51, playerName: '乙', teamId: 41),
                  ],
            pageNum: page,
            pages: 2,
            total: 2,
          );
        },
      );
      await controller.loadInitial();
      expect(controller.state.records, hasLength(1));
      appendFail = true;
      await controller.loadMore();
      expect(controller.state.records, hasLength(1));
      expect(controller.state.appendMessage, contains('网络连接失败'));
      appendFail = false;
      await controller.loadMore();
      expect(controller.state.records.map((value) => value.playerId), [50, 51]);
      expect(controller.state.hasMore, isFalse);
      await controller.setFilter(teamId: 41, position: 'FORWARD');
      expect(calls.last, (1, 41, 'FORWARD'));
      expect(controller.state.pageNum, 1);
    },
  );

  test(
    'MATCH-13 stale player response cannot overwrite the latest filter',
    () async {
      final first = Completer<FootballPage<MatchPlayerStat>>();
      final second = Completer<FootballPage<MatchPlayerStat>>();
      var calls = 0;
      final controller = MatchPlayerStatsController(
        target: '球员统计',
        loader: (page, size, teamId, position) {
          calls++;
          return calls == 1 ? first.future : second.future;
        },
      );
      final initial = controller.loadInitial();
      final filtered = controller.setFilter(teamId: 41);
      second.complete(
        _page(const [
          MatchPlayerStat(playerId: 51, playerName: '新', teamId: 41),
        ]),
      );
      await filtered;
      first.complete(
        _page(const [
          MatchPlayerStat(playerId: 50, playerName: '旧', teamId: 40),
        ]),
      );
      await initial;
      expect(controller.state.records.single.playerId, 51);
    },
  );

  test(
    'MATCH-16 rating filter requests use real team ids and ignore stale responses',
    () async {
      final repository = _RatingsRaceRepository();
      final controller = MatchRatingsController(repository, matchId: 70);
      final home = controller.load(teamId: 40, force: true);
      final away = controller.load(teamId: 41, force: true);
      repository.away.complete(const [
        MatchRatingSummary(playerId: 51, playerName: '客队球员', teamId: 41),
      ]);
      await away;
      repository.home.complete(const [
        MatchRatingSummary(playerId: 50, playerName: '主队球员', teamId: 40),
      ]);
      await home;
      expect(repository.requestedTeams, [40, 41]);
      expect(controller.teamId, 41);
      expect(controller.state.records.single.playerId, 51);
    },
  );

  test(
    'MATCH-15 independent resource controllers retain separate state',
    () async {
      var lineupsFail = false;
      var statsFail = false;
      final lineups = MatchResourceController<MatchLineups>(
        target: '阵容',
        loader: () async {
          if (lineupsFail) {
            throw const BusinessException(
              'lineups down',
              code: 1,
              traceId: null,
            );
          }
          return const MatchLineups(
            home: MatchTeamLineup(teamId: 40, teamName: '主队'),
          );
        },
      );
      final stats = MatchResourceController<List<MatchTeamStatItem>>(
        target: '球队统计',
        loader: () async {
          if (statsFail) throw const NetworkException('stats down');
          return const [
            MatchTeamStatItem(
              rawType: 'POSSESSION',
              displayName: '控球率',
              homeValue: 40,
              awayValue: 60,
            ),
          ];
        },
      );
      lineupsFail = true;
      await lineups.load();
      await stats.load();
      expect(lineups.state.status, MatchResourceStatus.failure);
      expect(stats.state.value, isNotEmpty);
      statsFail = true;
      await stats.refresh();
      expect(stats.state.value, isNotEmpty);
      expect(lineups.state.status, MatchResourceStatus.failure);
    },
  );
}

FootballPage<MatchPlayerStat> _page(List<MatchPlayerStat> records) =>
    FootballPage(records: records, pageNum: 1, pages: 1, total: records.length);

MatchDetail _detail(int id) => MatchDetail(
  match: FootballMatch(
    id: id,
    leagueId: 10,
    leagueName: '测试联赛',
    homeTeam: const FootballTeam(id: 40, name: '主队'),
    awayTeam: const FootballTeam(id: 41, name: '客队'),
    status: 'FINISHED',
  ),
  events: const [],
);

final class _RatingsRaceRepository implements MatchDetailRepositoryContract {
  final home = Completer<List<MatchRatingSummary>>();
  final away = Completer<List<MatchRatingSummary>>();
  final requestedTeams = <int?>[];

  @override
  Future<List<MatchRatingSummary>> ratings(int matchId, {int? teamId}) {
    requestedTeams.add(teamId);
    return teamId == 40 ? home.future : away.future;
  }

  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) => throw UnimplementedError();

  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) =>
      throw UnimplementedError();

  @override
  Future<MatchOverviewV1> overview(int matchId) => throw UnimplementedError();
  @override
  Future<MatchLineups> lineups(int matchId) => throw UnimplementedError();
  @override
  Future<FootballPage<MatchRelatedContent>> contents(
    int matchId, {
    int page = 1,
    int size = 10,
    String? contentType,
  }) => throw UnimplementedError();
  @override
  Future<List<MatchTeamStatItem>> stats(int matchId) =>
      throw UnimplementedError();
  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size, {
    int? teamId,
    String? position,
  }) => throw UnimplementedError();
}
