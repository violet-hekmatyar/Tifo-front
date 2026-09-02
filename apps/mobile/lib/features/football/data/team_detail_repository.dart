import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/football_models.dart';
import '../domain/team_detail_models.dart';
import 'team_detail_api.dart';

abstract interface class TeamDetailRepositoryContract {
  Future<TeamOverview> overview(int teamId, {int? seasonId});
  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId,
    int page,
    int size, {
    int? seasonId,
  });
  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId});
  Future<List<TeamHonor>> honors(int teamId);
  Future<FootballPage<FootballMatch>> matches(int teamId, int page, int size);
  Future<FootballPage<TeamContentSummary>> contents(
    int teamId,
    int page,
    int size,
  );
}

final teamDetailRepositoryProvider = Provider<TeamDetailRepositoryContract>(
  (ref) => TeamDetailRepository(TeamDetailApi(ref.watch(apiClientProvider))),
);

final class TeamDetailRepository implements TeamDetailRepositoryContract {
  const TeamDetailRepository(this._api);
  final TeamDetailApi _api;
  @override
  Future<TeamOverview> overview(int teamId, {int? seasonId}) =>
      _api.overview(teamId, seasonId: seasonId);
  @override
  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId,
    int page,
    int size, {
    int? seasonId,
  }) => _api.players(teamId, seasonId: seasonId, pageNum: page, pageSize: size);
  @override
  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId}) =>
      _api.stats(teamId, seasonId: seasonId, stageId: stageId);
  @override
  Future<List<TeamHonor>> honors(int teamId) => _api.honors(teamId);
  @override
  Future<FootballPage<FootballMatch>> matches(int teamId, int page, int size) =>
      _api.matches(teamId, pageNum: page, pageSize: size);
  @override
  Future<FootballPage<TeamContentSummary>> contents(
    int teamId,
    int page,
    int size,
  ) => _api.contents(teamId, pageNum: page, pageSize: size);
}
