import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/football_models.dart';
import '../domain/match_detail_models.dart';
import 'match_detail_api.dart';

abstract interface class MatchDetailRepositoryContract {
  Future<MatchOverviewV1> overview(int matchId);
  Future<MatchLineups> lineups(int matchId);
  Future<List<MatchTeamStatItem>> stats(int matchId);
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size,
  );
  Future<List<MatchRatingSummary>> ratings(int matchId);
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  );
  Future<MatchRatingResult> cancelRating(int matchId, int playerId);
}

final matchDetailRepositoryProvider = Provider<MatchDetailRepositoryContract>(
  (ref) => MatchDetailRepository(MatchDetailApi(ref.watch(apiClientProvider))),
);

final class MatchDetailRepository implements MatchDetailRepositoryContract {
  const MatchDetailRepository(this._api);
  final MatchDetailApi _api;
  @override
  Future<MatchOverviewV1> overview(int matchId) => _api.overview(matchId);
  @override
  Future<MatchLineups> lineups(int matchId) => _api.lineups(matchId);
  @override
  Future<List<MatchTeamStatItem>> stats(int matchId) => _api.stats(matchId);
  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size,
  ) => _api.playerStats(matchId, pageNum: page, pageSize: size);
  @override
  Future<List<MatchRatingSummary>> ratings(int matchId) =>
      _api.ratings(matchId);
  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) => _api.submitRating(matchId, playerId, rating);
  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) =>
      _api.cancelRating(matchId, playerId);
}
