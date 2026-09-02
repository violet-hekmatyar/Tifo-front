import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/football_models.dart';
import '../domain/football_ranking_models.dart';

final class FootballApi {
  const FootballApi(this._client);
  final ApiClient _client;

  Future<List<League>> leagues() => _client.get(
    '/api/app/football/leagues',
    decode: (raw) => _list(raw, _league),
  );

  Future<List<FootballSeason>> seasons(int leagueId) => _client.get(
    '/api/app/football/leagues/$leagueId/seasons',
    decode: (raw) => jsonList(raw, _season),
  );

  Future<List<FootballStage>> stages(int leagueId, int seasonId) => _client.get(
    '/api/app/football/leagues/$leagueId/seasons/$seasonId/stages',
    decode: (raw) => jsonList(raw, _stage),
  );

  Future<StandingTable> standings({
    required int leagueId,
    required int seasonId,
    int? stageId,
    String? groupCode,
  }) => _client.get(
    '/api/app/football/standings',
    queryParameters: {
      'leagueId': leagueId,
      'seasonId': seasonId,
      ..._optional('stageId', stageId),
      ..._optional('groupCode', groupCode),
    },
    decode: _standingTable,
  );

  Future<FootballPage<PlayerRankRecord>> playerRanks({
    required int leagueId,
    required int seasonId,
    required PlayerRankType rankType,
    required int pageNum,
    required int pageSize,
    int? stageId,
  }) => _client.get(
    '/api/app/football/player-ranks',
    queryParameters: {
      'leagueId': leagueId,
      'seasonId': seasonId,
      ..._optional('stageId', stageId),
      'rankType': rankType.wireValue,
      'pageNum': pageNum,
      'pageSize': pageSize,
    },
    decode: (raw) => _rankingPage(raw, _playerRank),
  );

  Future<FootballPage<TeamRankRecord>> teamRanks({
    required int leagueId,
    required int seasonId,
    required TeamRankType rankType,
    required int pageNum,
    required int pageSize,
    int? stageId,
  }) => _client.get(
    '/api/app/football/team-ranks',
    queryParameters: {
      'leagueId': leagueId,
      'seasonId': seasonId,
      ..._optional('stageId', stageId),
      'rankType': rankType.wireValue,
      'pageNum': pageNum,
      'pageSize': pageSize,
    },
    decode: (raw) => _rankingPage(raw, _teamRank),
  );

  Future<FootballPage<FootballMatch>> importantMatches({
    required int pageNum,
    required int pageSize,
    DateTime? date,
  }) => _matchesPage(
    '/api/app/football/matches/important',
    pageNum: pageNum,
    pageSize: pageSize,
    extra: date == null ? const {} : {'date': _date(date)},
  );

  Future<FootballPage<FootballMatch>> followingMatches({
    required int pageNum,
    required int pageSize,
  }) => _matchesPage(
    '/api/app/football/matches/following-teams',
    pageNum: pageNum,
    pageSize: pageSize,
  );

  Future<FootballPage<FootballMatch>> matches({
    required int pageNum,
    required int pageSize,
    int? leagueId,
    int? teamId,
    DateTime? date,
    String? status,
  }) => _matchesPage(
    '/api/app/football/matches',
    pageNum: pageNum,
    pageSize: pageSize,
    extra: {
      ..._optional('leagueId', leagueId),
      ..._optional('teamId', teamId),
      ..._optional('date', date == null ? null : _date(date)),
      ..._optional('status', status),
    },
  );

  Future<FootballPage<FootballMatch>> _matchesPage(
    String path, {
    required int pageNum,
    required int pageSize,
    Map<String, dynamic> extra = const {},
  }) => _client.get(
    path,
    queryParameters: {'pageNum': pageNum, 'pageSize': pageSize, ...extra},
    decode: (raw) {
      final page = PageResult.fromRaw(raw, _match);
      return FootballPage(
        records: page.records,
        pageNum: page.pageNum,
        pages: page.pages,
        total: page.total,
      );
    },
  );

  Future<MatchDetail> matchDetail(int id) =>
      _client.get('/api/app/football/matches/$id', decode: _matchDetail);

  Future<TeamDetail> teamDetail(int id) =>
      _client.get('/api/app/football/teams/$id', decode: _teamDetail);

  Future<PlayerDetail> playerDetail(int id) =>
      _client.get('/api/app/football/players/$id', decode: _playerDetail);
}

FootballPage<T> _rankingPage<T>(Object? raw, T Function(Object?) decode) {
  final page = PageResult.fromRaw(raw, decode);
  return FootballPage(
    records: page.records,
    pageNum: page.pageNum,
    pages: page.pages,
    total: page.total,
  );
}

List<T> _list<T>(Object? raw, T Function(Object?) decode) {
  if (raw is! List) throw const ParseException('List data is invalid.');
  return raw.map(decode).toList(growable: false);
}

