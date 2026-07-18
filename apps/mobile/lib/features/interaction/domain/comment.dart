import '../../content/domain/content_detail.dart';

enum CommentSort { hot, latest }

final class CommentItem {
  const CommentItem({
    required this.commentId,
    required this.parentId,
    required this.rootId,
    required this.author,
    required this.content,
    required this.likeCount,
    required this.replyCount,
    required this.liked,
    required this.replies,
    this.replyToUserId,
    this.replyToNickname,
    this.createTime,
  });
  final int commentId;
  final int parentId;
  final int? rootId;
  final int? replyToUserId;
  final String? replyToNickname;
  final ContentAuthor author;
  final String content;
  final int likeCount;
  final int replyCount;
  final bool liked;
  final DateTime? createTime;
  final List<CommentItem> replies;

  CommentItem interactionCopy({bool? liked, int? likeCount}) => CommentItem(
    commentId: commentId,
    parentId: parentId,
    rootId: rootId,
    author: author,
    content: content,
    likeCount: likeCount ?? this.likeCount,
    replyCount: replyCount,
    liked: liked ?? this.liked,
    replies: replies,
    replyToUserId: replyToUserId,
    replyToNickname: replyToNickname,
    createTime: createTime,
  );
}

final class CommentPage {
  const CommentPage({
    required this.records,
    required this.pageNum,
    required this.pages,
    required this.total,
  });
  final List<CommentItem> records;
  final int pageNum;
  final int pages;
  final int total;
  bool get hasMore => pageNum < pages;
}

final class ToggleState {
  const ToggleState({required this.active, this.count});
  final bool active;
  final int? count;
}
