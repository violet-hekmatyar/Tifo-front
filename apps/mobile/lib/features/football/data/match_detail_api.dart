import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/football_models.dart';
import '../domain/match_detail_models.dart';

final class MatchDetailApi {
  const MatchDetailApi(this._client);
  final ApiClient _client;

  Future<MatchOverviewV1> overview(int id) =>
      _client.get('/api/app/football/matches/$id/overview', decode: _overview);
  Future<MatchLineups> lineups(int id) =>
      _client.get('/api/app/football/matches/$id/lineups', decode: _lineups);
  Future<List<MatchTeamStatItem>> stats(int id) => _client.get(
    '/api/app/football/matches/$id/stats',
    decode: (raw) => jsonList(raw, _teamStat),
  );
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int id, {
    int? teamId,
    String? position,
    int pageNum = 1,
    int pageSize = 50,
  }) => _client.get(
    '/api/app/football/matches/$id/player-stats',
    queryParameters: {
      'teamId': ?teamId,
      if (position != null && position.isNotEmpty) 'position': position,
      'pageNum': pageNum,
      'pageSize': pageSize,
    },
    decode: (raw) => _page(raw, _playerStat),
  );
  Future<List<MatchRatingSummary>> ratings(int id, {int? teamId}) =>
      _client.get(
        '/api/app/football/matches/$id/ratings',
        queryParameters: {'teamId': ?teamId},
        decode: (raw) => jsonList(raw, _rating),
      );
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) => _client.post(
    '/api/app/football/matches/$matchId/players/$playerId/ratings',
    body: {'rating': rating},
    decode: _ratingResult,
  );
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) =>
      _client.delete(
        '/api/app/football/matches/$matchId/players/$playerId/ratings',
        decode: _ratingResult,
      );
}

Map<Object?, Object?> _map(Object? raw, String name) =>
    jsonMap(raw) ?? (throw ParseException('$name data is invalid.'));

MatchOverviewV1 _overview(Object? raw) {
  final m = _map(raw, 'Match overview');
  final match = jsonMap(m['match']);
  final id = jsonInt(match?['matchId']);
  if (id == null) throw const ParseException('Match overview id is invalid.');
  return MatchOverviewV1(
    matchId: id,
    lineups: _lineups(m['lineups']),
    teamStats: jsonList(m['teamStats'], _teamStat),
    playerStats: _page(m['playerStats'], _playerStat),
    ratings: jsonList(m['ratings'], _rating),
    ranking: _ranking(m['ranking']),
  );
}

MatchLineups _lineups(Object? raw) {
  final m = _map(raw, 'Match lineups');
  return MatchLineups(
    home: _teamLineup(m['home']),
    away: _teamLineup(m['away']),
  );
}

MatchTeamLineup? _teamLineup(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['teamId']);
  if (m == null || id == null) return null;
  return MatchTeamLineup(
    teamId: id,
    teamName: jsonString(m['teamName']) ?? '球队 $id',
    teamLogoUrl: jsonString(m['teamLogoUrl']),
    formation: jsonString(m['formation']),
    coachName: jsonString(m['coachName']),
    starters: jsonList(m['starters'], _lineupPlayer),
    substitutes: jsonList(m['substitutes'], _lineupPlayer),
    bench: jsonList(m['bench'], _lineupPlayer),
  );
}

MatchLineupPlayer? _lineupPlayer(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['playerId']);
  if (m == null || id == null) return null;
  return MatchLineupPlayer(
    playerId: id,
    playerName: jsonString(m['playerName']) ?? '球员 $id',
    avatarUrl: jsonString(m['avatarUrl']),
    position: jsonString(m['position']),
    shirtNumber: jsonInt(m['shirtNumber']),
    captain: m['captain'] == true,
    started: m['started'] == true,
    appeared: m['appeared'] == true,
    substitutedInMinute: jsonInt(m['substitutedInMinute']),
    substitutedOutMinute: jsonInt(m['substitutedOutMinute']),
  );
}

MatchTeamStatItem? _teamStat(Object? raw) {
  final m = jsonMap(raw);
  if (m == null) return null;
  return MatchTeamStatItem(
    rawType: jsonString(m['statType']) ?? 'UNKNOWN',
    displayName: jsonString(m['displayName']) ?? '未知统计',
    homeValue: m['homeValue'],
    awayValue: m['awayValue'],
    unit: jsonString(m['unit']),
  );
}

