import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../domain/comment.dart';
import 'interaction_api.dart';

abstract interface class InteractionRepositoryContract {
  Future<ToggleState> toggleLike(int id);
  Future<ToggleState> toggleFavorite(int id);
  Future<CommentPage> comments(int id, CommentSort sort, int page);
  Future<CommentPage> replies(int id, int page);
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId,
    int? replyToUserId,
  });
  Future<ToggleState> toggleCommentLike(int id);
  Future<void> deleteComment(int id);
}

final interactionRepositoryProvider = Provider<InteractionRepositoryContract>(
  (ref) => InteractionRepository(InteractionApi(ref.watch(apiClientProvider))),
);

final class InteractionRepository implements InteractionRepositoryContract {
  const InteractionRepository(this.api);
  final InteractionApi api;
  @override
  Future<ToggleState> toggleLike(int id) => api.toggleLike(id);
  @override
  Future<ToggleState> toggleFavorite(int id) => api.toggleFavorite(id);
  @override
  Future<CommentPage> comments(int id, CommentSort sort, int page) =>
      api.comments(id, sort, page);
  @override
  Future<CommentPage> replies(int id, int page) => api.replies(id, page);
  @override
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId = 0,
    int? replyToUserId,
  }) => api.createComment(
    contentId: contentId,
    content: content,
    parentId: parentId,
    replyToUserId: replyToUserId,
  );
  @override
  Future<ToggleState> toggleCommentLike(int id) => api.toggleCommentLike(id);
  @override
  Future<void> deleteComment(int id) => api.deleteComment(id);
}
