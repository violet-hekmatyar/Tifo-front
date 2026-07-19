import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/user_center_repository.dart';
import '../../domain/user_center_models.dart';

final mySummaryProvider = FutureProvider.autoDispose<MySummary>(
  (ref) => ref.watch(userCenterRepositoryProvider).summary(),
);
final myStandProvider = FutureProvider.autoDispose<UserStand>(
  (ref) => ref.watch(userCenterRepositoryProvider).stand(),
);

enum UserListKind {
  myContents,
  myFavorites,
  myComments,
  userContents,
  followings,
  followers,
}

final class UserListRequest {
  const UserListRequest(this.kind, {this.userId});
  final UserListKind kind;
  final int? userId;
  @override
  bool operator ==(Object other) =>
      other is UserListRequest && other.kind == kind && other.userId == userId;
  @override
  int get hashCode => Object.hash(kind, userId);
}

enum UserListStatus { loading, ready, empty, failure }

final class UserListState {
  const UserListState({
    required this.status,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.refreshing = false,
    this.message,
    this.appendMessage,
  });
  final UserListStatus status;
  final List<Object> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool refreshing;
  final String? message;
  final String? appendMessage;
}

final userListControllerProvider = ChangeNotifierProvider.autoDispose
    .family<UserListController, UserListRequest>(
      (ref, request) =>
          UserListController(ref.watch(userCenterRepositoryProvider), request),
    );

final class UserListController extends ChangeNotifier {
  UserListController(this._repository, this.request);
  static const pageSize = 10;
  final UserCenterRepositoryContract _repository;
  final UserListRequest request;
  UserListState state = const UserListState(status: UserListStatus.loading);
  bool _started = false;

  Future<void> loadInitial() async {
    if (_started) return;
    _started = true;
    await retry();
  }

