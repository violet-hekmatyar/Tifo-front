import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/player_detail_api.dart';

void main() {
  const base = 'https://api.test';
  late DioAdapter adapter;
  late PlayerDetailApi api;

  setUp(() {
    final dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = PlayerDetailApi(
      ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio),
    );
  });

  test(
    'decodes all player detail resources with nullable and unknown data',
    () async {
      adapter
        ..onGet(
          '$base/api/app/football/players/50/overview',
          (server) => server.reply(
            200,
            _result({
              'playerId': 50,
              'playerName': '测试球员',
              'position': 'UNKNOWN_POSITION',
              'retired': true,
              'playerStatus': 'UNKNOWN_STATUS',
              'club': {'teamId': 40, 'teamName': '测试球队'},
              'nationalTeam': null,
              'seasonStats': [_stats],
              'recentMatches': [_match],
              'recentContents': [_content],
            }),
          ),
          queryParameters: {'seasonId': 20},
        )
        ..onGet(
          '$base/api/app/football/players/50/stats',
          (server) => server.reply(200, _result([_stats])),
          queryParameters: {'leagueId': 10, 'seasonId': 20, 'stageId': 30},
        )
        ..onGet(
          '$base/api/app/football/players/50/teams',
          (server) => server.reply(
            200,
            _result([
              {
                'teamId': 40,
                'teamName': '测试球队',
                'current': true,
                'loan': false,
              },
            ]),
          ),
        )
        ..onGet(
          '$base/api/app/football/players/50/career',
          (server) => server.reply(
            200,
            _result({
              'totalAppearances': 12,
              'averageRating': 7.25,
              'byTeam': [
                {'id': 40, 'name': '测试球队', 'goals': 3},
              ],
            }),
          ),
        )
        ..onGet(
          '$base/api/app/football/players/50/matches',
          (server) => server.reply(200, _result(_page(_match))),
          queryParameters: {'pageNum': 1, 'pageSize': 20},
        )
        ..onGet(
          '$base/api/app/football/players/50/contents',
          (server) => server.reply(200, _result(_page(_content))),
          queryParameters: {'pageNum': 1, 'pageSize': 20},
        );

      final overview = await api.overview(50, seasonId: 20);
      final stats = await api.stats(
        50,
        leagueId: 10,
        seasonId: 20,
        stageId: 30,
      );
      final teams = await api.teams(50);
      final career = await api.career(50);
      final matches = await api.matches(50);
      final contents = await api.contents(50);

      expect(overview.retired, isTrue);
      expect(overview.rawStatus, 'UNKNOWN_STATUS');
      expect(overview.nationalTeam, isNull);
      expect(overview.club?.id, 40);
      expect(stats.single.rating, 7.25);
      expect(teams.single.current, isTrue);
      expect(career.byTeam.single.id, 40);
      expect(matches.records.single.status, 'UNKNOWN_MATCH_STATUS');
      expect(contents.records.single.rawType, 'UNKNOWN_CONTENT_TYPE');
    },
  );
}

const _stats = <String, Object?>{
  'leagueId': 10,
  'seasonId': 20,
  'appearances': 12,
  'rating': 7.25,
  'updatedAt': '2026-07-20T12:00:00',
};
const _match = <String, Object?>{
  'matchId': 70,
  'leagueId': 10,
  'leagueName': '测试联赛',
  'homeTeamId': 40,
  'homeTeamName': '测试球队',
  'awayTeamId': 41,
  'awayTeamName': '对手',
  'matchStatus': 'UNKNOWN_MATCH_STATUS',
};
const _content = <String, Object?>{
  'contentId': 80,
  'contentType': 'UNKNOWN_CONTENT_TYPE',
  'title': '球员动态',
};
Map<String, Object?> _result(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
Map<String, Object?> _page(Map<String, Object?> record) => {
  'records': [record],
  'total': 1,
  'pageNum': 1,
  'pageSize': 20,
  'pages': 1,
};
