import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../domain/recommendation_behavior.dart';

final class RecommendationBehaviorApi {
  const RecommendationBehaviorApi(this._client);

  final ApiClient _client;

  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> events,
  ) {
    if (events.isEmpty || events.length > 100) {
      throw ArgumentError.value(events.length, 'events', 'must contain 1-100');
    }
    return _client.post<RecommendationBehaviorBatchResult>(
      '/api/app/recommendation/behaviors/batch',
      body: {'events': events.map((event) => event.toJson()).toList()},
      decode: (raw) {
        final map = jsonMap(raw);
        final received = jsonInt(map?['received']);
        final saved = jsonInt(map?['saved']);
        final duplicated = jsonInt(map?['duplicated']);
        final rejected = jsonInt(map?['rejected']);
        if (received == null ||
            saved == null ||
            duplicated == null ||
            rejected == null) {
          throw const ParseException('Invalid recommendation batch response.');
        }
        return RecommendationBehaviorBatchResult(
          received: received,
          saved: saved,
          duplicated: duplicated,
          rejected: rejected,
        );
      },
    );
  }
}
