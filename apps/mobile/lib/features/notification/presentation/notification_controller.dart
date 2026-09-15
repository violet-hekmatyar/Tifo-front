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
    this.readBusyIds = const <int>{},
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
  final Set<int> readBusyIds;
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
  int _generation = 0;
  int _markAllEpoch = 0;
  int _lastSuccessfulMarkAllEpoch = 0;
  final Set<int> _readOverrides = <int>{};

  Future<void> loadInitial() async {
    if (_started) return;
    _started = true;
    await retry();
  }

  Future<void> retry() async {
    final generation = ++_generation;
    _set(
      state.items.isEmpty
          ? const NotificationState(status: NotificationLoadStatus.loading)
          : _copyValue(
              status: NotificationLoadStatus.ready,
              refreshing: true,
              loadingMore: false,
              clearMessages: true,
            ),
    );
    try {
      final page = await _repository.list(1, pageSize);
      if (generation != _generation) return;
      _setPage(page, replace: true);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        state.items.isEmpty
            ? NotificationState(
                status: NotificationLoadStatus.failure,
                message: _message(error),
              )
            : _copyValue(
                status: NotificationLoadStatus.ready,
                refreshing: false,
                message: _message(error),
              ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.refreshing) return;
    final generation = ++_generation;
    _copy(refreshing: true, loadingMore: false, clearMessages: true);
    try {
      final page = await _repository.list(1, pageSize);
      if (generation != _generation) return;
      _setPage(page, replace: true);
      onUnreadChanged?.call();
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(refreshing: false, message: _message(error));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    final requestedPage = state.page + 1;
    _copy(loadingMore: true, clearMessages: true);
    try {
      final page = await _repository.list(requestedPage, pageSize);
      if (generation != _generation) return;
      if (state.page >= page.pageNum) {
        _copy(loadingMore: false);
        return;
      }
      _setPage(page, replace: false);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(loadingMore: false, appendMessage: _message(error));
    }
  }

  Future<bool> markRead(AppNotification item) async {
    if (item.read) return true;
    if (item.notificationId <= 0 ||
        state.readBusyIds.contains(item.notificationId)) {
      return false;
    }
    final id = item.notificationId;
    final markAllEpoch = _markAllEpoch;
    _set(
      _copyValue(
        items: [
          for (final value in state.items)
            if (value.notificationId == id) value.asRead() else value,
        ],
        readBusyIds: {...state.readBusyIds, id},
      ),
    );
    try {
      final success = await _repository.markRead(id);
      if (!success) {
        throw const UnknownException('Notification was not updated.');
      }
      _set(
        _copyValue(
          items: [
            for (final value in state.items)
              if (value.notificationId == id) value.asRead() else value,
          ],
          readBusyIds: {...state.readBusyIds}..remove(id),
          clearMessages: true,
        ),
      );
      _readOverrides.add(id);
      onUnreadChanged?.call();
      return true;
    } on AppNetworkException catch (error) {
      final markAllWon =
          _lastSuccessfulMarkAllEpoch >= markAllEpoch &&
          _lastSuccessfulMarkAllEpoch > 0;
      _set(
        _copyValue(
          items: markAllWon
              ? state.items
              : [
                  for (final value in state.items)
                    if (value.notificationId == id) item else value,
                ],
          readBusyIds: {...state.readBusyIds}..remove(id),
          message: _message(error),
        ),
      );
      return false;
    }
  }

  Future<void> markAllRead() async {
    if (state.actionBusy || !state.items.any((item) => !item.read)) return;
    final epoch = ++_markAllEpoch;
    _copy(actionBusy: true, clearMessages: true);
    try {
      await _repository.markAllRead();
      _lastSuccessfulMarkAllEpoch = epoch;
      _readOverrides.addAll(state.items.map((item) => item.notificationId));
      _set(
        _copyValue(
          items: [for (final item in state.items) item.asRead()],
          actionBusy: false,
          clearMessages: true,
        ),
      );
      onUnreadChanged?.call();
    } on AppNetworkException catch (error) {
      _copy(actionBusy: false, message: _message(error));
    }
  }

  void _setPage(NotificationPage page, {required bool replace}) {
    final merged = replace ? page.records : [...state.items, ...page.records];
    final unique = <int, AppNotification>{};
    for (final item in merged) {
      final shouldRead = _readOverrides.contains(item.notificationId);
      unique.putIfAbsent(
        item.notificationId,
        () => shouldRead ? item.asRead() : item,
      );
    }
    if (replace) {
      _readOverrides.removeWhere((id) => !unique.containsKey(id));
    }
    _set(
      NotificationState(
        status: unique.isEmpty
            ? NotificationLoadStatus.empty
            : NotificationLoadStatus.ready,
        items: List.unmodifiable(unique.values),
        page: page.pageNum,
        hasMore: page.hasMore,
        refreshing: false,
        loadingMore: false,
        actionBusy: state.actionBusy,
        readBusyIds: state.readBusyIds,
      ),
    );
  }

  NotificationState _copyValue({
    NotificationLoadStatus? status,
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    bool? refreshing,
    bool? loadingMore,
    bool? actionBusy,
    Set<int>? readBusyIds,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => NotificationState(
    status: status ?? state.status,
    items: List.unmodifiable(items ?? state.items),
    page: page ?? state.page,
    hasMore: hasMore ?? state.hasMore,
    refreshing: refreshing ?? state.refreshing,
    loadingMore: loadingMore ?? state.loadingMore,
    actionBusy: actionBusy ?? state.actionBusy,
    readBusyIds: Set.unmodifiable(readBusyIds ?? state.readBusyIds),
    message: clearMessages ? null : message ?? state.message,
    appendMessage: clearMessages ? null : appendMessage ?? state.appendMessage,
  );

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
      readBusyIds: state.readBusyIds,
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
