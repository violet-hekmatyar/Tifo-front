import '../../../core/network/backend_v1_contract.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../domain/feed_page.dart';
import 'dto/feed_page_dto.dart';

final class FeedApi {
  const FeedApi(this._client);

  final ApiClient _client;

  Future<FeedPage> feed({
    required FeedTab tab,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async {
    return _client.get<FeedPage>(
      '/api/app/feed',
      queryParameters: {
        'tab': tab.wireValue,
        'pageNum': pageNum,
        'pageSize': pageSize,
        'teamId': ?teamId,
      },
      decode: (raw) => FeedPageDto.fromRaw(raw).toDomain(),
    );
  }

  Future<List<FollowedTeam>> followedTeams() => _client.get<List<FollowedTeam>>(
    '/api/app/users/me/stand',
    decode: (raw) {
      if (raw is! Map || raw['followTeams'] is! List) {
        throw const ParseException('Invalid user stand response.');
      }
      final result = <int, FollowedTeam>{};
      final main = _team(raw['mainTeam']);
      if (main != null) result[main.teamId] = main;
      for (final item in raw['followTeams'] as List) {
        final team = _team(item);
        if (team != null) result[team.teamId] = team;
      }
      return List.unmodifiable(result.values);
    },
  );

  static FollowedTeam? _team(Object? raw) {
    if (raw is! Map ||
        jsonInt(raw['teamId']) == null ||
        jsonString(raw['teamName']) == null) {
      return null;
    }
    return FollowedTeam(
      teamId: jsonInt(raw['teamId'])!,
      teamName: jsonString(raw['teamName'])!,
      logoUrl: jsonString(raw['logoUrl']),
    );
  }
}
