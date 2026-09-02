import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/player_detail_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real player overview stats teams career matches and contents',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      const playerId = 40007;
      final api = PlayerDetailApi(
        ApiClient(
          AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
          Dio(),
        ),
      );

      final overview = await api.overview(playerId);
      final stats = await api.stats(playerId);
      final teams = await api.teams(playerId);
      final career = await api.career(playerId);
      final matches = await api.matches(playerId, pageSize: 2);
      final contents = await api.contents(playerId, pageSize: 2);

      expect(overview.id, playerId);
      expect(overview.nationalTeam, anyOf(isNull, isA<Object>()));
      expect(stats, isNotEmpty);
      expect(teams, isNotEmpty);
      expect(career.hasData, isTrue);
      expect(matches.records, isNotEmpty);
      expect(contents.records, isNotEmpty);
      expect(
        matches.records.map((item) => item.id).toSet().length,
        matches.records.length,
      );
      expect(
        contents.records.map((item) => item.id).toSet().length,
        contents.records.length,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
