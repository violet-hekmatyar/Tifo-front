import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/recommendation/presentation/recommendation_behavior_dispatcher.dart';

void main() {
  const attribution = RecommendationAttribution(
    algorithmVersion: 'rule-v2',
    modelVersion: 'model-7',
    experimentId: 'home-v1',
    experimentBucket: 'B',
    requestId: 'request-1',
    impressionId: 'impression-1',
    position: 3,
  );
  const source = RecommendationSourceContext(
    targetType: RecommendationTargetType.content,
    targetId: 20005,
    attribution: attribution,
  );

  test('event keeps complete attribution and uses backend ISO contract', () {
    final event = RecommendationBehaviorEvent(
      clientEventId: 'event-1',
      sessionId: 'session-1',
      behaviorType: RecommendationBehaviorType.click,
      source: source,
      eventTime: DateTime(2026, 9, 3, 10, 20, 30),
    );
    final json = event.toJson();
    expect(json['behaviorType'], 'CLICK');
    expect(json['targetType'], 'CONTENT');
    expect(json['requestId'], 'request-1');
    expect(json['impressionId'], 'impression-1');
    expect(json['position'], 3);
    expect(json['algorithmVersion'], 'rule-v2');
    expect(json['modelVersion'], 'model-7');
    expect(json['experimentId'], 'home-v1');
    expect(json['experimentBucket'], 'B');
    expect(json['eventTime'], '2026-09-03T10:20:30.000');
    expect(json.containsKey('extraJson'), isFalse);
  });

  test(
    'dispatcher batches at 100, deduplicates and retries stable IDs',
    () async {
      final repository = _RecordingRepository(failures: 1);
      final dispatcher = RecommendationBehaviorDispatcher(
        repository,
        batchDelay: const Duration(days: 1),
        retryDelay: const Duration(days: 1),
      );
      addTearDown(dispatcher.dispose);
      final events = List.generate(
        101,
        (index) => RecommendationBehaviorEvent(
          clientEventId: 'event-$index',
          sessionId: 'session',
          behaviorType: RecommendationBehaviorType.expose,
          source: source,
          eventTime: DateTime(2026, 9, 3),
        ),
      );
      for (final event in events) {
        dispatcher.enqueue(event);
      }
      dispatcher.enqueue(events.first);
      await dispatcher.flush();
      await dispatcher.flush();
      await dispatcher.flush();

      expect(repository.calls.map((batch) => batch.length), [100, 100, 1]);
      expect(
        repository.calls[0].map((event) => event.clientEventId),
        repository.calls[1].map((event) => event.clientEventId),
      );
      expect(repository.calls.last.single.clientEventId, 'event-100');
    },
  );

  test('nullable or invalid source is ignored safely', () async {
    final repository = _RecordingRepository();
    final dispatcher = RecommendationBehaviorDispatcher(
      repository,
      batchDelay: const Duration(days: 1),
    );
    addTearDown(dispatcher.dispose);
    dispatcher.record(RecommendationBehaviorType.expose, null);
    dispatcher.record(
      RecommendationBehaviorType.click,
      const RecommendationSourceContext(
        targetType: RecommendationTargetType.unknown,
        targetId: -1,
        attribution: RecommendationAttribution(),
      ),
    );
    await dispatcher.flush();
    expect(repository.calls, isEmpty);
  });

  test('retry is finite and dispose drops the account queue', () async {
    final repository = _RecordingRepository(failures: 10);
    final dispatcher = RecommendationBehaviorDispatcher(
      repository,
      batchDelay: const Duration(days: 1),
      retryDelay: const Duration(days: 1),
    );
    dispatcher.record(RecommendationBehaviorType.click, source);
    await dispatcher.flush();
    await dispatcher.flush();
    await dispatcher.flush();
    expect(repository.calls, hasLength(2));

    dispatcher.record(RecommendationBehaviorType.detail, source);
    dispatcher.dispose();
    await dispatcher.flush();
    expect(repository.calls, hasLength(2));
  });
}

final class _RecordingRepository
    implements RecommendationBehaviorRepositoryContract {
  _RecordingRepository({this.failures = 0});
  int failures;
  final List<List<RecommendationBehaviorEvent>> calls = [];

  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> events,
  ) async {
    calls.add(List.of(events));
    if (failures > 0) {
      failures--;
      throw StateError('temporary failure');
    }
    return RecommendationBehaviorBatchResult(
      received: events.length,
      saved: events.length,
      duplicated: 0,
      rejected: 0,
    );
  }
}
