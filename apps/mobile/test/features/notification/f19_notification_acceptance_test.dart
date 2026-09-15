import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/notification/data/notification_repository.dart';
import 'package:tifo/features/notification/domain/app_notification.dart';
import 'package:tifo/features/notification/presentation/notification_controller.dart';
import 'package:tifo/features/notification/presentation/notifications_page.dart';
import 'package:tifo/features/main_shell/presentation/main_shell_page.dart';

void main() {
  test(
    'MSG-03 valid targets route while invalid and unavailable targets do not',
    () {
      expect(_item(1, targetId: 9).route, '/contents/9');
      expect(
        _item(
          2,
          targetType: NotificationTargetType.comment,
          secondaryTargetType: NotificationTargetType.content,
          secondaryTargetId: 10,
        ).route,
        '/contents/10',
      );
      expect(
        _item(3, targetType: NotificationTargetType.user, targetId: 8).route,
        '/users/8',
      );
      expect(_item(4, targetId: 0).route, isNull);
      expect(_item(5, targetId: -1).route, isNull);
      expect(_item(6, targetId: 9, available: false).route, isNull);
      expect(
        _item(
          7,
          type: AppNotificationType.unknown,
          targetType: NotificationTargetType.unknown,
        ).route,
        isNull,
      );
    },
  );

  test(
    'MSG-04 ready refresh failure preserves records and exposes feedback',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)]);
      final controller = NotificationController(repository);
      await controller.loadInitial();
      repository.nextListError = const BusinessException('刷新失败', code: 50001);
      await controller.refresh();

      expect(controller.state.status, NotificationLoadStatus.ready);
      expect(controller.state.items.single.notificationId, 1);
      expect(controller.state.message, '刷新失败');
      expect(controller.state.refreshing, isFalse);
    },
  );

  test(
    'MSG-05 append dedupes pages and retries the original failed page',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)], pageNum: 1, pages: 3)
        ..pages[2] = _page([_item(1), _item(2)], pageNum: 2, pages: 3)
        ..pages[3] = _page([_item(3)], pageNum: 3, pages: 3);
      final controller = NotificationController(repository);
      await controller.loadInitial();
      await controller.loadMore();
      await controller.loadMore();

      expect(controller.state.items.map((item) => item.notificationId), [
        1,
        2,
        3,
      ]);
      expect(repository.listCalls, [1, 2, 3]);
    },
  );

  test(
    'MSG-06 already-read and invalid notifications make zero read calls',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1, read: true)]);
      final controller = NotificationController(repository);
      await controller.loadInitial();

      expect(await controller.markRead(controller.state.items.single), isTrue);
      expect(await controller.markRead(_item(-1)), isFalse);
      expect(repository.readCalls, isEmpty);
    },
  );

  test(
    'MSG-07 different notification failures merge by item and busy state',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1), _item(2)])
        ..readPending[1] = Completer<bool>()
        ..readPending[2] = Completer<bool>();
      final controller = NotificationController(repository);
      await controller.loadInitial();
      final first = controller.markRead(controller.state.items[0]);
      final second = controller.markRead(controller.state.items[1]);
      expect(controller.state.readBusyIds, {1, 2});

      repository.readPending[2]!.complete(true);
      expect(await second, isTrue);
      repository.readPending[1]!.completeError(const NetworkException('网络失败'));
      expect(await first, isFalse);
      expect(controller.state.items[0].read, isFalse);
      expect(controller.state.items[1].read, isTrue);
      expect(controller.state.readBusyIds, isEmpty);
    },
  );

  test('MSG-07 same notification is deduped while request is busy', () async {
    final repository = _NotificationRepository()
      ..pages[1] = _page([_item(1)])
      ..readPending[1] = Completer<bool>();
    final controller = NotificationController(repository);
    await controller.loadInitial();
    final original = controller.state.items.single;
    final first = controller.markRead(original);
    expect(await controller.markRead(original), isFalse);
    expect(repository.readCalls, [1]);
    repository.readPending[1]!.complete(true);
    expect(await first, isTrue);
  });

  test(
    'MSG-08 mark-all success wins over a concurrent individual failure',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1), _item(2)])
        ..readPending[1] = Completer<bool>()
        ..markAllPending = Completer<int>();
      final controller = NotificationController(repository);
      await controller.loadInitial();
      final individual = controller.markRead(controller.state.items.first);
      final all = controller.markAllRead();
      repository.markAllPending!.complete(2);
      await all;
      repository.readPending[1]!.completeError(
        const BusinessException('单条失败', code: 50002),
      );
      expect(await individual, isFalse);
      expect(controller.state.items.every((item) => item.read), isTrue);
      expect(controller.state.actionBusy, isFalse);
    },
  );

  test(
    'MSG-08 mark-all failure preserves unread rows and prevents duplicate calls',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)])
        ..markAllPending = Completer<int>();
      final controller = NotificationController(repository);
      await controller.loadInitial();
      final all = controller.markAllRead();
      await controller.markAllRead();
      expect(repository.markAllCalls, 1);
      repository.markAllPending!.completeError(
        const BusinessException('全部失败', code: 50003),
      );
      await all;
      expect(controller.state.items.single.read, isFalse);
      expect(controller.state.actionBusy, isFalse);
      expect(controller.state.message, '全部失败');
    },
  );

  test(
    'MSG-09 unread provider failure does not replace local list state',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)]);
      final controller = NotificationController(repository);
      await controller.loadInitial();
      repository.unreadError = const NetworkException('未读失败');
      expect(controller.state.items.where((item) => !item.read), hasLength(1));
    },
  );

  testWidgets('R13A-09 notification page fits 360px at 1.4x text', (
    tester,
  ) async {
    await _pumpNotificationAt(tester, 360);
    expect(find.byKey(const ValueKey('notification_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R13A-09 notification page fits 412px at 1.4x text', (
    tester,
  ) async {
    await _pumpNotificationAt(tester, 412);
    expect(find.byKey(const ValueKey('notification_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'MSG-10 returning from content preserves records, page and scroll offset',
    (tester) async {
      final repository = _NotificationRepository()
        ..pages[1] = _page(
          List.generate(20, (index) => _item(index + 1, targetId: index + 1)),
        );
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
              AppConfig.fromValues(apiBaseUrl: 'https://api.test'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, -420));
      await tester.pumpAndSettle();
      final initialOffset = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(initialOffset, greaterThan(0));
      await tester.ensureVisible(find.byKey(const ValueKey('notification_10')));
      final before = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      await tester.tap(find.byKey(const ValueKey('notification_10')));
      await tester.pumpAndSettle();
      expect(repository.readCalls, [10]);
      expect(find.text('内容 10'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      final after = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(after, closeTo(before, 0.1));
      expect(repository.listCalls, [1]);
      expect(find.byKey(const ValueKey('notification_10')), findsOneWidget);
    },
  );

  test(
    'R13A-01 pending mark-read remains authoritative after an old refresh',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)])
        ..readPending[1] = Completer<bool>();
      final oldRefresh = Completer<NotificationPage>();
      final controller = NotificationController(repository);
      await controller.loadInitial();
      repository.listPending[1] = [oldRefresh];

      final read = controller.markRead(controller.state.items.single);
      final refresh = controller.refresh();
      oldRefresh.complete(_page([_item(1)]));
      await refresh;
      expect(controller.state.items.single.read, isFalse);
      expect(controller.state.readBusyIds, {1});

      repository.readPending[1]!.complete(true);
      expect(await read, isTrue);
      expect(controller.state.items.single.read, isTrue);
      expect(controller.state.readBusyIds, isEmpty);
    },
  );

  test('R13A-02 mark-all wins over an older refresh response', () async {
    final repository = _NotificationRepository()
      ..pages[1] = _page([_item(1), _item(2)]);
    final oldRefresh = Completer<NotificationPage>();
    final markAll = Completer<int>();
    repository.markAllPending = markAll;
    final controller = NotificationController(repository);
    await controller.loadInitial();
    repository.listPending[1] = [oldRefresh];

    final refresh = controller.refresh();
    final all = controller.markAllRead();
    markAll.complete(2);
    await all;
    expect(controller.state.items.every((item) => item.read), isTrue);
    oldRefresh.complete(_page([_item(1), _item(2)]));
    await refresh;
    expect(controller.state.items.every((item) => item.read), isTrue);
    expect(controller.state.actionBusy, isFalse);
  });

  test(
    'R13A-03 inverse retry and refresh completion keeps the newest generation',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)]);
      final old = Completer<NotificationPage>();
      final newest = Completer<NotificationPage>();
      final controller = NotificationController(repository);
      await controller.loadInitial();
      repository.listPending[1] = [old, newest];

      final refresh = controller.refresh();
      final retry = controller.retry();
      newest.complete(_page([_item(2)]));
      await retry;
      old.complete(_page([_item(1)]));
      await refresh;
      expect(controller.state.items.map((item) => item.notificationId), [2]);
      expect(controller.state.page, 1);
    },
  );

  test(
    'R13A-04 append failure preserves the page and retries that page',
    () async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([_item(1)], pages: 2)
        ..pages[2] = _page([_item(1), _item(2)], pageNum: 2, pages: 2)
        ..listErrors[2] = [const BusinessException('追加失败', code: 50010)];
      final controller = NotificationController(repository);
      await controller.loadInitial();
      await controller.loadMore();
      expect(controller.state.page, 1);
      expect(controller.state.items.map((item) => item.notificationId), [1]);
      expect(controller.state.appendMessage, '追加失败');
      await controller.loadMore();
      expect(repository.listCalls, [1, 2, 2]);
      expect(controller.state.page, 2);
      expect(controller.state.items.map((item) => item.notificationId), [1, 2]);
    },
  );

  testWidgets(
    'R13A-05 false, network and business read failures rollback without navigation',
    (tester) async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([
          _item(1, targetId: 1),
          _item(2, targetId: 2),
          _item(3, targetId: 3),
          _item(4, targetId: 4),
        ])
        ..readOutcomes[1] = [false]
        ..readOutcomes[2] = [const NetworkException('网络失败')]
        ..readOutcomes[3] = [const BusinessException('业务失败', code: 50011)]
        ..readOutcomes[4] = [true];
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
              AppConfig.fromValues(apiBaseUrl: 'https://api.test'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      for (final id in [1, 2, 3]) {
        await tester.tap(find.byKey(ValueKey('notification_$id')));
        await tester.pumpAndSettle();
        expect(find.text('内容 $id'), findsNothing);
        expect(find.byKey(const ValueKey('notification_1')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('notification_unread_dot')),
          findsNWidgets(4),
        );
      }
      await tester.tap(find.byKey(const ValueKey('notification_4')));
      await tester.pumpAndSettle();
      expect(find.text('内容 4'), findsOneWidget);
      expect(repository.readCalls, [1, 2, 3, 4]);
    },
  );

  testWidgets(
    'R13A-06 already-read valid target navigates without read request and invalid target stays',
    (tester) async {
      final repository = _NotificationRepository()
        ..pages[1] = _page([
          _item(7, targetId: 7, read: true),
          _item(8, targetType: NotificationTargetType.system, targetId: null),
        ]);
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
              AppConfig.fromValues(apiBaseUrl: 'https://api.test'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification_7')));
      await tester.pumpAndSettle();
      expect(find.text('内容 7'), findsOneWidget);
      expect(repository.readCalls, isEmpty);

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification_8')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/messages');
      expect(repository.readCalls, [8]);
    },
  );

  test(
    'R13A-07 successful read actions invalidate unread state while failures do not',
    () async {
      var successInvalidations = 0;
      final successRepository = _NotificationRepository()
        ..pages[1] = _page([_item(1), _item(2)]);
      final successController = NotificationController(
        successRepository,
        onUnreadChanged: () => successInvalidations++,
      );
      await successController.loadInitial();
      await successController.markRead(successController.state.items.first);
      await successController.markAllRead();
      expect(successInvalidations, 2);

      var failedInvalidations = 0;
      final failedRepository = _NotificationRepository()
        ..pages[1] = _page([_item(1)])
        ..readOutcomes[1] = [const NetworkException('单条失败')]
        ..markAllError = const BusinessException('全部失败', code: 50012);
      final failedController = NotificationController(
        failedRepository,
        onUnreadChanged: () => failedInvalidations++,
      );
      await failedController.loadInitial();
      expect(
        await failedController.markRead(failedController.state.items.single),
        isFalse,
      );
      await failedController.markAllRead();
      expect(failedInvalidations, 0);
    },
  );

  testWidgets(
    'R13A-07 Shell badge hides zero, caps large counts and tolerates failure',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/app/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShellPage(navigationShell: shell),
            branches: [
              for (final path in [
                '/app/home',
                '/app/data',
                '/app/messages',
                '/app/profile',
              ])
                StatefulShellBranch(
                  routes: [
                    GoRoute(path: path, builder: (_, _) => const Text('页')),
                  ],
                ),
            ],
          ),
        ],
      );
      for (final count in [0, 3, 120]) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey('badge_scope_$count'),
            overrides: [
              notificationUnreadCountProvider.overrideWithValue(
                AsyncValue.data(count),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Badge), count == 0 ? findsNothing : findsOneWidget);
        if (count == 3) expect(find.text('3'), findsOneWidget);
        if (count == 120) expect(find.text('99+'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      router.dispose();
      final failureRouter = GoRouter(
        initialLocation: '/app/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShellPage(navigationShell: shell),
            branches: [
              for (final path in [
                '/app/home',
                '/app/data',
                '/app/messages',
                '/app/profile',
              ])
                StatefulShellBranch(
                  routes: [
                    GoRoute(path: path, builder: (_, _) => const Text('页')),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(failureRouter.dispose);
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('badge_failure_scope'),
          overrides: [
            notificationUnreadCountProvider.overrideWithValue(
              AsyncValue.error(
                const NetworkException('未读数失败'),
                StackTrace.current,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: failureRouter),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpNotificationAt(WidgetTester tester, int width) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(Size(width.toDouble(), 800));
  final repository = _NotificationRepository()..pages[1] = _page([_item(1)]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(apiBaseUrl: 'https://api.test'),
        ),
      ],
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: const MaterialApp(home: NotificationsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _NotificationRepository implements NotificationRepositoryContract {
  final pages = <int, NotificationPage>{};
  final listCalls = <int>[];
  final readCalls = <int>[];
  final readPending = <int, Completer<bool>>{};
  final readOutcomes = <int, List<Object>>{};
  final listPending = <int, List<Completer<NotificationPage>>>{};
  final listErrors = <int, List<Object>>{};
  Object? nextListError;
  Object? unreadError;
  Completer<int>? markAllPending;
  Object? markAllError;
  int markAllCalls = 0;

  @override
  Future<NotificationPage> list(int page, int size) async {
    listCalls.add(page);
    final pending = listPending[page];
    if (pending != null && pending.isNotEmpty) {
      return pending.removeAt(0).future;
    }
    final errors = listErrors[page];
    if (errors != null && errors.isNotEmpty) throw errors.removeAt(0);
    final error = nextListError;
    nextListError = null;
    if (error != null) throw error;
    return pages[page] ?? _page([]);
  }

  @override
  Future<int> unreadCount() async {
    if (unreadError != null) throw unreadError!;
    return 0;
  }

  @override
  Future<bool> markRead(int id) async {
    readCalls.add(id);
    final pending = readPending[id];
    if (pending != null) return pending.future;
    final outcomes = readOutcomes[id];
    if (outcomes != null && outcomes.isNotEmpty) {
      final outcome = outcomes.removeAt(0);
      if (outcome is bool) return outcome;
      throw outcome;
    }
    return true;
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    if (markAllError != null) throw markAllError!;
    return markAllPending?.future ?? 0;
  }
}

NotificationPage _page(
  List<AppNotification> records, {
  int pageNum = 1,
  int pages = 1,
}) => NotificationPage(
  records: records,
  pageNum: pageNum,
  pages: pages,
  total: records.length,
);

AppNotification _item(
  int id, {
  AppNotificationType type = AppNotificationType.contentLiked,
  int? targetId = 9,
  NotificationTargetType targetType = NotificationTargetType.content,
  NotificationTargetType? secondaryTargetType,
  int? secondaryTargetId,
  bool available = true,
  bool read = false,
}) => AppNotification(
  notificationId: id,
  type: type,
  rawType: type.name,
  targetType: targetType,
  rawTargetType: targetType.name,
  targetId: targetId,
  secondaryTargetType: secondaryTargetType,
  secondaryTargetId: secondaryTargetId,
  title: '通知 $id',
  content: '通知正文',
  read: read,
  targetAvailable: available,
);
