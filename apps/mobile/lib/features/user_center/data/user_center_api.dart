import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/user_center_models.dart';

final class UserCenterApi {
  const UserCenterApi(this._client);
  final ApiClient _client;

  Future<MySummary> summary() =>
      _client.get('/api/app/users/me/summary', decode: _summary);
  Future<UserStand> stand() =>
      _client.get('/api/app/users/me/stand', decode: _stand);
  Future<UserProfile> profile(int userId) =>
      _client.get('/api/app/users/$userId/profile', decode: _profile);
  Future<void> updateProfile({required String nickname, required String bio}) =>
      _client.put<void>(
        '/api/app/users/me/profile',
        body: {'nickname': nickname, 'bio': bio},
        decode: (_) {},
      );
  Future<UserPage<UserContentItem>> myContents(int page, int size) =>
      _page('/api/app/users/me/contents', page, size, _content);
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
      _page('/api/app/users/me/favorites', page, size, _favorite);
  Future<UserPage<UserCommentItem>> myComments(int page, int size) =>
      _page('/api/app/users/me/comments', page, size, _comment);
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) => _page('/api/app/users/$userId/contents', page, size, _content);
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) =>
      _page('/api/app/users/$userId/followings', page, size, _userBrief);
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) =>
      _page('/api/app/users/$userId/followers', page, size, _userBrief);

  Future<UserProfile> follow(int userId, bool follow) async {
    final raw = follow
        ? await _client.post<Object?>(
            '/api/app/users/$userId/follow',
            decode: (value) => value,
          )
        : await _client.delete<Object?>(
            '/api/app/users/$userId/follow',
            decode: (value) => value,
          );
    if (raw is! Map) throw const ParseException('Invalid follow response.');
    final profile = await this.profile(userId);
    return profile.copyWith(
      followerCount: _integer(raw['followerCount']),
      relationStatus: _text(raw['relationStatus']) ?? profile.relationStatus,
    );
  }

  Future<bool> toggleEntity(String type, int id) => _client.post(
    '/api/app/follows/toggle',
    body: {'followType': type, 'targetId': id},
    decode: (raw) {
      if (raw is! Map || raw['followed'] is! bool) {
        throw const ParseException('Invalid follow toggle response.');
      }
      return raw['followed'] as bool;
    },
  );
  Future<void> removeFavorite(int contentId) => _client.post<void>(
    '/api/app/favorites/toggle',
    body: {'targetType': 'CONTENT', 'targetId': contentId},
    decode: (_) {},
  );
  Future<void> deleteComment(int commentId) =>
      _client.delete<void>('/api/app/comments/$commentId', decode: (_) {});

  Future<UserPage<T>> _page<T>(
    String path,
    int page,
    int size,
    T Function(Object?) decodeItem,
  ) async {
    final result = await _client.get(
      path,
      queryParameters: {'pageNum': page, 'pageSize': size},
      decode: (raw) => PageResult.fromRaw(raw, decodeItem),
    );
    return UserPage(
      records: result.records,
      pageNum: result.pageNum,
      pages: result.pages,
      total: result.total,
    );
  }
}

MySummary _summary(Object? raw) {
  final map = _map(raw);
  final stats = map['stats'] is Map ? map['stats'] as Map : const {};
  return MySummary(
    userId: _requiredInt(map, 'userId'),
    username: _text(map['username']) ?? '',
    nickname: _displayName(map),
    avatarUrl: _text(map['avatarUrl']),
    bio: _text(map['bio']),
    mainTeam: _team(map['mainTeam']),
    postCount: _integer(stats['postCount']),
    favoriteCount: _integer(stats['favoriteCount']),
    commentCount: _integer(stats['commentCount']),
    followingCount: _integer(stats['followingCount']),
    followerCount: _integer(stats['followerCount']),
    teamFollowCount: _integer(stats['teamFollowCount']),
    playerFollowCount: _integer(stats['playerFollowCount']),
  );
}

