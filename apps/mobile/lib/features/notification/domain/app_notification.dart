enum AppNotificationType {
  contentLiked,
  contentCommented,
  commentReplied,
  commentLiked,
  userFollowed,
  system,
  unknown;

  factory AppNotificationType.fromWire(String? value) => switch (value) {
    'CONTENT_LIKED' => contentLiked,
    'CONTENT_COMMENTED' => contentCommented,
    'COMMENT_REPLIED' => commentReplied,
    'COMMENT_LIKED' => commentLiked,
    'USER_FOLLOWED' => userFollowed,
    'SYSTEM' => system,
    _ => unknown,
  };
}

enum NotificationTargetType {
  content,
  comment,
  user,
  system,
  unknown;

  factory NotificationTargetType.fromWire(String? value) => switch (value) {
    'CONTENT' => content,
    'COMMENT' => comment,
    'USER' => user,
    'SYSTEM' => system,
    _ => unknown,
  };
}

final class NotificationActor {
  const NotificationActor({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
  });
  final int userId;
  final String nickname;
  final String? avatarUrl;
}

final class NotificationTargetPreview {
  const NotificationTargetPreview({
    this.contentTitle,
    this.coverUrl,
    this.commentExcerpt,
  });
  final String? contentTitle;
  final String? coverUrl;
  final String? commentExcerpt;
}

final class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.type,
    required this.rawType,
    required this.targetType,
    required this.rawTargetType,
    required this.title,
    required this.content,
    required this.read,
    required this.targetAvailable,
    this.actor,
    this.targetId,
    this.secondaryTargetType,
    this.secondaryTargetId,
    this.readTime,
    this.createTime,
    this.targetPreview,
  });

  final int notificationId;
  final AppNotificationType type;
  final String rawType;
  final NotificationActor? actor;
  final NotificationTargetType targetType;
  final String rawTargetType;
  final int? targetId;
  final NotificationTargetType? secondaryTargetType;
  final int? secondaryTargetId;
  final String title;
  final String content;
  final bool read;
  final DateTime? readTime;
  final DateTime? createTime;
  final bool targetAvailable;
  final NotificationTargetPreview? targetPreview;

  AppNotification asRead() => AppNotification(
    notificationId: notificationId,
    type: type,
    rawType: rawType,
    actor: actor,
    targetType: targetType,
    rawTargetType: rawTargetType,
    targetId: targetId,
    secondaryTargetType: secondaryTargetType,
    secondaryTargetId: secondaryTargetId,
    title: title,
    content: content,
    read: true,
    readTime: readTime,
    createTime: createTime,
    targetAvailable: targetAvailable,
    targetPreview: targetPreview,
  );

  String? get route {
    if (!targetAvailable) return null;
    return switch (targetType) {
      NotificationTargetType.content when targetId != null =>
        '/contents/$targetId',
      NotificationTargetType.comment
          when secondaryTargetType == NotificationTargetType.content &&
              secondaryTargetId != null =>
        '/contents/$secondaryTargetId',
      NotificationTargetType.user when targetId != null => '/users/$targetId',
      _ => null,
    };
  }
}

final class NotificationPage {
  const NotificationPage({
    required this.records,
    required this.pageNum,
    required this.pages,
    required this.total,
  });
  final List<AppNotification> records;
  final int pageNum;
  final int pages;
  final int total;
  bool get hasMore => pageNum < pages;
}
