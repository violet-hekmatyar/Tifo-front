import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../../content/domain/content_detail.dart';
import '../domain/comment.dart';

final class InteractionApi {
  const InteractionApi(this.client);
  final ApiClient client;
  Future<ToggleState> toggleLike(int id) => client.post(
    '/api/app/likes/toggle',
    body: {'targetType': 'CONTENT', 'targetId': id},
    decode: (raw) => _toggle(raw, 'liked'),
  );
  Future<ToggleState> toggleFavorite(int id) => client.post(
    '/api/app/favorites/toggle',
    body: {'targetType': 'CONTENT', 'targetId': id},
    decode: (raw) => _toggle(raw, 'favorited'),
  );
  Future<CommentPage> comments(int id, CommentSort sort, int page) =>
      client.get(
        '/api/app/comments',
        queryParameters: {
          'contentId': id,
          'sort': sort.name,
          'pageNum': page,
          'pageSize': 10,
        },
        decode: _page,
      );
  Future<CommentPage> replies(int id, int page) => client.get(
    '/api/app/comments/$id/replies',
    queryParameters: {'sort': 'latest', 'pageNum': page, 'pageSize': 10},
    decode: _page,
  );
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId = 0,
    int? replyToUserId,
  }) => client.post(
    '/api/app/comments',
    body: {
      'contentId': contentId,
      'parentId': parentId,
      'replyToUserId': ?replyToUserId,
      'content': content,
    },
    decode: (raw) {
      if (raw is! Map || raw['commentId'] is! num) {
        throw const ParseException('Invalid comment response.');
      }
      return (raw['commentId'] as num).toInt();
    },
  );
  Future<ToggleState> toggleCommentLike(int id) => client.post(
    '/api/app/comments/$id/likes/toggle',
    decode: (raw) => _toggle(raw, 'liked'),
  );
  Future<void> deleteComment(int id) =>
      client.delete('/api/app/comments/$id', decode: (_) {});
}

ToggleState _toggle(Object? raw, String field) {
  if (raw is! Map || raw[field] is! bool) {
    throw const ParseException('Invalid toggle response.');
  }
  return ToggleState(
    active: raw[field] as bool,
    count: (raw['likeCount'] as num?)?.toInt(),
  );
}

CommentPage _page(Object? raw) {
  final page = PageResult<CommentItem>.fromRaw(raw, _comment);
  return CommentPage(
    records: page.records,
    pageNum: page.pageNum,
    pages: page.pages,
    total: page.total,
  );
}

CommentItem _comment(Object? raw) {
  if (raw is! Map ||
      raw['commentId'] is! num ||
      raw['contentText'] is! String) {
    throw const ParseException('Invalid comment.');
  }
  final author = raw['author'];
  final replies = raw['replies'] is List ? raw['replies'] as List : const [];
  return CommentItem(
    commentId: (raw['commentId'] as num).toInt(),
    parentId: (raw['parentId'] as num?)?.toInt() ?? 0,
    rootId: (raw['rootId'] as num?)?.toInt(),
    replyToUserId: (raw['replyToUserId'] as num?)?.toInt(),
    replyToNickname: raw['replyToNickname'] as String?,
    author: author is Map
        ? ContentAuthor(
            userId: (author['userId'] as num?)?.toInt(),
            nickname: author['nickname'] as String? ?? '南看台用户',
            avatarUrl: author['avatarUrl'] as String?,
            verified: author['verified'] == true,
          )
        : const ContentAuthor(userId: null, nickname: '南看台用户'),
    content: raw['contentText'] as String,
    likeCount: (raw['likeCount'] as num?)?.toInt().clamp(0, 1 << 31) ?? 0,
    replyCount: (raw['replyCount'] as num?)?.toInt().clamp(0, 1 << 31) ?? 0,
    liked: raw['liked'] == true,
    createTime: DateTime.tryParse(raw['createTime'] as String? ?? ''),
    replies: replies.map(_comment).toList(growable: false),
  );
}
