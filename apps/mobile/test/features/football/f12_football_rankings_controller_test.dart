import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/data/football_rankings_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/football_ranking_models.dart';
import 'package:tifo/features/football/presentation/controllers/football_rankings_controller.dart';

void main() {
  test(
    'loads current season, stage and standings then switches view',
    () async {
      final repository = _RankingsRepository();
      final controller = FootballRankingsController(repository);

      await controller.loadInitial();
      expect(controller.state.status, FootballRankingsStatus.ready);
      expect(controller.state.selectedLeagueId, 10);
      expect(controller.state.selectedSeasonId, 20);
      expect(controller.state.selectedStageId, 30);
      expect(controller.state.standings?.records.single.teamId, 40);

      await controller.selectView(FootballRankingView.players);
      expect(controller.state.playerRecords.map((item) => item.playerId), [50]);
      expect(controller.state.hasMore, isTrue);
      await controller.loadMore();
      expect(controller.state.playerRecords.map((item) => item.playerId), [
        50,
        51,
      ]);
      expect(repository.playerPages, [1, 2]);

      await controller.selectPlayerRankType(PlayerRankType.assists);
      expect(repository.lastPlayerType, PlayerRankType.assists);
      expect(controller.state.pageNum, 1);
    },
  );

  test(
    'season switch resets stage and stale ranking cannot overwrite',
    () async {
      final repository = _RankingsRepository();
      final controller = FootballRankingsController(repository);
      await controller.loadInitial();
      final stale = Completer<FootballPage<PlayerRankRecord>>();
      repository.deferredPlayers = stale;
      final oldLoad = controller.selectView(FootballRankingView.players);
      await controller.selectSeason(21);
      stale.complete(
        _playerPage(1, [
          const PlayerRankRecord(rank: 9, playerId: 99, playerName: '过期'),
        ]),
      );
      await oldLoad;

      expect(controller.state.selectedSeasonId, 21);
      expect(controller.state.selectedStageId, isNull);
      expect(
        controller.state.playerRecords.any((item) => item.playerId == 99),
        isFalse,
      );
    },
  );

  test('ranking failure, retry and empty state are explicit', () async {
    final repository = _RankingsRepository()
      ..standingError = const NetworkException('down');
    final controller = FootballRankingsController(repository);

    await controller.loadInitial();
    expect(controller.state.status, FootballRankingsStatus.failure);
    expect(controller.state.message, contains('网络连接失败'));

    repository
      ..standingError = null
      ..emptyStandings = true;
    await controller.retry();
    expect(controller.state.status, FootballRankingsStatus.empty);

    repository.emptyStandings = false;
    await controller.retry();
    expect(controller.state.status, FootballRankingsStatus.ready);
  });
}

final class _RankingsRepository implements FootballRankingsRepositoryContract {
  final List<int> playerPages = [];
  PlayerRankType? lastPlayerType;
  Completer<FootballPage<PlayerRankRecord>>? deferredPlayers;
  AppNetworkException? standingError;
  bool emptyStandings = false;

  @override
  Future<List<League>> leagues() async => const [League(id: 10, name: '联赛')];

  @override
  Future<List<FootballSeason>> seasons(int leagueId) async => const [
    FootballSeason(id: 21, leagueId: 10, name: '旧赛季', current: false),
    FootballSeason(id: 20, leagueId: 10, name: '当前赛季', current: true),
  ];

  @override
  Future<List<FootballStage>> stages(int leagueId, int seasonId) async =>
      seasonId == 20 ? const [FootballStage(id: 30, name: '联赛阶段')] : const [];

  @override
  Future<StandingTable> standings({
    required int leagueId,
    required int seasonId,
    int? stageId,
    String? groupCode,
  }) async {
    if (standingError case final error?) throw error;
    return StandingTable(
      leagueId: 10,
      seasonId: 20,
      records: emptyStandings
          ? const []
          : const [
              StandingRecord(
                rank: 1,
                teamId: 40,
                teamName: '球队',
                played: 1,
                won: 1,
                drawn: 0,
                lost: 0,
                goalsFor: 2,
                goalsAgainst: 0,
                goalDifference: 2,
                points: 3,
                deductionPoints: 0,
              ),
            ],
    );
  }

  @override
  Future<FootballPage<PlayerRankRecord>> playerRanks({
    required int leagueId,
    required int seasonId,
    required PlayerRankType rankType,
    required int page,
    required int size,
    int? stageId,
  }) {
    playerPages.add(page);
    lastPlayerType = rankType;
    if (deferredPlayers case final deferred?) {
      deferredPlayers = null;
      return deferred.future;
    }
    return Future.value(
      page == 1
          ? _playerPage(1, [
              const PlayerRankRecord(rank: 1, playerId: 50, playerName: '球员甲'),
            ], pages: 2)
          : _playerPage(2, const [
              PlayerRankRecord(rank: 1, playerId: 50, playerName: '球员甲'),
              PlayerRankRecord(rank: 2, playerId: 51, playerName: '球员乙'),
            ], pages: 2),
    );
  }

  @override
  Future<FootballPage<TeamRankRecord>> teamRanks({
    required int leagueId,
    required int seasonId,
    required TeamRankType rankType,
    required int page,
    required int size,
    int? stageId,
  }) async => const FootballPage(
    records: [TeamRankRecord(rank: 1, teamId: 40, teamName: '球队')],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
}

FootballPage<PlayerRankRecord> _playerPage(
  int page,
  List<PlayerRankRecord> records, {
  int pages = 1,
}) => FootballPage(
  records: records,
  pageNum: page,
  pages: pages,
  total: records.length,
);
