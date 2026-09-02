import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/football_models.dart';
import '../domain/player_detail_models.dart';
import '../domain/team_detail_models.dart';

final class PlayerDetailApi {
  const PlayerDetailApi(this._client);
  final ApiClient _client;

  Future<PlayerOverview> overview(int playerId, {int? seasonId}) => _client.get(
    '/api/app/football/players/$playerId/overview',
    queryParameters: _query({'seasonId': seasonId}),
    decode: _overview,
  );
  Future<List<PlayerSeasonStats>> stats(
    int playerId, {
    int? leagueId,
    int? seasonId,
    int? stageId,
  }) => _client.get(
    '/api/app/football/players/$playerId/stats',
    queryParameters: _query({
      'leagueId': leagueId,
      'seasonId': seasonId,
      'stageId': stageId,
    }),
    decode: (raw) => jsonList(raw, _stats),
  );
  Future<List<PlayerTeamHistory>> teams(int playerId) => _client.get(
    '/api/app/football/players/$playerId/teams',
    decode: (raw) => jsonList(raw, _history),
  );
  Future<PlayerCareer> career(int playerId) => _client.get(
    '/api/app/football/players/$playerId/career',
    decode: _career,
  );
  Future<FootballPage<FootballMatch>> matches(
    int playerId, {
    int pageNum = 1,
    int pageSize = 20,
  }) => _page(
    '/api/app/football/players/$playerId/matches',
    pageNum,
    pageSize,
    _match,
  );
  Future<FootballPage<TeamContentSummary>> contents(
    int playerId, {
    int pageNum = 1,
    int pageSize = 20,
  }) => _page(
    '/api/app/football/players/$playerId/contents',
    pageNum,
    pageSize,
    _content,
  );

  Future<FootballPage<T>> _page<T>(
    String path,
    int pageNum,
    int pageSize,
    T Function(Object?) decode,
  ) async {
    final result = await _client.get(
      path,
      queryParameters: {'pageNum': pageNum, 'pageSize': pageSize},
      decode: (raw) => PageResult.fromRaw(raw, decode),
    );
    return FootballPage(
      records: result.records,
      pageNum: result.pageNum,
      pages: result.pages,
      total: result.total,
    );
  }
}

Map<String, dynamic> _query(Map<String, Object?> values) => {
  for (final entry in values.entries)
    if (entry.value != null) entry.key: entry.value,
};
Map<Object?, Object?> _map(Object? raw, String target) =>
    jsonMap(raw) ?? (throw ParseException('$target data is invalid.'));

PlayerOverview _overview(Object? raw) {
  final m = _map(raw, 'Player overview');
  final id = jsonInt(m['playerId']);
  if (id == null) throw const ParseException('Player overview id is invalid.');
  return PlayerOverview(
    id: id,
    name: jsonString(m['playerName']) ?? '球员 $id',
    nameEn: jsonString(m['playerNameEn']),
    avatarUrl: jsonString(m['avatarUrl']),
    position: jsonString(m['position']),
    nationality: jsonString(m['nationality']),
    birthDate: jsonIsoDateTime(m['birthDate']),
    age: jsonInt(m['age']),
    height: jsonInt(m['height']),
    weight: jsonInt(m['weight']),
    preferredFoot: jsonString(m['preferredFoot']),
    shirtNumber: jsonInt(m['shirtNumber']),
    captain: m['captain'] == true,
    followed: m['followed'] == true,
    retired: m['retired'] == true,
    rawStatus: jsonString(m['playerStatus']),
    club: _teamLink(m['club']),
    nationalTeam: _teamLink(m['nationalTeam']),
    seasonStats: jsonList(m['seasonStats'], _stats),
    recentMatches: jsonList(m['recentMatches'], _safeMatch),
    recentContents: jsonList(m['recentContents'], _safeContent),
  );
}

PlayerTeamLink? _teamLink(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['teamId']);
  if (m == null || id == null) return null;
  return PlayerTeamLink(
    id: id,
    name: jsonString(m['teamName']) ?? '球队 $id',
    logoUrl: jsonString(m['logoUrl']),
    rawType: jsonString(m['teamType']),
    shirtNumber: jsonInt(m['shirtNumber']),
  );
}

PlayerSeasonStats? _stats(Object? raw) {
  final m = jsonMap(raw);
  if (m == null) return null;
  return PlayerSeasonStats(
    leagueId: jsonInt(m['leagueId']),
    leagueName: jsonString(m['leagueName']),
    seasonId: jsonInt(m['seasonId']),
    seasonName: jsonString(m['seasonName']),
    teamId: jsonInt(m['teamId']),
    teamName: jsonString(m['teamName']),
    appearances: jsonInt(m['appearances']),
    starts: jsonInt(m['starts']),
    minutes: jsonInt(m['minutes']),
    goals: jsonInt(m['goals']),
    assists: jsonInt(m['assists']),
    yellowCards: jsonInt(m['yellowCards']),
    redCards: jsonInt(m['redCards']),
    shots: jsonInt(m['shots']),
    shotsOnTarget: jsonInt(m['shotsOnTarget']),
    shotAccuracy: jsonDouble(m['shotAccuracy']),
    rating: jsonDouble(m['rating']),
    saves: jsonInt(m['saves']),
    source: jsonString(m['source']),
    updatedAt: jsonIsoDateTime(m['updatedAt']),
  );
}

