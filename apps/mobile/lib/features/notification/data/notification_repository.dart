import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/app_notification.dart';
import 'notification_api.dart';

abstract interface class NotificationRepositoryContract {
  Future<NotificationPage> list(int page, int size);
  Future<int> unreadCount();
  Future<bool> markRead(int id);
  Future<int> markAllRead();
}

final notificationRepositoryProvider = Provider<NotificationRepositoryContract>(
  (ref) =>
      NotificationRepository(NotificationApi(ref.watch(apiClientProvider))),
);

final notificationUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationRepositoryProvider).unreadCount(),
);

final class NotificationRepository implements NotificationRepositoryContract {
  const NotificationRepository(this._api);
  final NotificationApi _api;
  @override
  Future<NotificationPage> list(int page, int size) =>
      _api.list(pageNum: page, pageSize: size);
  @override
  Future<int> unreadCount() => _api.unreadCount();
  @override
  Future<bool> markRead(int id) => _api.markRead(id);
  @override
  Future<int> markAllRead() => _api.markAllRead();
}
