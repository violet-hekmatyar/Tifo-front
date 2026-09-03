import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_api.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real six behaviors and saved duplicated rejected counters parse',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final client = ApiClient(
        AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
        dio,
      );
      final auth = AuthRepository(AuthApi(client), storage);
      final api = RecommendationBehaviorApi(client);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = stamp.toString();
      final tail = suffix.substring(suffix.length - 12);
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      await auth.register(
        username: 'f17_$tail',
        phone: '134${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      await auth.login(username: 'f17_$tail', password: password);

      const source = RecommendationSourceContext(
        targetType: RecommendationTargetType.content,
        targetId: 20005,
        attribution: RecommendationAttribution(
          algorithmVersion: 'F17_TEST',
          modelVersion: 'contract-v1',
          experimentId: 'F17',
          experimentBucket: 'A',
          requestId: 'f17-contract',
          impressionId: 'f17-impression',
          position: 0,
        ),
      );
      final types = [
        RecommendationBehaviorType.expose,
        RecommendationBehaviorType.click,
        RecommendationBehaviorType.detail,
        RecommendationBehaviorType.like,
        RecommendationBehaviorType.favorite,
        RecommendationBehaviorType.comment,
      ];
      final events = [
        for (var index = 0; index < types.length; index++)
          RecommendationBehaviorEvent(
            clientEventId: 'f17-$stamp-$index',
            sessionId: 'f17-$stamp',
            behaviorType: types[index],
            source: source,
            eventTime: DateTime.now(),
          ),
      ];
      final saved = await api.sendBatch(events);
      expect(saved.received, 6);
      expect(saved.saved, 6);
      expect(saved.duplicated, 0);
      expect(saved.rejected, 0);

      final duplicate = await api.sendBatch(events);
      expect(duplicate.received, 6);
      expect(duplicate.saved, 0);
      expect(duplicate.duplicated, 6);
      expect(duplicate.rejected, 0);

      final invalid = RecommendationBehaviorEvent(
        clientEventId: 'f17-$stamp-rejected',
        sessionId: 'f17-$stamp',
        behaviorType: RecommendationBehaviorType.expose,
        source: const RecommendationSourceContext(
          targetType: RecommendationTargetType.content,
          targetId: -1,
          attribution: RecommendationAttribution(),
        ),
        eventTime: DateTime.now(),
      );
      final rejected = await api.sendBatch([invalid]);
      expect(rejected.received, 1);
      expect(rejected.saved, 0);
      expect(rejected.duplicated, 0);
      expect(rejected.rejected, 1);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
