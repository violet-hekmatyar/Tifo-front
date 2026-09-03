import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/recommendation_behavior.dart';
import 'recommendation_behavior_api.dart';

abstract interface class RecommendationBehaviorRepositoryContract {
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> events,
  );
}

final recommendationBehaviorRepositoryProvider =
    Provider<RecommendationBehaviorRepositoryContract>(
      (ref) => RecommendationBehaviorRepository(
        RecommendationBehaviorApi(ref.watch(apiClientProvider)),
      ),
    );

final class RecommendationBehaviorRepository
    implements RecommendationBehaviorRepositoryContract {
  const RecommendationBehaviorRepository(this._api);

  final RecommendationBehaviorApi _api;

  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> events,
  ) => _api.sendBatch(events);
}
