import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/notification/data/notification_repository.dart';
import 'package:tifo/features/notification/domain/app_notification.dart';

void main() {
  testWidgets('messages route opens the real interaction notification page', (
    tester,
  ) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/messages');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            const _EmptyNotificationRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/messages');
    expect(find.text('暂无互动通知'), findsOneWidget);
  });

  testWidgets('my likes route uses the real paged page', (tester) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/users/me/likes');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的点赞'), findsOneWidget);
    expect(find.textContaining('没有“我的点赞”分页查询接口'), findsNothing);
  });
}

final class _EmptyNotificationRepository
    implements NotificationRepositoryContract {
  const _EmptyNotificationRepository();
  @override
  Future<NotificationPage> list(int page, int size) async =>
      const NotificationPage(records: [], pageNum: 1, pages: 0, total: 0);
  @override
  Future<int> unreadCount() async => 0;
  @override
  Future<bool> markRead(int id) async => true;
  @override
  Future<int> markAllRead() async => 0;
}

const _user = AuthUser(
  id: 7,
  username: 'f07_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

final class _ReadyAuthRepository implements AuthRepositoryContract {
  @override
  Future<AuthUser> currentUser() async => _user;
  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => _user;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => _user;
  @override
  Future<AuthUser> restore() async => _user;
  @override
  Future<String?> storedToken() async => 'stored';
}
