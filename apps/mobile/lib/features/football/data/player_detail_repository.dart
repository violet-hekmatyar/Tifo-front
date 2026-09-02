import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/football_models.dart';
import '../domain/player_detail_models.dart';
import '../domain/team_detail_models.dart';
import 'player_detail_api.dart';

abstract interface class PlayerDetailRepositoryContract {
  Future<PlayerOverview> overview(int playerId, {int? seasonId});
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  });
  Future<List<PlayerTeamHistory>> teams(int playerId);
  Future<PlayerCareer> career(int playerId);
  Future<FootballPage<FootballMatch>> matches(int playerId, int page, int size);
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId,
    int page,
    int size,
  );
}

final playerDetailRepositoryProvider = Provider<PlayerDetailRepositoryContract>(
  (ref) =>
      PlayerDetailRepository(PlayerDetailApi(ref.watch(apiClientProvider))),
);

final class PlayerDetailRepository implements PlayerDetailRepositoryContract {
  const PlayerDetailRepository(this._api);
  final PlayerDetailApi _api;
  @override
  Future<PlayerOverview> overview(int playerId, {int? seasonId}) =>
      _api.overview(playerId, seasonId: seasonId);
  @override
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  }) => _api.stats(
    playerId,
    leagueId: leagueId,
    seasonId: seasonId,
    stageId: stageId,
  );
  @override
  Future<List<PlayerTeamHistory>> teams(int playerId) => _api.teams(playerId);
  @override
  Future<PlayerCareer> career(int playerId) => _api.career(playerId);
  @override
  Future<FootballPage<FootballMatch>> matches(
    int playerId,
    int page,
    int size,
  ) => _api.matches(playerId, pageNum: page, pageSize: size);
  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId,
    int page,
    int size,
  ) => _api.contents(playerId, pageNum: page, pageSize: size);
}
