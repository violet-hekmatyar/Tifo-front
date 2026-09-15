import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../data/interaction_repository.dart';
import '../../domain/comment.dart';

enum CommentsStatus { loading, ready, empty, failure }

final class CommentsState {
  const CommentsState({
    required this.status,
    this.items = const [],
    this.sort = CommentSort.hot,
    this.page = 0,
    this.hasMore = false,
    this.message,
    this.loadingMore = false,
    this.moreFailure = false,
    this.submitting = false,
    this.busyIds = const {},
  });
  final CommentsStatus status;
  final List<CommentItem> items;
  final CommentSort sort;
  final int page;
  final bool hasMore;
  final String? message;
  final bool loadingMore;
  final bool moreFailure;
  final bool submitting;
  final Set<int> busyIds;
}

final commentControllerProvider = ChangeNotifierProvider.autoDispose
    .family<CommentController, int>(
      (ref, id) =>
          CommentController(id, ref.watch(interactionRepositoryProvider))
            ..load(),
    );

final class CommentController extends ChangeNotifier {
  CommentController(this.contentId, this.repository);
  final int contentId;
  final InteractionRepositoryContract repository;
  CommentsState state = const CommentsState(status: CommentsStatus.loading);
  bool _disposed = false;
  int _requestVersion = 0;
  Future<void> load({CommentSort? sort}) async {
    final selected = sort ?? state.sort;
    final version = ++_requestVersion;
    state = CommentsState(
      status: CommentsStatus.loading,
      sort: selected,
      moreFailure: false,
    );
    notifyListeners();
    try {
      final p = await repository.comments(contentId, selected, 1);
      if (_disposed || version != _requestVersion) return;
      state = CommentsState(
        status: p.records.isEmpty ? CommentsStatus.empty : CommentsStatus.ready,
        items: p.records,
        sort: selected,
        page: 1,
        hasMore: p.hasMore,
      );
      notifyListeners();
    } on AppNetworkException catch (e) {
      if (_disposed || version != _requestVersion) return;
      state = CommentsState(
        status: CommentsStatus.failure,
        sort: selected,
        message: e.message,
      );
      notifyListeners();
    }
  }

  Future<void> more() async {
    if (state.loadingMore || !state.hasMore) return;
    final version = _requestVersion;
    final selected = state.sort;
    final nextPage = state.page + 1;
    state = _copy(loadingMore: true, moreFailure: false, message: null);
    notifyListeners();
    try {
      final p = await repository.comments(contentId, selected, nextPage);
      if (_disposed || version != _requestVersion) return;
      final map = {for (final x in state.items) x.commentId: x};
      for (final x in p.records) {
        map[x.commentId] = x;
      }
      state = CommentsState(
        status: CommentsStatus.ready,
        items: map.values.toList(),
        sort: state.sort,
        page: p.pageNum,
        hasMore: p.hasMore,
        moreFailure: false,
      );
      notifyListeners();
    } on AppNetworkException catch (e) {
      if (_disposed || version != _requestVersion) return;
      state = _copy(loadingMore: false, moreFailure: true, message: e.message);
      notifyListeners();
    }
  }

  Future<bool> submit(String text, {CommentItem? replyTo}) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 1000 || state.submitting) return false;
    state = _copy(submitting: true, message: null);
    notifyListeners();
    try {
      await repository.createComment(
        contentId: contentId,
        content: value,
        parentId: replyTo?.rootId ?? replyTo?.commentId ?? 0,
        replyToUserId: replyTo?.author.userId,
      );
      await load(sort: state.sort);
      return true;
    } on AppNetworkException catch (e) {
      if (_disposed) return false;
      state = _copy(submitting: false, message: e.message);
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(CommentItem item) async {
    if (state.busyIds.contains(item.commentId)) return;
    final originalItems = state.items;
    final originalState = state;
    final optimistic = item.interactionCopy(
      liked: !item.liked,
      likeCount: (item.likeCount + (item.liked ? -1 : 1)).clamp(0, 1 << 31),
    );
    state = CommentsState(
      status: state.status,
      items: [
        for (final value in state.items)
          if (value.commentId == item.commentId) optimistic else value,
      ],
      sort: state.sort,
      page: state.page,
      hasMore: state.hasMore,
      message: null,
      loadingMore: state.loadingMore,
      moreFailure: state.moreFailure,
      submitting: state.submitting,
      busyIds: {...state.busyIds, item.commentId},
    );
    notifyListeners();
    try {
      await repository.toggleCommentLike(item.commentId);
      await load(sort: state.sort);
    } on AppNetworkException catch (e) {
      if (_disposed) return;
      state = CommentsState(
        status: originalState.status,
        items: originalItems,
        sort: originalState.sort,
        page: originalState.page,
        hasMore: originalState.hasMore,
        loadingMore: originalState.loadingMore,
        moreFailure: originalState.moreFailure,
        submitting: originalState.submitting,
        message: e.message,
      );
      notifyListeners();
    }
  }

  Future<bool> delete(CommentItem item) async {
    if (state.busyIds.contains(item.commentId)) return false;
    state = _copy(busyIds: {...state.busyIds, item.commentId});
    notifyListeners();
    try {
      await repository.deleteComment(item.commentId);
      final remaining = state.items
          .where((value) => value.commentId != item.commentId)
          .toList(growable: false);
      state = CommentsState(
        status: remaining.isEmpty ? CommentsStatus.empty : CommentsStatus.ready,
        items: remaining,
        sort: state.sort,
        page: state.page,
        hasMore: state.hasMore,
      );
      notifyListeners();
      return true;
    } on AppNetworkException catch (e) {
      if (_disposed) return false;
      state = _copy(
        busyIds: {...state.busyIds}..remove(item.commentId),
        message: e.message,
      );
      notifyListeners();
      return false;
    }
  }

  Future<CommentPage> replies(CommentItem root, {int page = 1}) =>
      repository.replies(root.commentId, page);

  CommentsState _copy({
    bool? loadingMore,
    bool? moreFailure,
    bool? submitting,
    String? message,
    Set<int>? busyIds,
  }) => CommentsState(
    status: state.status,
    items: state.items,
    sort: state.sort,
    page: state.page,
    hasMore: state.hasMore,
    loadingMore: loadingMore ?? state.loadingMore,
    moreFailure: moreFailure ?? state.moreFailure,
    submitting: submitting ?? state.submitting,
    message: message,
    busyIds: busyIds ?? state.busyIds,
  );
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
