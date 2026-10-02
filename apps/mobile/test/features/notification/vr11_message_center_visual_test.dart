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
  testWidgets('VR11 message home exposes only the real interaction entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1624);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _Repository();
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(repository, router));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('消息_title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('messages_interactions_entry')),
      findsOneWidget,
    );
    expect(find.text('私信'), findsNothing);
    expect(find.byKey(const ValueKey('notification_1')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('messages_interactions_entry')))
          .height,
      64,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('messages_interaction_icon'))),
      const Size(44, 44),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('消息_title')))
          .style
          ?.fontSize,
      18,
    );
    expect(
      tester
              .getCenter(
                find.byKey(const ValueKey('messages_interaction_icon')),
              )
              .dy -
          tester.getCenter(find.byKey(const ValueKey('消息_title'))).dy,
      closeTo(62, 4),
    );

    await tester.tap(find.byKey(const ValueKey('messages_interactions_entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('互动消息_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification_read_all')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('notification_1'))).height,
      60,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('notification_avatar_1'))),
      const Size(40, 40),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('notification_cover_1'))),
      const Size(40, 40),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('notification_avatar_1'))).dy -
          tester.getCenter(find.byKey(const ValueKey('互动消息_title'))).dy,
      closeTo(60, 4),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('notification_2'))).dy -
          tester.getCenter(find.byKey(const ValueKey('notification_1'))).dy,
      closeTo(60, 3),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('notification_cover_placeholder_3')),
      ),
      const Size(40, 40),
    );
    expect(find.text('没有更多消息了'), findsNothing);
  });

  testWidgets('VR11 hides read-all action when there are no unread items', (
    tester,
  ) async {
    final router = _router(initialLocation: '/messages/interactions');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(_Repository(allRead: true), router));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notification_read_all')), findsNothing);
  });

  testWidgets('VR11 interactions fit 360dp at 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _router(initialLocation: '/messages/interactions');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: _app(_Repository(), router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('互动消息_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(_Repository repository, GoRouter router) => ProviderScope(
  overrides: [
    notificationRepositoryProvider.overrideWithValue(repository),
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
  ],
  child: MaterialApp.router(routerConfig: router),
);

GoRouter _router({String initialLocation = '/app/messages'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/app/messages', builder: (_, _) => const MessagesHomePage()),
    GoRoute(
      path: '/messages/interactions',
      builder: (_, _) => const NotificationsPage(),
    ),
  ],
);

final class _Repository implements NotificationRepositoryContract {
  _Repository({this.allRead = false});

  final bool allRead;

  final _item = AppNotification(
    notificationId: 1,
    type: AppNotificationType.contentLiked,
    rawType: 'CONTENT_LIKED',
    targetType: NotificationTargetType.content,
    rawTargetType: 'CONTENT',
    targetId: 901,
    title: '赞了你的帖子',
    content: '互动消息',
    createTime: DateTime(2026, 9, 28, 12),
    read: false,
    targetAvailable: true,
    targetPreview: NotificationTargetPreview(
      coverUrl: 'http://localhost/cover.png',
    ),
  );

  final _secondItem = AppNotification(
    notificationId: 2,
    type: AppNotificationType.contentLiked,
    rawType: 'CONTENT_LIKED',
    targetType: NotificationTargetType.content,
    rawTargetType: 'CONTENT',
    targetId: 902,
    title: '赞了你的帖子',
    content: '互动消息',
    createTime: DateTime(2026, 9, 27, 12),
    read: false,
    targetAvailable: true,
    targetPreview: NotificationTargetPreview(
      coverUrl: 'http://localhost/cover2.png',
    ),
  );

  final _thirdItem = AppNotification(
    notificationId: 3,
    type: AppNotificationType.contentLiked,
    rawType: 'CONTENT_LIKED',
    targetType: NotificationTargetType.content,
    rawTargetType: 'CONTENT',
    targetId: 903,
    title: '赞了你的帖子',
    content: '互动消息',
    createTime: DateTime(2026, 9, 26, 12),
    read: false,
    targetAvailable: true,
  );

  @override
  Future<NotificationPage> list(int page, int size) async => NotificationPage(
    records: [
      if (allRead) _item.asRead() else _item,
      if (allRead) _secondItem.asRead() else _secondItem,
      if (allRead) _thirdItem.asRead() else _thirdItem,
    ],
    pageNum: 1,
    pages: 1,
    total: 3,
  );

  @override
  Future<int> unreadCount() async => allRead ? 0 : 2;

  @override
  Future<bool> markRead(int id) async => true;

  @override
  Future<int> markAllRead() async => 1;
}
