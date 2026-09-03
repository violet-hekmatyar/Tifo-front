import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  testWidgets('F07 messages route keeps formal unavailable page', (
    tester,
  ) async {
    final auth = AuthController(_ReadyAuthRepository());
    await auth.initialize();
    final router = createAppRouter(auth)..go('/messages');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/messages');
    expect(find.text('消息能力暂不可用'), findsOneWidget);
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
