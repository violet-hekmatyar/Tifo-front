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

final class ContentDetail {
  const ContentDetail({
    required this.contentId,
    required this.contentType,
    required this.contentFormat,
    required this.title,
    required this.body,
    required this.author,
    required this.media,
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
