import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/football/data/football_api.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/domain/match_display_sort.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real backend provides football leagues matches teams players and events',
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
      final football = FootballRepository(FootballApi(client));

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f06_${suffix.substring(suffix.length - 12)}';
      final phone = '137${suffix.substring(suffix.length - 8)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}f';
      await auth.register(username: username, phone: phone, password: password);
      await auth.login(username: username, password: password);

      final leagues = await football.leagues();
      expect(leagues, isNotEmpty);

      final important = await football.importantMatches(1, 10);
      expect(important.records, isNotEmpty);
      final displayMatches = sortMatchesForDisplay(important.records);
      expect(
        displayMatches.map((item) => item.id).toSet(),
        hasLength(important.records.length),
      );
      final match = displayMatches.first;
      final detail = await football.matchDetail(match.id);
      expect(detail.match.id, match.id);
      expect(detail.match.homeTeam.id, match.homeTeam.id);
      expect(detail.match.awayTeam.id, match.awayTeam.id);

      final home = await football.teamDetail(match.homeTeam.id);
      final away = await football.teamDetail(match.awayTeam.id);
      expect(home.id, match.homeTeam.id);
      expect(away.id, match.awayTeam.id);

      final schedule = await football.teamMatches(home.id, 1, 10);
      expect(schedule.pageNum, 1);
      expect(schedule.records, isNotEmpty);

      final eventPlayerIds = detail.events
          .map((event) => event.playerId)
          .whereType<int>()
          .toSet();
      final playerId = eventPlayerIds.firstOrNull ?? 40001;
      final player = await football.playerDetail(playerId);
      expect(player.id, playerId);
      expect(player.name, isNotEmpty);

      final following = await football.followingMatches(1, 10);
      expect(following.pageNum, 1);

      // Safe capability summary: no credentials, tokens, response bodies, or text.
      // These are absent backend capabilities, not test failures or mocked data.
      debugPrint(
        'football_smoke leagues=${leagues.length} matches=${important.records.length} '
        'events=${detail.events.length} '
        'eventPlayers=${eventPlayerIds.length} statuses='
        '${important.records.map((item) => item.status).toSet().join(',')} '
        'following=${following.records.length} standings=unsupported '
        'roster=unsupported lineups=unsupported statistics=unsupported',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
