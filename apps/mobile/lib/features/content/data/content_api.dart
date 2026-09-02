import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../domain/content_detail.dart';

final class ContentApi {
  const ContentApi(this._client);
  final ApiClient _client;
  Future<ContentDetail> detail(int id) =>
      _client.get('/api/app/contents/$id', decode: _detail);
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  }) => _client.post(
    '/api/app/contents/posts',
    body: {
      'title': title,
      'body': body,
      'mediaFileIds': mediaFileIds,
      'relationList': <Object>[],
    },
    decode: (raw) {
      if (raw is! Map || raw['contentId'] is! num || raw['title'] is! String) {
        throw const ParseException('Invalid create post response.');
      }
      return CreatedPost(
        contentId: (raw['contentId'] as num).toInt(),
        title: raw['title'] as String,
      );
    },
  );

  Future<CreatedPost> createArticle(ArticleRequest request) => _client.post(
    '/api/app/contents/articles',
    body: request.toJson(),
    decode: _createdContent,
  );

  Future<ContentDetail> updateArticle(int id, ArticleRequest request) =>
      _client.put(
        '/api/app/contents/$id/articles',
        body: request.toJson(),
        decode: _detail,
      );
}

CreatedPost _createdContent(Object? raw) {
  final map = jsonMap(raw);
  final contentId = jsonInt(map?['contentId']);
  final title = jsonString(map?['title']);
  if (contentId == null || title == null) {
    throw const ParseException('Invalid create article response.');
  }
  return CreatedPost(contentId: contentId, title: title);
}

ContentDetail _detail(Object? raw) {
  if (raw is! Map || raw['contentId'] is! num || raw['title'] is! String) {
    throw const ParseException('Invalid content detail response.');
  }
  final author = raw['author'];
  final media = raw['mediaList'] is List ? raw['mediaList'] as List : const [];
  final relations = raw['relationList'] is List
      ? raw['relationList'] as List
      : const [];
  final rawBlocks = raw['blocks'] is List ? raw['blocks'] as List : const [];
  final indexedBlocks = <({int index, ArticleBlock block})>[];
  for (var index = 0; index < rawBlocks.length; index++) {
    final item = jsonMap(rawBlocks[index]);
    if (item == null) continue;
    indexedBlocks.add((
      index: index,
      block: ArticleBlock(
        blockId: jsonInt(item['blockId']),
        rawType: jsonString(item['blockType']) ?? 'UNKNOWN',
        text: jsonString(item['text']),
        mediaFileId: jsonInt(item['mediaFileId']),
        mediaUrl: jsonString(item['mediaUrl']),
        sortOrder: jsonInt(item['sortOrder']) ?? index,
      ),
    ));
  }
  indexedBlocks.sort((a, b) {
    final byOrder = a.block.sortOrder.compareTo(b.block.sortOrder);
    return byOrder == 0 ? a.index.compareTo(b.index) : byOrder;
  });
  return ContentDetail(
    contentId: (raw['contentId'] as num).toInt(),
    contentType: _text(raw['contentType']) ?? 'UNKNOWN',
    contentFormat: _text(raw['contentFormat']) ?? 'POST_FORMAT',
    title: raw['title'] as String,
    summary: _text(raw['summary']),
    body: _text(raw['body']) ?? '',
    coverUrl: _text(raw['coverUrl']),
    author: author is Map
        ? ContentAuthor(
            userId: (author['userId'] as num?)?.toInt(),
            nickname: _text(author['nickname']) ?? '南看台用户',
            avatarUrl: _text(author['avatarUrl']),
            verified: author['verified'] == true,
          )
        : const ContentAuthor(userId: null, nickname: '南看台用户'),
    media: media
        .whereType<Map>()
        .map((item) {
          final url = _text(item['mediaUrl']);
          if (url == null) return null;
          return ContentMedia(
            mediaId: (item['mediaId'] as num?)?.toInt(),
            mediaType: _text(item['mediaType']) ?? 'UNKNOWN',
            mediaUrl: url,
            thumbnailUrl: _text(item['thumbnailUrl']),
            width: (item['width'] as num?)?.toInt(),
            height: (item['height'] as num?)?.toInt(),
          );
        })
        .whereType<ContentMedia>()
        .toList(growable: false),
    blocks: indexedBlocks.map((item) => item.block).toList(growable: false),
    relations: relations
        .whereType<Map>()
        .map((item) {
          final id = (item['relationId'] as num?)?.toInt();
          if (id == null) return null;
          return ContentRelation(
            type: _text(item['relationType']) ?? 'UNKNOWN',
            id: id,
            name: _text(item['relationName']) ?? '关联内容',
          );
        })
        .whereType<ContentRelation>()
        .toList(growable: false),
    likeCount: _count(raw['likeCount']),
    commentCount: _count(raw['commentCount']),
    favoriteCount: _count(raw['favoriteCount']),
    viewCount: _count(raw['viewCount']),
    liked: raw['liked'] == true,
    favorited: raw['favorited'] == true,
    publishTime: DateTime.tryParse(_text(raw['publishTime']) ?? ''),
  );
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int _count(Object? value) => value is num ? value.toInt().clamp(0, 1 << 31) : 0;