Map<Object?, Object?> _map(Object? raw) {
  if (raw is! Map) throw const ParseException('Football data is invalid.');
  return raw;
}

int _id(Map<Object?, Object?> raw, String key) {
  final value = raw[key];
  if (value is! num) throw ParseException('$key is invalid.');
  return value.toInt();
}

String _requiredText(Map<Object?, Object?> raw, String key) {
  final value = raw[key];
  if (value is! String || value.trim().isEmpty) {
    throw ParseException('$key is invalid.');
  }
  return value.trim();
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int? _integer(Object? value) => value is num ? value.toInt() : null;
bool _boolean(Object? value) => value == true;
DateTime? _time(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
Map<String, dynamic> _optional(String key, Object? value) =>
    value == null ? const {} : {key: value};

FootballSeason? _season(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['seasonId']);
  final leagueId = jsonInt(m?['leagueId']);
  if (id == null || leagueId == null) return null;
  return FootballSeason(
    id: id,
    leagueId: leagueId,
    code: jsonString(m?['seasonCode']),
    name:
        jsonString(m?['seasonName']) ??
        jsonString(m?['seasonCode']) ??
        '赛季 $id',
    startDate: jsonIsoDateTime(m?['startDate']),
    endDate: jsonIsoDateTime(m?['endDate']),
    current: m?['current'] == true,
    status: jsonString(m?['status']),
  );
}

FootballStage? _stage(Object? raw) {
  final m = jsonMap(raw);
  final id = jsonInt(m?['stageId']);
  if (id == null) return null;
  return FootballStage(
    id: id,
    name: jsonString(m?['stageName']) ?? '阶段 $id',
    rawType: jsonString(m?['stageType']),
    groupCode: jsonString(m?['groupCode']),
    sortOrder: jsonInt(m?['sortOrder']),
  );
}

StandingTable _standingTable(Object? raw) {
  final m = jsonMap(raw);
  if (m == null) throw const ParseException('Standing table is invalid.');
  return StandingTable(
    leagueId: jsonInt(m['leagueId']),
    leagueName: jsonString(m['leagueName']),
    seasonId: jsonInt(m['seasonId']),
    seasonName: jsonString(m['seasonName']),
    stageId: jsonInt(m['stageId']),
    stageName: jsonString(m['stageName']),
    groupCode: jsonString(m['groupCode']),
    source: jsonString(m['source']),
    updatedAt: jsonIsoDateTime(m['updatedAt']),
    records: jsonList(m['records'], _standingRecord),
  );
}

StandingRecord? _standingRecord(Object? raw) {
  final m = jsonMap(raw);
  final teamId = jsonInt(m?['teamId']);
  if (m == null || teamId == null) return null;
  return StandingRecord(
    rank: jsonInt(m['rank']) ?? 0,
    teamId: teamId,
    teamName: jsonString(m['teamName']) ?? '球队 $teamId',
    teamLogoUrl: jsonString(m['teamLogoUrl']),
    played: jsonInt(m['played']) ?? 0,
    won: jsonInt(m['won']) ?? 0,
    drawn: jsonInt(m['drawn']) ?? 0,
    lost: jsonInt(m['lost']) ?? 0,
    goalsFor: jsonInt(m['goalsFor']) ?? 0,
    goalsAgainst: jsonInt(m['goalsAgainst']) ?? 0,
    goalDifference: jsonInt(m['goalDifference']) ?? 0,
    points: jsonInt(m['points']) ?? 0,
    deductionPoints: jsonInt(m['deductionPoints']) ?? 0,
    form: jsonString(m['form']),
  );
}

PlayerRankRecord _playerRank(Object? raw) {
  final m = jsonMap(raw);
  final playerId = jsonInt(m?['playerId']);
  if (m == null || playerId == null) {
    throw const ParseException('Player rank record is invalid.');
  }
  return PlayerRankRecord(
    rank: jsonInt(m['rank']) ?? 0,
    playerId: playerId,
    playerName: jsonString(m['playerName']) ?? '球员 $playerId',
    playerAvatarUrl: jsonString(m['playerAvatarUrl']),
    teamId: jsonInt(m['teamId']),
    teamName: jsonString(m['teamName']),
    teamLogoUrl: jsonString(m['teamLogoUrl']),
    value: jsonDouble(m['value']),
    displayValue: jsonString(m['displayValue']),
    appearances: jsonInt(m['appearances']),
    starts: jsonInt(m['starts']),
    minutes: jsonInt(m['minutes']),
    updatedAt: jsonIsoDateTime(m['updatedAt']),
  );
}

TeamRankRecord _teamRank(Object? raw) {
  final m = jsonMap(raw);
  final teamId = jsonInt(m?['teamId']);
  if (m == null || teamId == null) {
    throw const ParseException('Team rank record is invalid.');
  }
  return TeamRankRecord(
    rank: jsonInt(m['rank']) ?? 0,
    teamId: teamId,
    teamName: jsonString(m['teamName']) ?? '球队 $teamId',
    teamLogoUrl: jsonString(m['teamLogoUrl']),
    value: jsonDouble(m['value']),
    displayValue: jsonString(m['displayValue']),
    played: jsonInt(m['played']),
    sortDirection: jsonString(m['sortDirection']),
    updatedAt: jsonIsoDateTime(m['updatedAt']),
  );
}

League _league(Object? raw) {
  final m = _map(raw);
  return League(
    id: _id(m, 'leagueId'),
    name: _requiredText(m, 'leagueName'),
    logoUrl: _text(m['logoUrl']),
    country: _text(m['country']),
    season: _text(m['season']),
  );
}

FootballTeam _team(Object? raw) {
  final m = _map(raw);
  return FootballTeam(
    id: _id(m, 'teamId'),
    name: _requiredText(m, 'teamName'),
    logoUrl: _text(m['logoUrl']),
    score: _integer(m['score']),
  );
}

FootballMatch _match(Object? raw) {
  final m = _map(raw);
  return FootballMatch(
    id: _id(m, 'matchId'),
    leagueId: _id(m, 'leagueId'),
    leagueName: _requiredText(m, 'leagueName'),
    homeTeam: _team(m['homeTeam']),
    awayTeam: _team(m['awayTeam']),
    status: _requiredText(m, 'matchStatus'),
    matchTime: _time(m['matchTime']),
    eventSummary: _text(m['eventSummary']),
    hasReport: _boolean(m['hasReport']),
    reportContentId: _integer(m['reportContentId']),
  );
}

MatchDetail _matchDetail(Object? raw) {
  final m = _map(raw);
  final base = _match(m);
  final reportRaw = m['report'];
  return MatchDetail(
    match: base,
    season: _text(m['season']),
    roundName: _text(m['roundName']),
    venue: _text(m['venue']),
    events: m['eventList'] is List
        ? (m['eventList'] as List).map(_event).toList(growable: false)
        : const [],
    report: reportRaw is Map
        ? MatchReport(
            contentId: _id(reportRaw, 'contentId'),
            title: _requiredText(reportRaw, 'title'),
            type: _text(reportRaw['reportType']),
          )
        : null,
  );
}

MatchEvent _event(Object? raw) {
  final m = _map(raw);
  return MatchEvent(
    id: _id(m, 'eventId'),
    type: _requiredText(m, 'eventType'),
    minute: _integer(m['minute']) ?? 0,
    extraMinute: _integer(m['extraMinute']),
    teamId: _integer(m['teamId']),
    teamName: _text(m['teamName']),
    playerId: _integer(m['playerId']),
    playerName: _text(m['playerName']),
    assistPlayerId: _integer(m['assistPlayerId']),
    assistPlayerName: _text(m['assistPlayerName']),
    scoreAfter: _text(m['scoreAfter']),
    description: _text(m['description']),
    hasDebate: _boolean(m['hasDebate']),
  );
}

TeamDetail _teamDetail(Object? raw) {
  final m = _map(raw);
  return TeamDetail(
    id: _id(m, 'teamId'),
    name: _requiredText(m, 'teamName'),
    nameEn: _text(m['teamNameEn']),
    shortName: _text(m['shortName']),
    logoUrl: _text(m['logoUrl']),
    country: _text(m['country']),
    city: _text(m['city']),
    stadiumName: _text(m['stadiumName']),
    foundedYear: _integer(m['foundedYear']),
    coachName: _text(m['coachName']),
    marketValue: _text(m['marketValue']),
    followerCount: _integer(m['followerCount']) ?? 0,
    followed: _boolean(m['followed']),
    recentMatches: m['recentMatches'] is List
        ? (m['recentMatches'] as List).map(_match).toList(growable: false)
        : const [],
    upcomingMatches: m['upcomingMatches'] is List
        ? (m['upcomingMatches'] as List).map(_match).toList(growable: false)
        : const [],
  );
}

PlayerDetail _playerDetail(Object? raw) {
  final m = _map(raw);
  final teamRaw = m['team'];
  return PlayerDetail(
    id: _id(m, 'playerId'),
    name: _requiredText(m, 'playerName'),
    nameEn: _text(m['playerNameEn']),
    avatarUrl: _text(m['avatarUrl']),
    position: _text(m['position']),
    nationality: _text(m['nationality']),
    age: _integer(m['age']),
    shirtNumber: _integer(m['shirtNumber']),
    retired: _boolean(m['retired']),
    followerCount: _integer(m['followerCount']) ?? 0,
    followed: _boolean(m['followed']),
    team: teamRaw is Map
        ? PlayerTeam(
            id: _id(teamRaw, 'teamId'),
            name: _requiredText(teamRaw, 'teamName'),
            logoUrl: _text(teamRaw['logoUrl']),
            shirtNumber: _integer(teamRaw['shirtNumber']),
            position: _text(teamRaw['position']),
          )
        : null,
  );
}
