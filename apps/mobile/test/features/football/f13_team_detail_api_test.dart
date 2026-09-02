import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/team_detail_api.dart';

void main() {
  const base = 'https://api.test';
  late DioAdapter adapter;
  late TeamDetailApi api;

  setUp(() {
    final dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = TeamDetailApi(ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio));
  });

  test('decodes overview players stats honors matches and contents', () async {
    adapter
      ..onGet(
        '$base/api/app/football/teams/40/overview',
        (server) => server.reply(
          200,
          _result({
            'teamId': 40,
            'teamName': '测试球队',
            'seasonId': 20,
            'standing': {'rank': 2, 'points': 30},
            'topScorers': [
              {
                'playerId': 50,
                'playerName': '测试球员',
                'position': 'UNKNOWN_POSITION',
              },
              {'playerId': null},
            ],
            'recentMatches': [_match],
            'recentContents': [_content],
          }),
        ),
        queryParameters: {'seasonId': 20},
      )
      ..onGet(
        '$base/api/app/football/teams/40/players',
        (server) => server.reply(
          200,
          _result(
            _page({
              'playerId': 50,
              'playerName': '测试球员',
              'position': null,
              'squadRole': 'UNKNOWN_ROLE',
            }),
          ),
        ),
        queryParameters: {'seasonId': 20, 'pageNum': 1, 'pageSize': 50},
      )
      ..onGet(
        '$base/api/app/football/teams/40/stats',
        (server) => server.reply(
          200,
          _result({'played': 10, 'avgRating': 7.25, 'shots': null}),
        ),
        queryParameters: {'seasonId': 20, 'stageId': 30},
      )
      ..onGet(
        '$base/api/app/football/teams/40/honors',
        (server) => server.reply(
          200,
          _result([
            {
              'honorId': 60,
              'honorName': '测试冠军',
              'honorType': 'UNKNOWN_HONOR',
              'winningYears': [2025, null],
            },
          ]),
        ),
      )
      ..onGet(
        '$base/api/app/football/teams/40/matches',
        (server) => server.reply(200, _result(_page(_match))),
        queryParameters: {'pageNum': 1, 'pageSize': 20},
      )
      ..onGet(
        '$base/api/app/football/teams/40/contents',
        (server) => server.reply(200, _result(_page(_content))),
        queryParameters: {'pageNum': 1, 'pageSize': 20},
      );

    final overview = await api.overview(40, seasonId: 20);
    final players = await api.players(40, seasonId: 20);
    final stats = await api.stats(40, seasonId: 20, stageId: 30);
    final honors = await api.honors(40);
    final matches = await api.matches(40);
    final contents = await api.contents(40);

    expect(overview.standing?.rank, 2);
    expect(overview.topScorers.single.position, 'UNKNOWN_POSITION');
    expect(players.records.single.squadRole, 'UNKNOWN_ROLE');
    expect(stats.averageRating, 7.25);
    expect(stats.shots, isNull);
    expect(honors.single.rawType, 'UNKNOWN_HONOR');
    expect(honors.single.winningYears, [2025]);
    expect(matches.records.single.homeTeam.id, 40);
    expect(contents.records.single.rawType, 'ARTICLE');
  });
}

const _match = <String, Object?>{
  'matchId': 70,
  'leagueId': 10,
  'leagueName': '测试联赛',
  'homeTeamId': 40,
  'homeTeamName': '测试球队',
  'awayTeamId': 41,
  'awayTeamName': '对手',
  'matchStatus': 'UNKNOWN_STATUS',
};

const _content = <String, Object?>{
  'contentId': 80,
  'contentType': 'ARTICLE',
  'title': '球队动态',
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
