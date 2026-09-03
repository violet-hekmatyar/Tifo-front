import '../../../core/network/backend_v1_contract.dart';

final class RecommendationSourceContext {
  const RecommendationSourceContext({
    required this.targetType,
    required this.targetId,
    required this.attribution,
    this.scene = 'HOME_FEED',
  });

  final RecommendationTargetType targetType;
  final int targetId;
  final RecommendationAttribution attribution;
  final String scene;

  bool get isValid =>
      targetId > 0 && targetType != RecommendationTargetType.unknown;
}

final class RecommendationNavigationData {
  const RecommendationNavigationData({required this.source});

  final RecommendationSourceContext source;
}

final class RecommendationBehaviorEvent {
  const RecommendationBehaviorEvent({
    required this.clientEventId,
    required this.sessionId,
    required this.behaviorType,
    required this.source,
    required this.eventTime,
    this.dwellMs,
  });

  final String clientEventId;
  final String sessionId;
  final RecommendationBehaviorType behaviorType;
  final RecommendationSourceContext source;
  final DateTime eventTime;
  final int? dwellMs;

  Map<String, Object?> toJson() {
    final attribution = source.attribution;
    return {
      'clientEventId': _limited(clientEventId, 64),
      'sessionId': _limited(sessionId, 64),
      'behaviorType': behaviorType.wireValue,
      'targetType': source.targetType.wireValue,
      'targetId': source.targetId,
      'scene': _limited(source.scene, 32),
      'algorithmVersion': _limited(attribution.algorithmVersion, 32),
      'modelVersion': _limited(attribution.modelVersion, 64),
      'experimentId': _limited(attribution.experimentId, 64),
      'experimentBucket': _limited(attribution.experimentBucket, 32),
      'requestId': _limited(attribution.requestId, 64),
      'impressionId': _limited(attribution.impressionId, 96),
      'position': attribution.position?.clamp(0, 0x7fffffff),
      'dwellMs': dwellMs?.clamp(0, 0x7fffffffffffffff),
      'eventTime': eventTime.toLocal().toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }
}

final class RecommendationBehaviorBatchResult {
  const RecommendationBehaviorBatchResult({
    required this.received,
    required this.saved,
    required this.duplicated,
    required this.rejected,
  });

  final int received;
  final int saved;
  final int duplicated;
  final int rejected;
}

String? _limited(String? value, int maxLength) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.length <= maxLength
      ? trimmed
      : trimmed.substring(0, maxLength);
}
