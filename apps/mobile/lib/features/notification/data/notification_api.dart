import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/page_result.dart';
import '../domain/app_notification.dart';

final class NotificationApi {
  const NotificationApi(this._client);
  final ApiClient _client;

  Future<NotificationPage> list({int pageNum = 1, int pageSize = 20}) =>
      _client.get(
        '/api/app/notifications',
        queryParameters: {'pageNum': pageNum, 'pageSize': pageSize},
        decode: (raw) {
          final page = PageResult.fromRaw(raw, _notification);
          return NotificationPage(
            records: page.records,
            pageNum: page.pageNum,
            pages: page.pages,
            total: page.total,
          );
        },
      );

  Future<int> unreadCount() => _client.get(
    '/api/app/notifications/unread-count',
    decode: (raw) {
      final value = jsonInt(jsonMap(raw)?['total']);
      if (value == null) throw const ParseException('Unread count is invalid.');
      return value;
    },
  );

  Future<bool> markRead(int id) => _client.post(
    '/api/app/notifications/$id/read',
    decode: (raw) => raw == true,
  );

  Future<int> markAllRead() => _client.post(
    '/api/app/notifications/read-all',
    decode: (raw) => jsonInt(jsonMap(raw)?['updatedCount']) ?? 0,
  );
}

AppNotification _notification(Object? raw) {
  final map = jsonMap(raw);
  final id = jsonInt(map?['notificationId']);
  if (map == null || id == null) {
    throw const ParseException('Notification item is invalid.');
  }
  final rawType = jsonString(map['notificationType']) ?? 'UNKNOWN';
  final rawTargetType = jsonString(map['targetType']) ?? 'UNKNOWN';
  return AppNotification(
    notificationId: id,
    type: AppNotificationType.fromWire(rawType),
    rawType: rawType,
    actor: _actor(map['actor']),
    targetType: NotificationTargetType.fromWire(rawTargetType),
    rawTargetType: rawTargetType,
    targetId: jsonInt(map['targetId']),
    secondaryTargetType: map['secondaryTargetType'] == null
        ? null
        : NotificationTargetType.fromWire(
            jsonString(map['secondaryTargetType']),
          ),
    secondaryTargetId: jsonInt(map['secondaryTargetId']),
    title: jsonString(map['title']) ?? '互动通知',
    content: jsonString(map['content']) ?? '',
    read: map['read'] == true,
    readTime: jsonIsoDateTime(map['readTime']),
    createTime: jsonIsoDateTime(map['createTime']),
    targetAvailable: map['targetAvailable'] != false,
    targetPreview: _preview(map['targetPreview']),
  );
}

NotificationActor? _actor(Object? raw) {
  final map = jsonMap(raw);
  final id = jsonInt(map?['userId']);
  if (map == null || id == null) return null;
  return NotificationActor(
    userId: id,
    nickname: jsonString(map['nickname']) ?? '用户',
    avatarUrl: jsonString(map['avatarUrl']),
  );
}

NotificationTargetPreview? _preview(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  return NotificationTargetPreview(
    contentTitle: jsonString(map['contentTitle']),
    coverUrl: jsonString(map['coverUrl']),
    commentExcerpt: jsonString(map['commentExcerpt']),
  );
}
