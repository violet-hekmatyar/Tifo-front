import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/match_detail_api.dart';

void main() {
  const base = 'https://api.test';
  late DioAdapter adapter;
  late MatchDetailApi api;
  setUp(() {
    final dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = MatchDetailApi(
      ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio),
    );
  });

  test('decodes overview and all match tab contracts safely', () async {
    adapter
      ..onGet(
        '$base/api/app/football/matches/70/overview',
        (s) => s.reply(200, _result(_overview)),
      )
      ..onGet(
        '$base/api/app/football/matches/70/lineups',
        (s) => s.reply(200, _result(_lineups)),
      )
      ..onGet(
        '$base/api/app/football/matches/70/stats',
        (s) => s.reply(200, _result([_teamStat])),
      )
      ..onGet(
        '$base/api/app/football/matches/70/player-stats',
        (s) => s.reply(200, _result(_page(_playerStat))),
        queryParameters: {'pageNum': 1, 'pageSize': 50},
      )
      ..onGet(
        '$base/api/app/football/matches/70/ratings',
        (s) => s.reply(200, _result([_rating])),
      )
      ..onPost(
        '$base/api/app/football/matches/70/players/50/ratings',
        (s) => s.reply(200, _result(_ratingResult(8.5))),
        data: {'rating': 8.5},
      )
      ..onDelete(
        '$base/api/app/football/matches/70/players/50/ratings',
        (s) => s.reply(200, _result(_ratingResult(null))),
      );

    final overview = await api.overview(70);
    final lineups = await api.lineups(70);
    final stats = await api.stats(70);
    final players = await api.playerStats(70);
    final ratings = await api.ratings(70);
    final submitted = await api.submitRating(70, 50, 8.5);
    final cancelled = await api.cancelRating(70, 50);

    expect(overview.ranking?.snapshotType, 'CURRENT_STANDING');
    expect(lineups.home?.starters.single.position, 'UNKNOWN_POSITION');
    expect(stats.single.rawType, 'UNKNOWN_STAT');
    expect(players.records.single.playerId, 50);
    expect(ratings.single.distribution['8.5-10.0'], 1);
    expect(submitted.myRating, 8.5);
    expect(cancelled.myRating, isNull);
  });
}

const _lineups = <String, Object?>{
  'home': {
    'teamId': 40,
    'teamName': '主队',
    'starters': [
      {'playerId': 50, 'playerName': '测试球员', 'position': 'UNKNOWN_POSITION'},
    ],
    'substitutes': [],
    'bench': [],
  },
  'away': {
    'teamId': 41,
    'teamName': '客队',
    'starters': [],
    'substitutes': [],
    'bench': [],
  },
};
const _teamStat = <String, Object?>{
  'statType': 'UNKNOWN_STAT',
  'displayName': '未知统计',
  'homeValue': 4,
  'awayValue': null,
};
const _playerStat = <String, Object?>{
  'playerId': 50,
  'playerName': '测试球员',
  'teamId': 40,
  'teamName': '主队',
  'officialRating': 7.4,
};
const _rating = <String, Object?>{
  'playerId': 50,
  'playerName': '测试球员',
  'teamId': 40,
  'officialRating': 7.4,
  'averageRating': 8.5,
  'ratingCount': 1,
  'distribution': {'8.5-10.0': 1},
};
const _overview = <String, Object?>{
  'match': {'matchId': 70},
  'lineups': _lineups,
  'teamStats': [_teamStat],
  'playerStats': {
    'records': [_playerStat],
    'total': 1,
    'pageNum': 1,
    'pageSize': 50,
    'pages': 1,
  },
  'ratings': [_rating],
  'ranking': {
    'snapshotType': 'CURRENT_STANDING',
    'home': {'teamId': 40, 'teamName': '主队', 'rank': 1},
    'away': null,
  },
};
Map<String, Object?> _ratingResult(double? value) => {
  'matchId': 70,
  'playerId': 50,
  'myRating': value,
  'averageRating': value,
  'ratingCount': value == null ? 0 : 1,
};
Map<String, Object?> _page(Map<String, Object?> item) => {
  'records': [item],
  'total': 1,
  'pageNum': 1,
  'pageSize': 50,
  'pages': 1,
};
Map<String, Object?> _result(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