MatchPlayerStat? _playerStat(Object? raw) {
  final m = jsonMap(raw);
  final playerId = jsonInt(m?['playerId']);
  final teamId = jsonInt(m?['teamId']);
  if (m == null || playerId == null || teamId == null) return null;
  return MatchPlayerStat(
    playerId: playerId,
    playerName: jsonString(m['playerName']) ?? '球员 $playerId',
    teamId: teamId,
    teamName: jsonString(m['teamName']),
    avatarUrl: jsonString(m['avatarUrl']),
    position: jsonString(m['position']),
    shirtNumber: jsonInt(m['shirtNumber']),
    starter: m['starter'] == true,
    captain: m['captain'] == true,
    minutes: jsonInt(m['minutes']),
    goals: jsonInt(m['goals']),
    assists: jsonInt(m['assists']),
    shots: jsonInt(m['shots']),
    shotsOnTarget: jsonInt(m['shotsOnTarget']),
    passes: jsonInt(m['passes']),
    successfulPasses: jsonInt(m['successfulPasses']),
    passAccuracy: jsonDouble(m['passAccuracy']),
    keyPasses: jsonInt(m['keyPasses']),
    tackles: jsonInt(m['tackles']),
    interceptions: jsonInt(m['interceptions']),
    saves: jsonInt(m['saves']),
    yellowCards: jsonInt(m['yellowCards']),
    redCards: jsonInt(m['redCards']),
    officialRating: jsonDouble(m['officialRating']),
    userRatingAverage: jsonDouble(m['userRatingAverage']),
    userRatingCount: jsonInt(m['userRatingCount']) ?? 0,
    currentUserRating: jsonDouble(m['currentUserRating']),
  );
}

MatchRatingSummary? _rating(Object? raw) {
  final m = jsonMap(raw);
  final playerId = jsonInt(m?['playerId']);
  final teamId = jsonInt(m?['teamId']);
  if (m == null || playerId == null || teamId == null) return null;
  final distribution = jsonMap(m['distribution']);
  return MatchRatingSummary(
    playerId: playerId,
    playerName: jsonString(m['playerName']) ?? '球员 $playerId',
    teamId: teamId,
    officialRating: jsonDouble(m['officialRating']),
    averageRating: jsonDouble(m['averageRating']),
    ratingCount: jsonInt(m['ratingCount']) ?? 0,
    currentUserRating: jsonDouble(m['currentUserRating']),
    distribution: {
      if (distribution != null)
        for (final entry in distribution.entries)
          if (entry.key is String && jsonInt(entry.value) != null)
            entry.key as String: jsonInt(entry.value)!,
    },
  );
}

MatchRanking? _ranking(Object? raw) {
  final m = jsonMap(raw);
  if (m == null) return null;
  return MatchRanking(
    snapshotType: jsonString(m['snapshotType']) ?? 'UNKNOWN',
    leagueName: jsonString(m['leagueName']),
    seasonName: jsonString(m['seasonName']),
    stageName: jsonString(m['stageName']),
    home: _standing(m['home']),
    away: _standing(m['away']),
  );
}

MatchStandingSnapshot? _standing(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['teamId']);
  if (m == null || id == null) return null;
  return MatchStandingSnapshot(
    teamId: id,
    teamName: jsonString(m['teamName']) ?? '球队 $id',
    rank: jsonInt(m['rank']),
    played: jsonInt(m['played']),
    won: jsonInt(m['won']),
    drawn: jsonInt(m['drawn']),
    lost: jsonInt(m['lost']),
    goalsFor: jsonInt(m['goalsFor']),
    goalsAgainst: jsonInt(m['goalsAgainst']),
    goalDifference: jsonInt(m['goalDifference']),
    points: jsonInt(m['points']),
  );
}

MatchRatingResult _ratingResult(Object? raw) {
  final m = _map(raw, 'Rating result');
  final matchId = jsonInt(m['matchId']);
  final playerId = jsonInt(m['playerId']);
  if (matchId == null || playerId == null) {
    throw const ParseException('Rating result id is invalid.');
  }
  return MatchRatingResult(
    matchId: matchId,
    playerId: playerId,
    myRating: jsonDouble(m['myRating']),
    averageRating: jsonDouble(m['averageRating']),
    ratingCount: jsonInt(m['ratingCount']) ?? 0,
    updatedAt: jsonIsoDateTime(m['updatedAt']),
  );
}

FootballPage<T> _page<T>(Object? raw, T? Function(Object?) decode) {
  final page = PageResult.fromRaw(raw, (value) {
    final item = decode(value);
    if (item == null) throw const ParseException('Match page item is invalid.');
    return item;
  });
  return FootballPage(
    records: page.records,
    pageNum: page.pageNum,
    pages: page.pages,
    total: page.total,
  );
}
