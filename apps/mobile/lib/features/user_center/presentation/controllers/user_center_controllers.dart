import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../file_upload/data/file_upload_repository.dart';
import '../../../file_upload/domain/uploaded_file.dart';
import '../../data/user_center_repository.dart';
import '../../domain/user_center_models.dart';

final mySummaryProvider = FutureProvider.autoDispose<MySummary>(
  (ref) => ref.watch(userCenterRepositoryProvider).summary(),
);
final myStandProvider = FutureProvider.autoDispose<UserStand>(
  (ref) => ref.watch(userCenterRepositoryProvider).stand(),
);

enum MyProfileResourceStatus { loading, ready, empty, failure }

final class MyProfileState {
  const MyProfileState({
    required this.summaryStatus,
    required this.standStatus,
    this.summary,
    this.stand,
    this.summaryMessage,
    this.standMessage,
    this.refreshing = false,
  });

  const MyProfileState.initial()
    : this(
        summaryStatus: MyProfileResourceStatus.loading,
        standStatus: MyProfileResourceStatus.loading,
      );

  final MyProfileResourceStatus summaryStatus;
  final MyProfileResourceStatus standStatus;
  final MySummary? summary;
  final UserStand? stand;
  final String? summaryMessage;
  final String? standMessage;
  final bool refreshing;
}

final myProfileControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => MyProfileController(ref.watch(userCenterRepositoryProvider)),
);

final class MyProfileController extends ChangeNotifier {
  MyProfileController(this._repository);
  final UserCenterRepositoryContract _repository;
  MyProfileState state = const MyProfileState.initial();
  bool _started = false;
  int _generation = 0;

  Future<void> load() async {
    if (_started) return;
    _started = true;
    await Future.wait([_loadSummary(), _loadStand()]);
  }

  Future<void> refresh() async {
    if (state.refreshing) return;
    _generation++;
    final generation = _generation;
    _set(_copy(refreshing: true, clearMessages: true));
    await Future.wait([_loadSummary(), _loadStand()]);
    if (generation == _generation) _set(_copy(refreshing: false));
  }

  Future<void> retrySummary() async {
    _generation++;
    await _loadSummary();
  }

  Future<void> retryStand() async {
    _generation++;
    await _loadStand();
  }

