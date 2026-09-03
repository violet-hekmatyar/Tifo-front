import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/backend_v1_contract.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/recommendation_behavior_repository.dart';
import '../domain/recommendation_behavior.dart';

final recommendationBehaviorDispatcherProvider =
    Provider<RecommendationBehaviorDispatcher>((ref) {
      final userId = ref.watch(
        authControllerProvider.select(
          (controller) => controller.state.user?.id,
        ),
      );
      final dispatcher = RecommendationBehaviorDispatcher(
        ref.watch(recommendationBehaviorRepositoryProvider),
        sessionScope: userId?.toString(),
      );
      ref.onDispose(dispatcher.dispose);
      return dispatcher;
    });

final class RecommendationBehaviorDispatcher {
  RecommendationBehaviorDispatcher(
    this._repository, {
    String? sessionScope,
    this.batchDelay = const Duration(milliseconds: 250),
    this.retryDelay = const Duration(seconds: 1),
    this.maxAttempts = 2,
  }) : _sessionId = [
         's',
         ?sessionScope,
         DateTime.now().microsecondsSinceEpoch.toRadixString(36),
       ].join('-');

  static const maxBatchSize = 100;

  final RecommendationBehaviorRepositoryContract _repository;
  final Duration batchDelay;
  final Duration retryDelay;
  final int maxAttempts;
  final String _sessionId;
  final List<_QueuedEvent> _queue = [];
  final Set<String> _knownIds = {};
  Timer? _timer;
  bool _sending = false;
  bool _disposed = false;
  int _counter = 0;

  void record(
    RecommendationBehaviorType behaviorType,
    RecommendationSourceContext? source, {
    int? dwellMs,
  }) {
    if (_disposed ||
        source == null ||
        !source.isValid ||
        behaviorType == RecommendationBehaviorType.unknown) {
      return;
    }
    final now = DateTime.now();
    enqueue(
      RecommendationBehaviorEvent(
        clientEventId:
            'e-${now.microsecondsSinceEpoch.toRadixString(36)}-${(_counter++).toRadixString(36)}',
        sessionId: _sessionId,
        behaviorType: behaviorType,
        source: source,
        eventTime: now,
        dwellMs: dwellMs,
      ),
    );
  }

  void enqueue(RecommendationBehaviorEvent event) {
    if (_disposed) return;
    if (!_knownIds.add(event.clientEventId)) return;
    _queue.add(_QueuedEvent(event));
    if (_queue.length >= maxBatchSize) {
      _timer?.cancel();
      unawaited(flush());
    } else {
      _schedule(batchDelay);
    }
  }

  Future<void> flush() async {
    if (_disposed || _sending || _queue.isEmpty) return;
    _timer?.cancel();
    _timer = null;
    _sending = true;
    final count = _queue.length.clamp(0, maxBatchSize);
    final batch = _queue.sublist(0, count);
    _queue.removeRange(0, count);
    try {
      await _repository.sendBatch(batch.map((item) => item.event).toList());
    } catch (_) {
      final retryable = _disposed
          ? const <_QueuedEvent>[]
          : [
              for (final item in batch)
                if (item.attempts + 1 < maxAttempts)
                  _QueuedEvent(item.event, attempts: item.attempts + 1),
            ];
      _queue.insertAll(0, retryable);
    } finally {
      _sending = false;
      if (!_disposed && _queue.isNotEmpty) _schedule(retryDelay);
    }
  }

  void _schedule(Duration delay) {
    if (_disposed || (_timer?.isActive ?? false)) return;
    _timer = Timer(delay, () => unawaited(flush()));
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _queue.clear();
    _knownIds.clear();
  }
}

final class _QueuedEvent {
  const _QueuedEvent(this.event, {this.attempts = 0});

  final RecommendationBehaviorEvent event;
  final int attempts;
}