  Future<void> retry() async {
    _set(const UserListState(status: UserListStatus.loading));
    try {
      _setPage(await _load(1), replace: true);
    } on AppNetworkException catch (error) {
      _set(
        UserListState(
          status: UserListStatus.failure,
          message: userCenterError(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.refreshing) return;
    _copy(refreshing: true, clearMessages: true);
    try {
      _setPage(await _load(1), replace: true);
    } on AppNetworkException catch (error) {
      _copy(refreshing: false, message: userCenterError(error));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    _copy(loadingMore: true, clearMessages: true);
    try {
      _setPage(await _load(state.page + 1), replace: false);
    } on AppNetworkException catch (error) {
      _copy(loadingMore: false, appendMessage: userCenterError(error));
    }
  }

  Future<void> removeItem(Object item) async {
    if (request.kind != UserListKind.myFavorites &&
        request.kind != UserListKind.myComments) {
      return;
    }
    final previous = state;
    final remaining = state.items
        .where((value) => !identical(value, item))
        .toList();
    _set(
      UserListState(
        status: remaining.isEmpty ? UserListStatus.empty : UserListStatus.ready,
        items: remaining,
        page: state.page,
        hasMore: state.hasMore,
      ),
    );
    try {
      if (item is UserFavoriteItem) {
        await _repository.removeFavorite(item.contentId);
      } else if (item is UserCommentItem) {
        await _repository.deleteComment(item.commentId);
      }
    } on AppNetworkException catch (error) {
      _set(
        UserListState(
          status: previous.status,
          items: previous.items,
          page: previous.page,
          hasMore: previous.hasMore,
          message: userCenterError(error),
        ),
      );
    }
  }

  Future<UserPage<Object>> _load(int page) async {
    final id = request.userId;
    final result = switch (request.kind) {
      UserListKind.myContents => await _repository.myContents(page, pageSize),
      UserListKind.myFavorites => await _repository.myFavorites(page, pageSize),
      UserListKind.myComments => await _repository.myComments(page, pageSize),
      UserListKind.userContents => await _repository.userContents(
        id!,
        page,
        pageSize,
      ),
      UserListKind.followings => await _repository.followings(
        id!,
        page,
        pageSize,
      ),
      UserListKind.followers => await _repository.followers(
        id!,
        page,
        pageSize,
      ),
    };
    return UserPage<Object>(
      records: result.records.cast<Object>(),
      pageNum: result.pageNum,
      pages: result.pages,
      total: result.total,
    );
  }

  void _setPage(UserPage<Object> page, {required bool replace}) {
    final values = replace
        ? page.records
        : <Object>[...state.items, ...page.records];
    _set(
      UserListState(
        status: values.isEmpty ? UserListStatus.empty : UserListStatus.ready,
        items: values,
        page: page.pageNum,
        hasMore: page.hasMore,
      ),
    );
  }

  void _copy({
    bool? refreshing,
    bool? loadingMore,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => _set(
    UserListState(
      status: state.status,
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
      refreshing: refreshing ?? state.refreshing,
      loadingMore: loadingMore ?? state.loadingMore,
      message: clearMessages ? null : message ?? state.message,
      appendMessage: clearMessages
          ? null
          : appendMessage ?? state.appendMessage,
    ),
  );
  void _set(UserListState value) {
    state = value;
    notifyListeners();
  }
}

enum PublicProfileStatus { loading, ready, notFound, failure }

final class PublicProfileState {
  const PublicProfileState({
    required this.status,
    this.profile,
    this.followBusy = false,
    this.message,
  });
  final PublicProfileStatus status;
  final UserProfile? profile;
  final bool followBusy;
  final String? message;
}

final publicProfileControllerProvider = ChangeNotifierProvider.autoDispose
    .family<PublicProfileController, int>(
      (ref, id) =>
          PublicProfileController(ref.watch(userCenterRepositoryProvider), id),
    );

final class PublicProfileController extends ChangeNotifier {
  PublicProfileController(this._repository, this.userId);
  final UserCenterRepositoryContract _repository;
  final int userId;
  PublicProfileState state = const PublicProfileState(
    status: PublicProfileStatus.loading,
  );
  bool _started = false;
  Future<void> load() async {
    if (_started && state.status == PublicProfileStatus.loading) return;
    _started = true;
    state = const PublicProfileState(status: PublicProfileStatus.loading);
    notifyListeners();
    try {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: await _repository.profile(userId),
      );
    } on BusinessException catch (error) {
      state = PublicProfileState(
        status: error.code == 40401
            ? PublicProfileStatus.notFound
            : PublicProfileStatus.failure,
        message: userCenterError(error),
      );
    } on AppNetworkException catch (error) {
      state = PublicProfileState(
        status: PublicProfileStatus.failure,
        message: userCenterError(error),
      );
    }
    notifyListeners();
  }

  Future<void> toggleFollow() async {
    final previous = state.profile;
    if (previous == null || previous.currentUser || state.followBusy) return;
    final nextFollowed = !previous.followed;
    state = PublicProfileState(
      status: PublicProfileStatus.ready,
      profile: previous.copyWith(
        followerCount: (previous.followerCount + (nextFollowed ? 1 : -1)).clamp(
          0,
          1 << 30,
        ),
        relationStatus: nextFollowed ? 'FOLLOWING' : 'NONE',
      ),
      followBusy: true,
    );
    notifyListeners();
    try {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: await _repository.follow(userId, nextFollowed),
      );
    } on AppNetworkException catch (error) {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: previous,
        message: userCenterError(error),
      );
    }
    notifyListeners();
  }
}

String userCenterError(AppNetworkException error) => switch (error) {
  NetworkException() => '网络连接失败，请检查后重试。',
  TimeoutException() => '请求超时，请稍后重试。',
  BusinessException(code: 40401) => '用户或内容不存在。',
  BusinessException(code: 40001) => error.message,
  BusinessException() => error.message,
  HttpException(statusCode: 403) => '当前账号无权执行此操作。',
  ParseException() => '数据格式异常，请稍后重试。',
  _ => '加载失败，请稍后重试。',
};
