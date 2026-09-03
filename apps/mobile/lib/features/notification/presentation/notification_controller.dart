import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/network_exceptions.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

enum NotificationLoadStatus { loading, ready, empty, failure }

final class NotificationState {
  const NotificationState({
    required this.status,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.refreshing = false,
    this.loadingMore = false,
    this.actionBusy = false,
    this.message,
    this.appendMessage,
  });
  final NotificationLoadStatus status;
  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final bool refreshing;
  final bool loadingMore;
  final bool actionBusy;
  final String? message;
  final String? appendMessage;
}

final notificationControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => NotificationController(
    ref.watch(notificationRepositoryProvider),
    onUnreadChanged: () => ref.invalidate(notificationUnreadCountProvider),
  ),
);

final class NotificationController extends ChangeNotifier {
  NotificationController(this._repository, {this.onUnreadChanged});
  static const pageSize = 20;
  final NotificationRepositoryContract _repository;
  final VoidCallback? onUnreadChanged;
  NotificationState state = const NotificationState(
    status: NotificationLoadStatus.loading,
  );
  bool _started = false;

  Future<void> loadInitial() async {
    if (_started) return;
    _started = true;
    await retry();
  }

  Future<void> retry() async {
    _set(const NotificationState(status: NotificationLoadStatus.loading));
    try {
      _setPage(await _repository.list(1, pageSize), replace: true);
    } on AppNetworkException catch (error) {
      _set(
        NotificationState(
          status: NotificationLoadStatus.failure,
          message: _message(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.refreshing) return;
    _copy(refreshing: true, clearMessages: true);
    try {
      _setPage(await _repository.list(1, pageSize), replace: true);
      onUnreadChanged?.call();
    } on AppNetworkException catch (error) {
      _copy(refreshing: false, message: _message(error));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    _copy(loadingMore: true, clearMessages: true);
    try {
      _setPage(
        await _repository.list(state.page + 1, pageSize),
        replace: false,
      );
    } on AppNetworkException catch (error) {
      _copy(loadingMore: false, appendMessage: _message(error));
    }
  }

  Future<bool> markRead(AppNotification item) async {
    if (item.read) return true;
    final previous = state;
    _set(
      _stateWithItems([
        for (final value in state.items)
          if (value.notificationId == item.notificationId)
            value.asRead()
          else
            value,
      ]),
    );
    try {
      final success = await _repository.markRead(item.notificationId);
      if (!success) {
        throw const UnknownException('Notification was not updated.');
      }
      onUnreadChanged?.call();
      return true;
    } on AppNetworkException catch (error) {
      _set(
        NotificationState(
          status: previous.status,
          items: previous.items,
          page: previous.page,
          hasMore: previous.hasMore,
          message: _message(error),
        ),
      );
      return false;
    }
  }

  Future<void> markAllRead() async {
    if (state.actionBusy || !state.items.any((item) => !item.read)) return;
    _copy(actionBusy: true, clearMessages: true);
    try {
      await _repository.markAllRead();
      _set(_stateWithItems([for (final item in state.items) item.asRead()]));
      onUnreadChanged?.call();
    } on AppNetworkException catch (error) {
      _copy(actionBusy: false, message: _message(error));
    }
  }

  NotificationState _stateWithItems(List<AppNotification> items) =>
      NotificationState(
        status: items.isEmpty
            ? NotificationLoadStatus.empty
            : NotificationLoadStatus.ready,
        items: List.unmodifiable(items),
        page: state.page,
        hasMore: state.hasMore,
      );

  void _setPage(NotificationPage page, {required bool replace}) {
    final merged = replace ? page.records : [...state.items, ...page.records];
    final unique = <int, AppNotification>{};
    for (final item in merged) {
      unique.putIfAbsent(item.notificationId, () => item);
    }
    _set(
      NotificationState(
        status: unique.isEmpty
            ? NotificationLoadStatus.empty
            : NotificationLoadStatus.ready,
        items: List.unmodifiable(unique.values),
        page: page.pageNum,
        hasMore: page.hasMore,
      ),
    );
  }

  void _copy({
    bool? refreshing,
    bool? loadingMore,
    bool? actionBusy,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => _set(
    NotificationState(
      status: state.status,
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
      refreshing: refreshing ?? state.refreshing,
      loadingMore: loadingMore ?? state.loadingMore,
      actionBusy: actionBusy ?? state.actionBusy,
      message: clearMessages ? null : message ?? state.message,
      appendMessage: clearMessages
          ? null
          : appendMessage ?? state.appendMessage,
    ),
  );

  void _set(NotificationState value) {
    state = value;
    notifyListeners();
  }
}

String _message(AppNetworkException error) => switch (error) {
  NetworkException() => '网络连接失败，请检查后重试。',
  TimeoutException() => '请求超时，请稍后重试。',
  BusinessException() => error.message,
  ParseException() => '通知数据格式异常，请稍后重试。',
  _ => '通知加载失败，请稍后重试。',
};
