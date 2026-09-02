import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/football_api.dart';
import 'package:tifo/features/football/domain/football_ranking_models.dart';

void main() {
  const base = 'https://api.test';
  late Dio dio;
  late DioAdapter adapter;
  late FootballApi api;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = FootballApi(ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio));
  });

  test('decodes seasons stages and standings with nullable fields', () async {
    adapter
      ..onGet(
        '$base/api/app/football/leagues/10/seasons',
        (server) => server.reply(
          200,
          _result([
            {
              'seasonId': 20,
              'leagueId': 10,
              'seasonName': '当前赛季',
              'current': true,
              'status': 'ACTIVE',
            },
            {'seasonId': null, 'leagueId': 10},
          ]),
        ),
      )
      ..onGet(
        '$base/api/app/football/leagues/10/seasons/20/stages',
        (server) => server.reply(
          200,
          _result([
            {
              'stageId': 30,
              'stageType': 'UNKNOWN_STAGE',
              'stageName': '联赛阶段',
              'groupCode': null,
            },
          ]),
        ),
      )
      ..onGet(
        '$base/api/app/football/standings',
        (server) => server.reply(
          200,
          _result({
            'leagueId': 10,
            'seasonId': 20,
            'stageId': 30,
            'records': [
              {
                'rank': 1,
                'teamId': 40,
                'teamName': '测试球队',
                'played': null,
                'points': 9,
              },
              {'teamId': null},
            ],
          }),
        ),
        queryParameters: {'leagueId': 10, 'seasonId': 20, 'stageId': 30},
      );

    final seasons = await api.seasons(10);
    final stages = await api.stages(10, 20);
    final table = await api.standings(leagueId: 10, seasonId: 20, stageId: 30);
    expect(seasons, hasLength(1));
    expect(seasons.single.current, isTrue);
    expect(stages.single.rawType, 'UNKNOWN_STAGE');
    expect(table.records, hasLength(1));
    expect(table.records.single.played, 0);
    expect(table.records.single.points, 9);
  });

  test('uses frozen rankType values and decodes paged ranks', () async {
    adapter
      ..onGet(
        '$base/api/app/football/player-ranks',
        (server) => server.reply(
          200,
          _result(
            _page({
              'rank': 1,
              'playerId': 50,
              'playerName': '测试球员',
              'value': 3.5,
              'displayValue': null,
            }),
          ),
        ),
        queryParameters: {
          'leagueId': 10,
          'seasonId': 20,
          'rankType': 'RATING',
          'pageNum': 1,
          'pageSize': 20,
        },
      )
      ..onGet(
        '$base/api/app/football/team-ranks',
        (server) => server.reply(
          200,
          _result(
            _page({
              'rank': 1,
              'teamId': 40,
              'teamName': '测试球队',
              'value': 1,
              'sortDirection': 'ASC',
            }),
          ),
        ),
        queryParameters: {
          'leagueId': 10,
          'seasonId': 20,
          'rankType': 'GOALS_AGAINST',
          'pageNum': 1,
          'pageSize': 20,
        },
      );

    final players = await api.playerRanks(
      leagueId: 10,
      seasonId: 20,
      rankType: PlayerRankType.rating,
      pageNum: 1,
      pageSize: 20,
    );
    final teams = await api.teamRanks(
      leagueId: 10,
      seasonId: 20,
      rankType: TeamRankType.goalsAgainst,
      pageNum: 1,
      pageSize: 20,
    );
    expect(players.records.single.value, 3.5);
    expect(teams.records.single.sortDirection, 'ASC');
  });
}

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
