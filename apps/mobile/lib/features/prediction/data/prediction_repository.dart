import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/prediction_api.dart';
import '../domain/prediction_models.dart';

final predictionApiProvider = Provider<PredictionApi>(
  (ref) => PredictionApi(ref.watch(apiClientProvider)),
);

final predictionRepositoryProvider = Provider<PredictionRepository>(
  (ref) => PredictionRepository(ref.watch(predictionApiProvider)),
);

final class PredictionRepository {
  const PredictionRepository(this._api);
  final PredictionApi _api;

  Future<MatchPrediction> detail(int matchId) => _api.detail(matchId);

  Future<MatchPrediction> submit(
    int matchId, {
    required int homeProbability,
    required int drawProbability,
    required int awayProbability,
    required int stake,
  }) => _api.submit(
    matchId,
    homeProbability: homeProbability,
    drawProbability: drawProbability,
    awayProbability: awayProbability,
    stake: stake,
  );
}

final predictionDetailProvider = FutureProvider.autoDispose
    .family<MatchPrediction, int>(
      (ref, matchId) =>
          ref.watch(predictionRepositoryProvider).detail(matchId),
    );