  Future<void> _loadSummary() async {
    final generation = _generation;
    if (state.summary == null) {
      _set(_copy(summaryStatus: MyProfileResourceStatus.loading));
    }
    try {
      final summary = await _repository.summary();
      if (generation != _generation) return;
      _set(
        _copy(
          summaryStatus: MyProfileResourceStatus.ready,
          summary: summary,
          clearSummaryMessage: true,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        _copy(
          summaryStatus: state.summary == null
              ? MyProfileResourceStatus.failure
              : state.summaryStatus,
          summaryMessage: userCenterError(error),
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      _set(
        _copy(
          summaryStatus: state.summary == null
              ? MyProfileResourceStatus.failure
              : state.summaryStatus,
          summaryMessage: '加载失败，请稍后重试。',
        ),
      );
    }
  }

  Future<void> _loadStand() async {
    final generation = _generation;
    if (state.stand == null) {
      _set(_copy(standStatus: MyProfileResourceStatus.loading));
    }
    try {
      final stand = await _repository.stand();
      if (generation != _generation) return;
      _set(
        _copy(
          standStatus: MyProfileResourceStatus.ready,
          stand: stand,
          clearStandMessage: true,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        _copy(
          standStatus: state.stand == null
              ? MyProfileResourceStatus.failure
              : state.standStatus,
          standMessage: userCenterError(error),
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      _set(
        _copy(
          standStatus: state.stand == null
              ? MyProfileResourceStatus.failure
              : state.standStatus,
          standMessage: '加载失败，请稍后重试。',
        ),
      );
    }
  }

  MyProfileState _copy({
    MyProfileResourceStatus? summaryStatus,
    MyProfileResourceStatus? standStatus,
    MySummary? summary,
    UserStand? stand,
    String? summaryMessage,
    String? standMessage,
    bool clearSummaryMessage = false,
    bool clearStandMessage = false,
    bool clearMessages = false,
    bool? refreshing,
  }) => MyProfileState(
    summaryStatus: summaryStatus ?? state.summaryStatus,
    standStatus: standStatus ?? state.standStatus,
    summary: summary ?? state.summary,
    stand: stand ?? state.stand,
    summaryMessage: clearMessages || clearSummaryMessage
        ? null
        : summaryMessage ?? state.summaryMessage,
    standMessage: clearMessages || clearStandMessage
        ? null
        : standMessage ?? state.standMessage,
    refreshing: refreshing ?? state.refreshing,
  );

  void _set(MyProfileState value) {
    state = value;
    notifyListeners();
  }
}

enum UserListKind {
  myContents,
  myLikes,
  myFavorites,
  myComments,
  userContents,
  userFavorites,
  userComments,
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

enum UserListStatus { loading, ready, empty, restricted, failure }

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
    this.busyItemKeys = const {},
  });
  final UserListStatus status;
  final List<Object> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool refreshing;
  final String? message;
  final String? appendMessage;
  final Set<String> busyItemKeys;
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
  int _generation = 0;

  Future<void> loadInitial() async {
    if (_started) return;
    _started = true;
    if (_needsValidUser && (request.userId ?? 0) <= 0) {
      _set(
        const UserListState(status: UserListStatus.failure, message: '用户不存在。'),
      );
      return;
    }
    await retry();
  }

  Future<void> retry() async {
    final generation = ++_generation;
    _set(const UserListState(status: UserListStatus.loading));
    try {
      final page = await _load(1);
      if (generation == _generation) _setPage(page, replace: true);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        UserListState(
          status: error is BusinessException && error.code == 40301
              ? UserListStatus.restricted
              : UserListStatus.failure,
          message: userCenterError(error),
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      _copy(
        status: state.items.isEmpty ? UserListStatus.failure : state.status,
        message: '加载失败，请稍后重试。',
      );
    }
  }

  Future<void> refresh() async {
    if (state.refreshing) return;
    final generation = ++_generation;
    _copy(refreshing: true, clearMessages: true);
    try {
      final page = await _load(1);
      if (generation == _generation) _setPage(page, replace: true);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      if (_restricted(error)) {
        if (state.items.isEmpty) {
          _set(_restrictedState(error));
        } else {
          _copy(
            status: UserListStatus.restricted,
            refreshing: false,
            message: userCenterError(error),
          );
        }
      } else {
        _copy(refreshing: false, message: userCenterError(error));
      }
    } catch (_) {
      if (generation == _generation) {
        _copy(refreshing: false, message: '加载失败，请稍后重试。');
      }
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    _copy(loadingMore: true, clearMessages: true);
    try {
      final page = await _load(state.page + 1);
      if (generation == _generation) _setPage(page, replace: false);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      if (_restricted(error)) {
        if (state.items.isEmpty) {
          _set(_restrictedState(error));
        } else {
          _copy(loadingMore: false, appendMessage: userCenterError(error));
        }
      } else {
        _copy(loadingMore: false, appendMessage: userCenterError(error));
      }
    } catch (_) {
      if (generation == _generation) {
        _copy(loadingMore: false, appendMessage: '加载失败，请稍后重试。');
      }
    }
  }

  Future<void> removeItem(Object item) async {
    if (request.kind != UserListKind.myFavorites &&
        request.kind != UserListKind.myComments) {
      return;
    }
    final key = _itemKey(item);
    if (state.busyItemKeys.contains(key) || !_removableIdIsValid(item)) return;
    final index = state.items.indexWhere((value) => identical(value, item));
    if (index < 0) return;
    final busy = {...state.busyItemKeys, key};
    final remaining = [...state.items]..removeAt(index);
    _setList(
      remaining,
      busy: busy,
      status: remaining.isEmpty ? UserListStatus.empty : UserListStatus.ready,
      message: null,
      clearMessage: true,
    );
    try {
      if (item is UserFavoriteItem) {
        await _repository.removeFavorite(item.contentId);
      } else if (item is UserCommentItem) {
        await _repository.deleteComment(item.commentId);
      }
    } on AppNetworkException catch (error) {
      _restoreRemovedItem(item, index, key, userCenterError(error));
    } catch (_) {
      _restoreRemovedItem(item, index, key, '操作失败，请稍后重试。');
    }
    if (state.busyItemKeys.contains(key)) {
      _copy(busyItemKeys: {...state.busyItemKeys}..remove(key));
    }
  }

  bool _removableIdIsValid(Object item) => switch (item) {
    UserFavoriteItem value => value.contentId > 0,
    UserCommentItem value => value.commentId > 0,
    _ => false,
  };

  void _restoreRemovedItem(Object item, int index, String key, String message) {
    final values = [...state.items];
    if (!values.any((value) => _itemKey(value) == key)) {
      values.insert(index.clamp(0, values.length), item);
    }
    _setList(
      values,
      busy: {...state.busyItemKeys}..remove(key),
      status: values.isEmpty ? UserListStatus.empty : UserListStatus.ready,
      message: message,
    );
  }

  void _setList(
    List<Object> items, {
    required Set<String> busy,
    required UserListStatus status,
    String? message,
    bool clearMessage = false,
  }) => _set(
    UserListState(
      status: status,
      items: items,
      page: state.page,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      refreshing: state.refreshing,
      message: clearMessage ? null : message ?? state.message,
      appendMessage: state.appendMessage,
      busyItemKeys: busy,
    ),
  );

  Future<void> toggleUser(UserBrief item) async {
    final key = _itemKey(item);
    if (item.userId <= 0 ||
        item.relationStatus == 'SELF' ||
        !{
          'NONE',
          'FOLLOWING',
          'FOLLOWED_BY',
          'MUTUAL',
        }.contains(item.relationStatus) ||
        state.busyItemKeys.contains(key)) {
      return;
    }
    final previous = item;
    final follow = !item.followed;
    final optimistic = item.copyWith(
      relationStatus: relationAfterLocalAction(
        item.relationStatus,
        follow: follow,
      ),
    );
    _replaceUser(
      optimistic,
      busy: {...state.busyItemKeys, key},
      message: null,
      clearMessage: true,
    );
    try {
      final authoritative = await _repository.follow(item.userId, follow);
      _replaceUser(
        optimistic.copyWith(relationStatus: authoritative.relationStatus),
        busy: {...state.busyItemKeys}..remove(key),
        message: null,
        clearMessage: true,
      );
    } on AppNetworkException catch (error) {
      _replaceUser(
        previous,
        busy: {...state.busyItemKeys}..remove(key),
        message: userCenterError(error),
      );
    } catch (_) {
      _replaceUser(
        previous,
        busy: {...state.busyItemKeys}..remove(key),
        message: '操作失败，请稍后重试。',
      );
    }
  }

  void _replaceUser(
    UserBrief replacement, {
    required Set<String> busy,
    String? message,
    bool clearMessage = false,
  }) {
    final values = state.items
        .map(
          (item) => item is UserBrief && item.userId == replacement.userId
              ? replacement
              : item,
        )
        .toList();
    _set(
      UserListState(
        status: state.status,
        items: values,
        page: state.page,
        hasMore: state.hasMore,
        loadingMore: state.loadingMore,
        refreshing: state.refreshing,
        message: clearMessage ? null : message ?? state.message,
        appendMessage: state.appendMessage,
        busyItemKeys: busy,
      ),
    );
  }

  Future<UserPage<Object>> _load(int page) async {
    final id = request.userId;
    final result = switch (request.kind) {
      UserListKind.myContents => await _repository.myContents(page, pageSize),
      UserListKind.myLikes => await _repository.myLikes(page, pageSize),
      UserListKind.myFavorites => await _repository.myFavorites(page, pageSize),
      UserListKind.myComments => await _repository.myComments(page, pageSize),
      UserListKind.userContents => await _repository.userContents(
        _validId(id),
        page,
        pageSize,
      ),
      UserListKind.userFavorites => await _repository.userFavorites(
        _validId(id),
        page,
        pageSize,
      ),
      UserListKind.userComments => await _repository.userComments(
        _validId(id),
        page,
        pageSize,
      ),
      UserListKind.followings => await _repository.followings(
        _validId(id),
        page,
        pageSize,
      ),
      UserListKind.followers => await _repository.followers(
        _validId(id),
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
    final merged = replace
        ? page.records
        : <Object>[...state.items, ...page.records];
    final values = <Object>[];
    final seen = <String>{};
    for (final item in merged) {
      if (seen.add(_itemKey(item))) values.add(item);
    }
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
    UserListStatus? status,
    bool? refreshing,
    bool? loadingMore,
    String? message,
    String? appendMessage,
    Set<String>? busyItemKeys,
    bool clearMessages = false,
  }) => _set(
    UserListState(
      status: status ?? state.status,
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
      refreshing: refreshing ?? state.refreshing,
      loadingMore: loadingMore ?? state.loadingMore,
      message: clearMessages ? null : message ?? state.message,
      appendMessage: clearMessages
          ? null
          : appendMessage ?? state.appendMessage,
      busyItemKeys: busyItemKeys ?? state.busyItemKeys,
    ),
  );
  bool get _needsValidUser => switch (request.kind) {
    UserListKind.userContents ||
    UserListKind.userFavorites ||
    UserListKind.userComments ||
    UserListKind.followings ||
    UserListKind.followers => true,
    _ => false,
  };

  int _validId(int? id) {
    if (id == null || id <= 0) throw const ParseException('用户不存在。');
    return id;
  }

  void _set(UserListState value) {
    state = value;
    notifyListeners();
  }
}

bool _restricted(AppNetworkException error) =>
    error is BusinessException && error.code == 40301;

UserListState _restrictedState(AppNetworkException error) => UserListState(
  status: UserListStatus.restricted,
  message: userCenterError(error),
);

String _itemKey(Object item) => switch (item) {
  UserContentItem value => 'content:${value.contentId}',
  UserLikeItem value => 'like:${value.contentId}',
  UserFavoriteItem value => 'favorite:${value.contentId}',
  UserCommentItem value => 'comment:${value.commentId}',
  UserBrief value => 'user:${value.userId}',
  _ => '${item.runtimeType}:${item.hashCode}',
};

enum PublicProfileStatus { loading, ready, notFound, failure }

final class PublicProfileState {
  const PublicProfileState({
    required this.status,
    this.profile,
    this.followBusy = false,
    this.refreshing = false,
    this.message,
  });
  final PublicProfileStatus status;
  final UserProfile? profile;
  final bool followBusy;
  final bool refreshing;
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
    if (userId <= 0) {
      state = const PublicProfileState(
        status: PublicProfileStatus.notFound,
        message: '用户不存在。',
      );
      notifyListeners();
      return;
    }
    if (_started && state.status == PublicProfileStatus.loading) return;
    _started = true;
    final previous = state.profile;
    state = PublicProfileState(
      status: previous == null
          ? PublicProfileStatus.loading
          : PublicProfileStatus.ready,
      profile: previous,
      refreshing: previous != null,
    );
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
    } catch (_) {
      state = const PublicProfileState(
        status: PublicProfileStatus.failure,
        message: '加载失败，请稍后重试。',
      );
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (state.refreshing || userId <= 0) return;
    final previous = state.profile;
    if (previous == null) {
      await load();
      return;
    }
    _started = true;
    state = PublicProfileState(
      status: PublicProfileStatus.ready,
      profile: previous,
      refreshing: true,
    );
    notifyListeners();
    try {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: await _repository.profile(userId),
      );
    } on AppNetworkException catch (error) {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: previous,
        message: userCenterError(error),
      );
    } catch (_) {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: previous,
        message: '加载失败，请稍后重试。',
      );
    }
    notifyListeners();
  }

  Future<void> toggleFollow() async {
    final previous = state.profile;
    if (previous == null ||
        previous.isSelf ||
        state.followBusy ||
        !{
          'NONE',
          'FOLLOWING',
          'FOLLOWED_BY',
          'MUTUAL',
        }.contains(previous.relationStatus)) {
      return;
    }
    final nextFollowed = !previous.followed;
    state = PublicProfileState(
      status: PublicProfileStatus.ready,
      profile: previous.copyWith(
        followerCount: (previous.followerCount + (nextFollowed ? 1 : -1)).clamp(
          0,
          1 << 30,
        ),
        relationStatus: relationAfterLocalAction(
          previous.relationStatus,
          follow: nextFollowed,
        ),
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
    } catch (_) {
      state = PublicProfileState(
        status: PublicProfileStatus.ready,
        profile: previous,
        message: '操作失败，请稍后重试。',
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
  BusinessException(code: 40301) => '该列表受隐私保护，仅用户本人可以查看。',
  BusinessException() => error.message,
  HttpException(statusCode: 403) => '当前账号无权执行此操作。',
  ParseException() => '数据格式异常，请稍后重试。',
  _ => '加载失败，请稍后重试。',
};

abstract interface class AvatarPickerContract {
  Future<XFile?> pick();
}

final class DeviceAvatarPicker implements AvatarPickerContract {
  @override
  Future<XFile?> pick() =>
      ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
}

final class AvatarUpdateState {
  const AvatarUpdateState({this.busy = false, this.avatarUrl, this.message});
  final bool busy;
  final String? avatarUrl;
  final String? message;
}

final avatarUpdateControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AvatarUpdateController(
    ref.watch(userCenterRepositoryProvider),
    ref.watch(avatarFileUploadRepositoryProvider),
    DeviceAvatarPicker(),
    onBound: () {
      ref.invalidate(mySummaryProvider);
      ref.invalidate(myProfileControllerProvider);
    },
  ),
);

final class AvatarUpdateController extends ChangeNotifier {
  AvatarUpdateController(
    this._users,
    this._files,
    this._picker, {
    this.onBound,
  });
  final UserCenterRepositoryContract _users;
  final AvatarFileUploadRepositoryContract _files;
  final AvatarPickerContract _picker;
  final VoidCallback? onBound;
  AvatarUpdateState state = const AvatarUpdateState();
  bool _picking = false;

  Future<void> chooseAndUpload() async {
    if (state.busy || _picking) return;
    _picking = true;
    state = const AvatarUpdateState(busy: true);
    notifyListeners();
    XFile? picked;
    try {
      picked = await _picker.pick();
    } catch (_) {
      _picking = false;
      state = const AvatarUpdateState(message: '无法读取所选图片，请重新选择。');
      notifyListeners();
      return;
    }
    if (picked == null) {
      _picking = false;
      state = const AvatarUpdateState();
      notifyListeners();
      return;
    }
    try {
      final uploaded = await _files.uploadAvatar(picked.path, picked.name);
      try {
        final url = await _users.bindAvatar(uploaded.fileId);
        _complete(url);
      } on BusinessException catch (error) {
        await _safeDelete(uploaded.fileId);
        state = AvatarUpdateState(message: userCenterError(error));
      } on AppNetworkException catch (error) {
        await _reconcile(uploaded, error);
      } catch (_) {
        state = const AvatarUpdateState(message: '头像绑定结果暂时无法确认，请刷新个人主页。');
      }
    } on AppNetworkException catch (error) {
      state = AvatarUpdateState(message: userCenterError(error));
    } catch (_) {
      state = const AvatarUpdateState(message: '头像上传失败，原头像已保留。');
    }
    _picking = false;
    notifyListeners();
  }

  Future<void> _reconcile(
    UploadedFile uploaded,
    AppNetworkException error,
  ) async {
    try {
      final summary = await _users.summary();
      if (summary.avatarUrl == uploaded.url) {
        _complete(uploaded.url);
        return;
      }
      await _safeDelete(uploaded.fileId);
    } catch (_) {
      // The bind outcome is ambiguous, so the uploaded file must be retained.
    }
    state = AvatarUpdateState(message: userCenterError(error));
  }

  Future<void> _safeDelete(int fileId) async {
    try {
      await _files.delete(fileId);
    } catch (_) {}
  }

  void _complete(String url) {
    state = AvatarUpdateState(avatarUrl: url);
    onBound?.call();
  }
}
