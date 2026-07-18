import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/football_models.dart';
import 'football_api.dart';

abstract interface class FootballRepositoryContract {
  Future<List<League>> leagues();
  Future<FootballPage<FootballMatch>> importantMatches(int page, int size);
  Future<FootballPage<FootballMatch>> followingMatches(int page, int size);
  Future<FootballPage<FootballMatch>> leagueMatches(int id, int page, int size);
  Future<FootballPage<FootballMatch>> teamMatches(int id, int page, int size);
  Future<MatchDetail> matchDetail(int id);
  Future<TeamDetail> teamDetail(int id);
  Future<PlayerDetail> playerDetail(int id);
}

final footballRepositoryProvider = Provider<FootballRepositoryContract>(
  (ref) => FootballRepository(FootballApi(ref.watch(apiClientProvider))),
);

final class FootballRepository implements FootballRepositoryContract {
  const FootballRepository(this._api);
  final FootballApi _api;

  @override
  Future<List<League>> leagues() => _api.leagues();
  @override
  Future<FootballPage<FootballMatch>> importantMatches(int page, int size) =>
      _api.importantMatches(pageNum: page, pageSize: size);
  @override
  Future<FootballPage<FootballMatch>> followingMatches(int page, int size) =>
      _api.followingMatches(pageNum: page, pageSize: size);
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) => _api.matches(pageNum: page, pageSize: size, leagueId: id);
  @override
  Future<FootballPage<FootballMatch>> teamMatches(int id, int page, int size) =>
      _api.matches(pageNum: page, pageSize: size, teamId: id);
  @override
  Future<MatchDetail> matchDetail(int id) => _api.matchDetail(id);
  @override
  Future<TeamDetail> teamDetail(int id) => _api.teamDetail(id);
  @override
  Future<PlayerDetail> playerDetail(int id) => _api.playerDetail(id);
}
