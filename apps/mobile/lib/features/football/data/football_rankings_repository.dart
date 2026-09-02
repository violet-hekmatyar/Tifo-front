import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/football_models.dart';
import '../domain/football_ranking_models.dart';
import 'football_api.dart';

abstract interface class FootballRankingsRepositoryContract {
  Future<List<League>> leagues();
  Future<List<FootballSeason>> seasons(int leagueId);
  Future<List<FootballStage>> stages(int leagueId, int seasonId);
  Future<StandingTable> standings({
    required int leagueId,
    required int seasonId,
    int? stageId,
    String? groupCode,
  });
  Future<FootballPage<PlayerRankRecord>> playerRanks({
    required int leagueId,
    required int seasonId,
    required PlayerRankType rankType,
    required int page,
    required int size,
    int? stageId,
  });
  Future<FootballPage<TeamRankRecord>> teamRanks({
    required int leagueId,
    required int seasonId,
    required TeamRankType rankType,
    required int page,
    required int size,
    int? stageId,
  });
}

final footballRankingsRepositoryProvider =
    Provider<FootballRankingsRepositoryContract>(
      (ref) =>
          FootballRankingsRepository(FootballApi(ref.watch(apiClientProvider))),
    );

final class FootballRankingsRepository
    implements FootballRankingsRepositoryContract {
  const FootballRankingsRepository(this._api);
  final FootballApi _api;

  @override
  Future<List<League>> leagues() => _api.leagues();
  @override
  Future<List<FootballSeason>> seasons(int leagueId) => _api.seasons(leagueId);
  @override
  Future<List<FootballStage>> stages(int leagueId, int seasonId) =>
      _api.stages(leagueId, seasonId);
  @override
  Future<StandingTable> standings({
    required int leagueId,
    required int seasonId,
    int? stageId,
    String? groupCode,
  }) => _api.standings(
    leagueId: leagueId,
    seasonId: seasonId,
    stageId: stageId,
    groupCode: groupCode,
  );
  @override
  Future<FootballPage<PlayerRankRecord>> playerRanks({
    required int leagueId,
    required int seasonId,
    required PlayerRankType rankType,
    required int page,
    required int size,
    int? stageId,
  }) => _api.playerRanks(
    leagueId: leagueId,
    seasonId: seasonId,
    rankType: rankType,
    pageNum: page,
    pageSize: size,
    stageId: stageId,
  );
  @override
  Future<FootballPage<TeamRankRecord>> teamRanks({
    required int leagueId,
    required int seasonId,
    required TeamRankType rankType,
    required int page,
    required int size,
    int? stageId,
  }) => _api.teamRanks(
    leagueId: leagueId,
    seasonId: seasonId,
    rankType: rankType,
    pageNum: page,
    pageSize: size,
    stageId: stageId,
  );
}