PlayerTeamHistory? _history(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['teamId']);
  if (m == null || id == null) return null;
  return PlayerTeamHistory(
    teamId: id,
    teamName: jsonString(m['teamName']) ?? '球队 $id',
    teamLogoUrl: jsonString(m['teamLogoUrl']),
    seasonId: jsonInt(m['seasonId']),
    seasonName: jsonString(m['seasonName']),
    startDate: jsonIsoDateTime(m['startDate']),
    endDate: jsonIsoDateTime(m['endDate']),
    shirtNumber: jsonInt(m['shirtNumber']),
    position: jsonString(m['position']),
    appearances: jsonInt(m['appearances']),
    goals: jsonInt(m['goals']),
    assists: jsonInt(m['assists']),
    current: m['current'] == true,
    loan: m['loan'] == true,
  );
}

PlayerCareer _career(Object? raw) {
  final m = _map(raw, 'Player career');
  return PlayerCareer(
    totalAppearances: jsonInt(m['totalAppearances']),
    totalStarts: jsonInt(m['totalStarts']),
    totalMinutes: jsonInt(m['totalMinutes']),
    totalGoals: jsonInt(m['totalGoals']),
    totalAssists: jsonInt(m['totalAssists']),
    totalYellowCards: jsonInt(m['totalYellowCards']),
    totalRedCards: jsonInt(m['totalRedCards']),
    totalShots: jsonInt(m['totalShots']),
    totalShotsOnTarget: jsonInt(m['totalShotsOnTarget']),
    averageRating: jsonDouble(m['averageRating']),
    totalSaves: jsonInt(m['totalSaves']),
    teamCount: jsonInt(m['teamCount']),
    seasonCount: jsonInt(m['seasonCount']),
    bySeason: jsonList(m['bySeason'], _careerGroup),
    byTeam: jsonList(m['byTeam'], _careerGroup),
  );
}

PlayerCareerGroup? _careerGroup(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['id']);
  if (m == null || id == null) return null;
  return PlayerCareerGroup(
    id: id,
    name: jsonString(m['name']) ?? '记录 $id',
    appearances: jsonInt(m['appearances']),
    starts: jsonInt(m['starts']),
    minutes: jsonInt(m['minutes']),
    goals: jsonInt(m['goals']),
    assists: jsonInt(m['assists']),
    averageRating: jsonDouble(m['averageRating']),
  );
}

FootballMatch _match(Object? raw) =>
    _safeMatch(raw) ?? (throw const ParseException('Player match is invalid.'));
FootballMatch? _safeMatch(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['matchId']);
  final leagueId = jsonInt(m?['leagueId']);
  final homeId = jsonInt(m?['homeTeamId']);
  final awayId = jsonInt(m?['awayTeamId']);
  if (m == null ||
      id == null ||
      leagueId == null ||
      homeId == null ||
      awayId == null) {
    return null;
  }
  return FootballMatch(
    id: id,
    leagueId: leagueId,
    leagueName: jsonString(m['leagueName']) ?? '赛事',
    homeTeam: FootballTeam(
      id: homeId,
      name: jsonString(m['homeTeamName']) ?? '主队',
      logoUrl: jsonString(m['homeTeamLogoUrl']),
      score: jsonInt(m['homeScore']),
    ),
    awayTeam: FootballTeam(
      id: awayId,
      name: jsonString(m['awayTeamName']) ?? '客队',
      logoUrl: jsonString(m['awayTeamLogoUrl']),
      score: jsonInt(m['awayScore']),
    ),
    status: jsonString(m['matchStatus']) ?? 'UNKNOWN',
    matchTime: jsonIsoDateTime(m['matchTime']),
  );
}

TeamContentSummary _content(Object? raw) =>
    _safeContent(raw) ??
    (throw const ParseException('Player content is invalid.'));
TeamContentSummary? _safeContent(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['contentId']);
  if (m == null || id == null) return null;
  return TeamContentSummary(
    id: id,
    title: jsonString(m['title']) ?? '未命名内容',
    rawType: jsonString(m['contentType']) ?? 'UNKNOWN',
    summary: jsonString(m['summary']),
    coverUrl: jsonString(m['coverUrl']),
    publishTime: jsonIsoDateTime(m['publishTime']),
    likeCount: jsonInt(m['likeCount']) ?? 0,
    commentCount: jsonInt(m['commentCount']) ?? 0,
    favoriteCount: jsonInt(m['favoriteCount']) ?? 0,
  );
}
