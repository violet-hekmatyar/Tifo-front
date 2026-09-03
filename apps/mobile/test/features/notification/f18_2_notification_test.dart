import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/notification/data/notification_repository.dart';
import 'package:tifo/features/notification/domain/app_notification.dart';
import 'package:tifo/features/notification/presentation/notifications_page.dart';

void main() {
  testWidgets(
    'renders interaction types, reads items and blocks unavailable target',
    (tester) async {
      final repository = _Repository();
      final router = GoRouter(
        initialLocation: '/messages',
        routes: [
          GoRoute(
            path: '/messages',
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/contents/:id',
            builder: (_, state) => Text('内容 ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(repository),
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      for (final title in ['点赞', '评论', '回复', '评论点赞', '关注', '系统']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('notification_unavailable')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('notification_1')));
      await tester.pumpAndSettle();
      expect(repository.readIds, [1]);
      expect(find.text('内容 90'), findsOneWidget);

      router.go('/messages');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification_4')));
      await tester.pumpAndSettle();
      expect(repository.readIds, contains(4));
      expect(router.routeInformationProvider.value.uri.path, '/messages');

      await tester.tap(find.byKey(const ValueKey('notification_read_all')));
      await tester.pumpAndSettle();
      expect(repository.readAllCalls, 1);
      expect(
        find.byKey(const ValueKey('notification_unread_dot')),
        findsNothing,
      );
    },
  );
}

final class _Repository implements NotificationRepositoryContract {
  final readIds = <int>[];
  int readAllCalls = 0;
  final items = <AppNotification>[
    _item(1, AppNotificationType.contentLiked, '点赞', targetId: 90),
    _item(2, AppNotificationType.contentCommented, '评论', targetId: 90),
    _item(3, AppNotificationType.commentReplied, '回复', targetId: 91),
    _item(
      4,
      AppNotificationType.commentLiked,
      '评论点赞',
      targetId: 91,
      available: false,
    ),
    _item(
      5,
      AppNotificationType.userFollowed,
      '关注',
      targetId: 22,
      targetType: NotificationTargetType.user,
    ),
    _item(
      6,
      AppNotificationType.system,
      '系统',
      targetType: NotificationTargetType.system,
    ),
  ];

  @override
  Future<NotificationPage> list(int page, int size) async => NotificationPage(
    records: items,
    pageNum: 1,
    pages: 1,
    total: items.length,
  );
  @override
  Future<int> unreadCount() async => items.where((item) => !item.read).length;
  @override
  Future<bool> markRead(int id) async {
    readIds.add(id);
    return true;
  }

  @override
  Future<int> markAllRead() async {
    readAllCalls++;
    return items.length;
  }
}

AppNotification _item(
  int id,
  AppNotificationType type,
  String title, {
  int? targetId,
  bool available = true,
  NotificationTargetType targetType = NotificationTargetType.content,
}) => AppNotification(
  notificationId: id,
  type: type,
  rawType: type.name,
  targetType: targetType,
  rawTargetType: targetType.name,
  targetId: targetId,
  secondaryTargetType:
      type == AppNotificationType.commentReplied ||
          type == AppNotificationType.commentLiked
      ? NotificationTargetType.content
      : null,
  secondaryTargetId:
      type == AppNotificationType.commentReplied ||
          type == AppNotificationType.commentLiked
      ? 90
      : null,
  title: title,
  content: '$title通知正文',
  read: false,
  targetAvailable: available,
);
