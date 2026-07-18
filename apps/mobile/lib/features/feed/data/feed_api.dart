import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/feed_card.dart';
import '../domain/feed_page.dart';
import 'dto/feed_card_dto.dart';

final class FeedApi {
  const FeedApi(this._client);

  final ApiClient _client;

  Future<FeedPage> feed({
    required String tab,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async {
    final page = await _client.get<PageResult<FeedCard>>(
      '/api/app/feed',
      queryParameters: {
        'tab': tab,
        'pageNum': pageNum,
        'pageSize': pageSize,
        'teamId': ?teamId,
      },
      decode: (raw) => PageResult<FeedCard>.fromRaw(
        raw,
        (item) => FeedCardDto.fromRaw(item).toDomain(),
      ),
    );
    return FeedPage(
      cards: page.records,
      total: page.total,
      pageNum: page.pageNum,
      pageSize: page.pageSize,
      pages: page.pages,
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
    if (raw is! Map || raw['teamId'] is! num || raw['teamName'] is! String) {
      return null;
    }
    return FollowedTeam(
      teamId: (raw['teamId'] as num).toInt(),
      teamName: raw['teamName'] as String,
      logoUrl: raw['logoUrl'] as String?,
    );
  }
}
