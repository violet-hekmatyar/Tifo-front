import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/api_response.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/onboarding/data/onboarding_api.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real backend registration, authentication, and onboarding flow',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
      }
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final client = ApiClient(config, dio);
      final auth = AuthRepository(AuthApi(client), storage);
      final onboarding = OnboardingRepository(OnboardingApi(client));

      final health = await client.get<Map<String, Object?>>(
        '/api/public/health',
        decode: _decodeMap,
      );
      expect(health['status'], 'UP');

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f03_${suffix.substring(suffix.length - 12)}';
      final phone = '137${suffix.substring(suffix.length - 8)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}x';

      final registered = await auth.register(
        username: username,
        phone: phone,
        password: password,
      );
      expect(registered.username, username);
      expect(registered.onboardingCompleted, isFalse);

      final loggedIn = await auth.login(username: username, password: password);
      expect(loggedIn.username, username);
      final token = await storage.readAccessToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      final me = await auth.currentUser();
      expect(me.username, username);

      final unauthenticatedClient = ApiClient(config, Dio());
      await expectLater(
        unauthenticatedClient.get<void>('/api/auth/me', decode: decodeVoid),
        throwsA(
          isA<BusinessException>().having((error) => error.code, 'code', 40101),
        ),
      );

      final options = await onboarding.loadOptions();
      expect(
        options.teams,
        isNotEmpty,
        reason: 'Backend seed must provide onboarding teams.',
      );
      expect(
        options.players,
        isNotEmpty,
        reason: 'Backend seed must provide onboarding players.',
      );
      final teams = options.teams.take(2).map((item) => item.id).toList();
      final players = options.players.take(2).map((item) => item.id).toList();
      final saved = await onboarding.savePreferences(
        mainTeamId: teams.first,
        followTeamIds: teams,
        followPlayerIds: players,
      );
      expect(saved.completed, isTrue);
      expect(saved.mainTeamId, teams.first);
      expect((await auth.currentUser()).onboardingCompleted, isTrue);

      await expectLater(
        auth.login(username: username, password: '${password}wrong'),
        throwsA(
          isA<BusinessException>().having((error) => error.code, 'code', 40101),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Map<String, Object?> _decodeMap(Object? raw) {
  if (raw is! Map) throw const ParseException('Expected JSON object.');
  return raw.map((key, value) => MapEntry(key.toString(), value));
}
