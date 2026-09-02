final class ContentAuthor {
  const ContentAuthor({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.verified = false,
  });
  final int? userId;
  final String nickname;
  final String? avatarUrl;
  final bool verified;
}

final class ContentMedia {
  const ContentMedia({
    required this.mediaId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
  });
  final int? mediaId;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
}

final class ContentRelation {
  const ContentRelation({
    required this.type,
    required this.id,
    required this.name,
  });
  final String type;
  final int id;
  final String name;
}

enum ArticleBlockType {
  text,
  image,
  unknown;

  static ArticleBlockType fromWire(Object? value) => switch (value) {
    'TEXT' => text,
    'IMAGE' => image,
    _ => unknown,
  };
}

final class ArticleBlock {
  const ArticleBlock({
    required this.rawType,
    required this.sortOrder,
    this.blockId,
    this.text,
    this.mediaFileId,
    this.mediaUrl,
  });

  final int? blockId;
  final String rawType;
  final String? text;
  final int? mediaFileId;
  final String? mediaUrl;
  final int sortOrder;

  ArticleBlockType get type => ArticleBlockType.fromWire(rawType);
}

final class ArticleBlockInput {
  const ArticleBlockInput({
    required this.blockType,
    required this.sortOrder,
    this.text,
    this.mediaFileId,
  });

  final String blockType;
  final String? text;
  final int? mediaFileId;
  final int sortOrder;

  Map<String, Object?> toJson() => {
    'blockType': blockType,
    'text': text,
    'mediaFileId': mediaFileId,
    'sortOrder': sortOrder,
  };
}

final class ContentRelationInput {
  const ContentRelationInput({required this.type, required this.id});

  final String type;
  final int id;

  Map<String, Object> toJson() => {'relationType': type, 'relationId': id};
}

final class ArticleRequest {
  const ArticleRequest({
    required this.title,
    required this.blocks,
    required this.relations,
    this.summary,
    this.coverFileId,
  });

  final String title;
  final String? summary;
  final int? coverFileId;
  final List<ArticleBlockInput> blocks;
  final List<ContentRelationInput> relations;

  Map<String, Object?> toJson() => {
    'title': title,
    'summary': summary,
    'coverFileId': coverFileId,
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
    'relationList': relations
        .map((relation) => relation.toJson())
        .toList(growable: false),
  };
}

final class ContentDetail {
  const ContentDetail({
    required this.contentId,
    required this.contentType,
    required this.contentFormat,
    required this.title,
    required this.body,
    required this.author,
    required this.media,
    this.blocks = const [],
    required this.relations,
    required this.likeCount,
    required this.commentCount,
    required this.favoriteCount,
    required this.viewCount,
    required this.liked,
    required this.favorited,
    this.summary,
    this.coverUrl,
    this.publishTime,
  });
  final int contentId;
  final String contentType;
  final String contentFormat;
  final String title;
  final String? summary;
  final String body;
  final String? coverUrl;
  final ContentAuthor author;
  final List<ContentMedia> media;
  final List<ArticleBlock> blocks;
  final List<ContentRelation> relations;
  final int likeCount;
  final int commentCount;
  final int favoriteCount;
  final int viewCount;
  final bool liked;
  final bool favorited;
  final DateTime? publishTime;

  ContentDetail interactionCopy({
    bool? liked,
    bool? favorited,
    int? likeCount,
    int? favoriteCount,
  }) => ContentDetail(
    contentId: contentId,
    contentType: contentType,
    contentFormat: contentFormat,
    title: title,
    body: body,
    author: author,
    media: media,
    blocks: blocks,
    relations: relations,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount,
    favoriteCount: favoriteCount ?? this.favoriteCount,
    viewCount: viewCount,
    liked: liked ?? this.liked,
    favorited: favorited ?? this.favorited,
    summary: summary,
    coverUrl: coverUrl,
    publishTime: publishTime,
  );
}

final class CreatedPost {
  const CreatedPost({required this.contentId, required this.title});
  final int contentId;
  final String title;
}
