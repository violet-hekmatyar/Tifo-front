import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/notification/data/notification_api.dart';
import 'package:tifo/features/notification/domain/app_notification.dart';

void main() {
  const base = 'https://api.test';
  late DioAdapter adapter;
  late NotificationApi api;

  setUp(() {
    final dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = NotificationApi(
      ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio),
    );
  });

  test(
    'SET-05 notification API decodes page, nullable preview, ISO and read responses',
    () async {
      adapter
        ..onGet(
          '$base/api/app/notifications',
          (server) => server.reply(
            200,
            _result({
              'records': [
                {
                  'notificationId': 12,
                  'notificationType': 'CONTENT_COMMENTED',
                  'targetType': 'CONTENT',
                  'targetId': 88,
                  'title': '评论',
                  'content': '有人评论了你的内容',
                  'read': false,
                  'readTime': null,
                  'createTime': '2026-09-15T10:20:30Z',
                  'targetAvailable': true,
                  'actor': {
                    'userId': 7,
                    'nickname': '长昵称用户',
                    'avatarUrl': '/avatar.png',
                  },
                  'targetPreview': {
                    'contentTitle': '很长的内容标题',
                    'coverUrl': '/cover.png',
                    'commentExcerpt': null,
                  },
                },
                {
                  'notificationId': 13,
                  'notificationType': 'FUTURE_TYPE',
                  'targetType': 'FUTURE_TARGET',
                  'targetId': -4,
                  'title': null,
                  'content': null,
                  'read': true,
                  'targetAvailable': false,
                  'actor': null,
                  'targetPreview': null,
                },
              ],
              'total': 2,
              'pageNum': 1,
              'pageSize': 20,
              'pages': 1,
            }),
          ),
          queryParameters: {'pageNum': 1, 'pageSize': 20},
        )
        ..onGet(
          '$base/api/app/notifications/unread-count',
          (server) => server.reply(200, _result({'total': 12000})),
        )
        ..onPost(
          '$base/api/app/notifications/12/read',
          (server) => server.reply(200, _result(true)),
        )
        ..onPost(
          '$base/api/app/notifications/read-all',
          (server) => server.reply(200, _result({'updatedCount': 2})),
        );

      final page = await api.list();
      expect(page.records, hasLength(2));
      expect(page.records.first.actor?.nickname, '长昵称用户');
      expect(page.records.first.targetPreview?.coverUrl, '/cover.png');
      expect(page.records.first.createTime, isNotNull);
      expect(page.records.last.type, AppNotificationType.unknown);
      expect(page.records.last.title, '互动通知');
      expect(page.records.last.content, isEmpty);
      expect(await api.unreadCount(), 12000);
      expect(await api.markRead(12), isTrue);
      expect(await api.markAllRead(), 2);
    },
  );

  test('SET-05 notification API preserves business error contract', () async {
    adapter.onGet(
      '$base/api/app/notifications/unread-count',
      (server) => server.reply(200, {
        'code': 42901,
        'message': '稍后重试',
        'data': null,
        'traceId': 'trace-notify',
      }),
    );

    await expectLater(
      api.unreadCount(),
      throwsA(
        isA<BusinessException>()
            .having((error) => error.code, 'code', 42901)
            .having((error) => error.traceId, 'traceId', 'trace-notify'),
      ),
    );
  });
}

Map<String, Object?> _result(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
