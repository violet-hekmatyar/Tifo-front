import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/football_models.dart';
import '../domain/team_detail_models.dart';

final class TeamDetailApi {
  const TeamDetailApi(this._client);
  final ApiClient _client;

  Future<TeamOverview> overview(int teamId, {int? seasonId}) => _client.get(
    '/api/app/football/teams/$teamId/overview',
    queryParameters: _query({'seasonId': seasonId}),
    decode: _overview,
  );

  Future<FootballPage<TeamRosterPlayer>> players(
    int teamId, {
    int? seasonId,
    int pageNum = 1,
    int pageSize = 50,
  }) => _page('/api/app/football/teams/$teamId/players', {
    'seasonId': seasonId,
    'pageNum': pageNum,
    'pageSize': pageSize,
  }, _rosterPlayer);

  Future<TeamStats> stats(int teamId, {int? seasonId, int? stageId}) =>
      _client.get(
        '/api/app/football/teams/$teamId/stats',
        queryParameters: _query({'seasonId': seasonId, 'stageId': stageId}),
        decode: _stats,
      );

  Future<List<TeamHonor>> honors(int teamId) => _client.get(
    '/api/app/football/teams/$teamId/honors',
    decode: (raw) => jsonList(raw, _honor),
  );

  Future<FootballPage<FootballMatch>> matches(
    int teamId, {
    int pageNum = 1,
    int pageSize = 20,
  }) => _page('/api/app/football/teams/$teamId/matches', {
    'pageNum': pageNum,
    'pageSize': pageSize,
  }, _detailMatch);

  Future<FootballPage<TeamContentSummary>> contents(
    int teamId, {
    int pageNum = 1,
    int pageSize = 20,
  }) => _page('/api/app/football/teams/$teamId/contents', {
    'pageNum': pageNum,
    'pageSize': pageSize,
  }, _content);

  Future<FootballPage<T>> _page<T>(
    String path,
    Map<String, Object?> query,
    T Function(Object?) decode,
  ) async {
    final result = await _client.get(
      path,
      queryParameters: _query(query),
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

Map<Object?, Object?> _requiredMap(Object? raw, String target) =>
    jsonMap(raw) ?? (throw ParseException('$target data is invalid.'));

TeamOverview _overview(Object? raw) {
  final m = _requiredMap(raw, 'Team overview');
  final id = jsonInt(m['teamId']);
  if (id == null) throw const ParseException('Team overview id is invalid.');
  return TeamOverview(
    teamId: id,
    teamName: jsonString(m['teamName']) ?? '球队 $id',
    leagueId: jsonInt(m['leagueId']),
    leagueName: jsonString(m['leagueName']),
    seasonId: jsonInt(m['seasonId']),
    seasonName: jsonString(m['seasonName']),
    city: jsonString(m['city']),
    stadium: jsonString(m['stadium']),
    foundedYear: jsonInt(m['foundedYear']),
    description: jsonString(m['description']),
    followed: m['followed'] == true,
    standing: jsonMap(m['standing']) == null ? null : _standing(m['standing']),
    seasonStats: jsonMap(m['seasonStats']) == null
        ? null
        : _stats(m['seasonStats']),
    topScorers: jsonList(m['topScorers'], _safeRosterPlayer),
    topAssists: jsonList(m['topAssists'], _safeRosterPlayer),
    recentMatches: jsonList(m['recentMatches'], _safeOverviewMatch),
    nextMatch: _safeOverviewMatch(m['nextMatch']),
    recentContents: jsonList(m['recentContents'], _safeContent),
  );
}

TeamRosterPlayer _rosterPlayer(Object? raw) =>
    _safeRosterPlayer(raw) ??
    (throw const ParseException('Roster player is invalid.'));

TeamRosterPlayer? _safeRosterPlayer(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['playerId']);
  if (m == null || id == null) return null;
  return TeamRosterPlayer(
    id: id,
    name: jsonString(m['playerName']) ?? '球员 $id',
    nameEn: jsonString(m['playerNameEn']),
    avatarUrl: jsonString(m['avatarUrl']),
    position: jsonString(m['position']),
    shirtNumber: jsonInt(m['shirtNumber']),
    captain: m['captain'] == true,
    loan: m['loan'] == true,
    loanFromTeamName: jsonString(m['loanFromTeamName']),
    squadRole: jsonString(m['squadRole']),
    appearances: jsonInt(m['appearances']),
    starts: jsonInt(m['starts']),
    minutes: jsonInt(m['minutes']),
    goals: jsonInt(m['goals']),
    assists: jsonInt(m['assists']),
    rating: jsonDouble(m['rating']),
    followed: m['followed'] == true,
  );
}

TeamStats _stats(Object? raw) {
  final m = _requiredMap(raw, 'Team stats');
  return TeamStats(
    played: jsonInt(m['played']),
    goalsFor: jsonInt(m['goalsFor']),
    goalsAgainst: jsonInt(m['goalsAgainst']),
    goalDifference: jsonInt(m['goalDifference']),
    assists: jsonInt(m['assists']),
    shots: jsonInt(m['shots']),
    shotsOnTarget: jsonInt(m['shotsOnTarget']),
    shotAccuracy: jsonDouble(m['shotAccuracy']),
    corners: jsonInt(m['corners']),
    fouls: jsonInt(m['fouls']),
    yellowCards: jsonInt(m['yellowCards']),
    redCards: jsonInt(m['redCards']),
    cleanSheets: jsonInt(m['cleanSheets']),
    averageRating: jsonDouble(m['avgRating']),
    standingRank: jsonInt(m['standingRank']),
    points: jsonInt(m['points']),
    source: jsonString(m['source']),
    updatedAt: jsonIsoDateTime(m['updatedAt']),
  );
}

TeamStandingSummary _standing(Object? raw) {
  final m = _requiredMap(raw, 'Team standing');
  return TeamStandingSummary(
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

TeamHonor? _honor(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['honorId']);
  if (m == null || id == null) return null;
  return TeamHonor(
    id: id,
    name: jsonString(m['honorName']) ?? '荣誉 $id',
    rawType: jsonString(m['honorType']),
    titleCount: jsonInt(m['titleCount']),
    winningYears: jsonList(m['winningYears'], jsonInt),
    latestYear: jsonInt(m['latestYear']),
  );
}

FootballMatch _detailMatch(Object? raw) =>
    _safeMatch(raw, detailed: true) ??
    (throw const ParseException('Team match is invalid.'));

FootballMatch? _safeOverviewMatch(Object? raw) =>
    _safeMatch(raw, detailed: false);

FootballMatch? _safeMatch(Object? raw, {required bool detailed}) {
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
    (throw const ParseException('Team content is invalid.'));

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
