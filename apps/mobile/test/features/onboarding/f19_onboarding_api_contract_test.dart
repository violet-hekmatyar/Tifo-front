import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/onboarding/data/onboarding_api.dart';

void main() {
  test(
    'ONB-09/10 options decode nullable fields and preferences preserve IDs',
    () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = OnboardingApi(
        ApiClient(AppConfig.fromValues(apiBaseUrl: 'https://api.test'), dio),
      );
      adapter
        ..onGet(
          'https://api.test/api/app/onboarding/options',
          (server) => server.reply(
            200,
            _envelope({
              'recommendedTeams': [
                {
                  'teamId': 7,
                  'teamName': '主队',
                  'logoUrl': null,
                  'leagueName': null,
                  'country': '中国',
                  'followed': false,
                },
              ],
              'hotTeams': <Object>[],
              'recommendedPlayers': [
                {
                  'playerId': 9,
                  'playerName': '球员',
                  'avatarUrl': null,
                  'position': null,
                  'teamId': null,
                  'teamName': null,
                  'followed': false,
                },
              ],
              'hotPlayers': <Object>[],
            }),
          ),
        )
        ..onPost(
          'https://api.test/api/app/onboarding/preferences',
          (server) => server.reply(
            200,
            _envelope({
              'completed': true,
              'mainTeamId': 7,
              'followTeamCount': 2,
              'followPlayerCount': 1,
            }),
          ),
          data: {
            'mainTeamId': 7,
            'followTeamIds': [7, 8],
            'followPlayerIds': [9],
          },
        );

      final options = await api.options();
      expect(options.teams.single.leagueName, isNull);
      expect(options.players.single.teamName, isNull);
      final saved = await api.savePreferences(
        mainTeamId: 7,
        followTeamIds: [7, 8],
        followPlayerIds: [9],
      );
      expect(saved.mainTeamId, 7);
    },
  );
}

Map<String, Object?> _envelope(Object data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