UserProfile _profile(Object? raw) {
  final map = _map(raw);
  return UserProfile(
    userId: _requiredInt(map, 'userId'),
    username: _text(map['username']) ?? '',
    nickname: _displayName(map),
    avatarUrl: _text(map['avatarUrl']),
    bio: _text(map['bio']),
    mainTeam: _team(map['mainTeam']),
    followingCount: _integer(map['followingCount']),
    followerCount: _integer(map['followerCount']),
    contentCount: _integer(map['contentCount']),
    likeReceivedCount: _integer(map['likeReceivedCount']),
    relationStatus: _text(map['relationStatus']) ?? 'NONE',
    currentUser: map['currentUser'] == true,
  );
}

UserStand _stand(Object? raw) {
  final map = _map(raw);
  return UserStand(
    teams: _list(
      map['followTeams'],
    ).map((e) => _team(e)).whereType<EntityBrief>().toList(),
    players: _list(map['followPlayers']).map((e) {
      final m = _map(e);
      return EntityBrief(
        id: _requiredInt(m, 'playerId'),
        name: _text(m['playerName']) ?? '球员',
        imageUrl: _text(m['avatarUrl']),
        subtitle: _text(m['teamName']),
      );
    }).toList(),
  );
}

UserBrief _userBrief(Object? raw) {
  final map = _map(raw);
  return UserBrief(
    userId: _requiredInt(map, 'userId'),
    username: _text(map['username']) ?? '',
    nickname: _displayName(map),
    avatarUrl: _text(map['avatarUrl']),
    bio: _text(map['bio']),
    relationStatus: _text(map['relationStatus']) ?? 'NONE',
  );
}

UserContentItem _content(Object? raw) {
  final map = _map(raw);
  return UserContentItem(
    contentId: _requiredInt(map, 'contentId'),
    contentType: _text(map['contentType']) ?? 'POST',
    title: _text(map['title']) ?? '未命名内容',
    summary: _text(map['summary']),
    coverUrl: _text(map['coverUrl']),
    likeCount: _integer(map['likeCount']),
    commentCount: _integer(map['commentCount']),
    favoriteCount: _integer(map['favoriteCount']),
    publishTime: DateTime.tryParse(_text(map['publishTime']) ?? ''),
  );
}

UserFavoriteItem _favorite(Object? raw) {
  final map = _map(raw);
  return UserFavoriteItem(
    contentId: _requiredInt(map, 'targetId'),
    title: _text(map['title']) ?? '未命名内容',
    summary: _text(map['summary']),
    coverUrl: _text(map['coverUrl']),
    favoriteTime: DateTime.tryParse(_text(map['favoriteTime']) ?? ''),
  );
}

UserCommentItem _comment(Object? raw) {
  final map = _map(raw);
  return UserCommentItem(
    commentId: _requiredInt(map, 'commentId'),
    contentId: _requiredInt(map, 'targetId'),
    content: _text(map['contentText']) ?? '',
    contentTitle: _text(map['targetTitle']),
    createTime: DateTime.tryParse(_text(map['createTime']) ?? ''),
  );
}

EntityBrief? _team(Object? raw) {
  if (raw is! Map) return null;
  return EntityBrief(
    id: _requiredInt(raw, 'teamId'),
    name: _text(raw['teamName']) ?? '球队',
    imageUrl: _text(raw['logoUrl']),
  );
}

Map _map(Object? raw) {
  if (raw is! Map) throw const ParseException('Invalid user center response.');
  return raw;
}

List _list(Object? raw) => raw is List ? raw : const [];
int _requiredInt(Map map, String key) {
  final value = map[key];
  if (value is! num) throw ParseException('Missing $key.');
  return value.toInt();
}

int _integer(Object? raw) => raw is num ? raw.toInt() : 0;
String? _text(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return raw.trim();
}

String _displayName(Map map) =>
    _text(map['nickname']) ?? _text(map['username']) ?? '南看台用户';
