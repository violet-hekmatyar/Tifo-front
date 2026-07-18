import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/football_models.dart';

final class FootballApi {
  const FootballApi(this._client);
  final ApiClient _client;

  Future<List<League>> leagues() => _client.get(
    '/api/app/football/leagues',
    decode: (raw) => _list(raw, _league),
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
