import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/football/data/match_detail_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real overview lineups stats player stats ratings and rating lifecycle',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      const matchId = 15000000000000017;
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final client = ApiClient(config, dio);
      final api = MatchDetailApi(client);
      final auth = AuthRepository(AuthApi(client), storage);
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f15_${suffix.substring(suffix.length - 12)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      await auth.register(
        username: username,
        phone: '137${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      await auth.login(username: username, password: password);

      final overview = await api.overview(matchId);
      final lineups = await api.lineups(matchId);
      final stats = await api.stats(matchId);
      final players = await api.playerStats(matchId);
      final ratings = await api.ratings(matchId);
      final playerId = players.records.first.playerId;
      expect(overview.ranking?.snapshotType, 'CURRENT_STANDING');
      expect(lineups.hasData, isTrue);
      expect(stats, isNotEmpty);
      expect(players.records, isNotEmpty);
      expect(ratings, isNotEmpty);

      try {
        final submitted = await api.submitRating(matchId, playerId, 8.5);
        expect(submitted.myRating, 8.5);
        final overwritten = await api.submitRating(matchId, playerId, 9.0);
        expect(overwritten.myRating, 9.0);
      } finally {
        final cancelled = await api.cancelRating(matchId, playerId);
        expect(cancelled.myRating, isNull);
      }
      final restored = await api.ratings(matchId);
      expect(
        restored
            .firstWhere((item) => item.playerId == playerId)
            .currentUserRating,
        isNull,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
