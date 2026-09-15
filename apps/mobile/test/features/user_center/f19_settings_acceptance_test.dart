import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/user_center/presentation/pages/settings_pages.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';

void main() {
  testWidgets('SET-01 settings has exactly four real entries', (tester) async {
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsPage(authController: auth)),
      ),
    );

    expect(find.byKey(const ValueKey('settings_account')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_edit_profile')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_notifications')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings_logout')), findsOneWidget);
    expect(find.text('私信'), findsNothing);
    expect(find.text('手机号'), findsNothing);
    expect(find.text('修改密码'), findsNothing);
    expect(find.text('注销账号'), findsNothing);
  });

  testWidgets(
    'SET-02 account page renders AuthUser fields without fake sensitive fields',
    (tester) async {
      final auth = await _readyAuth();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AccountInfoPage(authController: auth)),
        ),
      );

      expect(find.text('真实昵称'), findsNWidgets(2));
      expect(find.text('account_user'), findsOneWidget);
      expect(find.text('MODERATOR'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('手机号'), findsNothing);
      expect(find.text('修改密码'), findsNothing);
      expect(find.text('注销账号'), findsNothing);
    },
  );

  testWidgets(
    'SET-04 logout cancel makes zero calls and failure stays on settings',
    (tester) async {
      final repository = _AuthRepository(logoutError: true);
      final auth = await _readyAuth(repository);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SettingsPage(authController: auth)),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('settings_logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_logout_cancel')));
      await tester.pumpAndSettle();
      expect(repository.logoutCalls, 0);

      await tester.tap(find.byKey(const ValueKey('settings_logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_logout_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_feedback')), findsOneWidget);
      expect(auth.state.status, AuthStatus.authenticatedReady);
    },
  );

  testWidgets('SET-03 successful logout uses existing auth redirect to login', (
    tester,
  ) async {
    final auth = await _readyAuth();
    final router = createAppRouter(auth)..go('/settings');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_logout_confirm')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets(
    'R13A-08 settings account, edit and notification entries return correctly',
    (tester) async {
      final auth = await _readyAuth();
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => SettingsPage(authController: auth),
          ),
          GoRoute(
            path: '/settings/account',
            builder: (_, _) => AccountInfoPage(authController: auth),
          ),
          GoRoute(
            path: '/settings/notifications',
            builder: (_, _) => const Scaffold(body: Text('消息设置')),
          ),
          GoRoute(
            path: '/users/me/edit',
            builder: (_, _) => const Scaffold(body: Text('编辑资料页')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mySummaryProvider.overrideWithValue(
              const AsyncValue.data(
                MySummary(
                  userId: 77,
                  username: 'account_user',
                  nickname: '真实昵称',
                  postCount: 1,
                  favoriteCount: 2,
                  commentCount: 3,
                  followingCount: 4,
                  followerCount: 5,
                  teamFollowCount: 6,
                  playerFollowCount: 7,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings_account')));
      await tester.pumpAndSettle();
      expect(find.text('账号与安全'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings_edit_profile')));
      await tester.pumpAndSettle();
      expect(find.text('编辑资料页'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings_notifications')));
      await tester.pumpAndSettle();
      expect(find.text('消息设置'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings_logout')), findsOneWidget);
    },
  );

  testWidgets(
    'R13A-08 logout double tap calls once and failure keeps settings visible',
    (tester) async {
      final repository = _AuthRepository(
        logoutPending: Completer<void>(),
        logoutError: true,
      );
      final auth = await _readyAuth(repository);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SettingsPage(authController: auth)),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('settings_logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_logout_confirm')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('settings_logout')));
      await tester.pump();
      expect(repository.logoutCalls, 1);

      repository.logoutPending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_feedback')), findsOneWidget);
      expect(auth.state.status, AuthStatus.authenticatedReady);
    },
  );

  testWidgets(
    'SET-06 settings and account pages fit narrow large-text surfaces',
    (tester) async {
      final auth = await _readyAuth();
      for (final width in [360.0, 412.0]) {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: ProviderScope(
              child: MaterialApp(home: SettingsPage(authController: auth)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('settings_account')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: ProviderScope(
              child: MaterialApp(home: AccountInfoPage(authController: auth)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('account_user'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}

Future<AuthController> _readyAuth([_AuthRepository? repository]) async {
  final auth = AuthController(repository ?? _AuthRepository());
  await auth.initialize();
  return auth;
}

const _user = AuthUser(
  id: 77,
  username: 'account_user',
  nickname: '真实昵称',
  avatarUrl: '/avatar.png',
  roleType: 'MODERATOR',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

final class _AuthRepository implements AuthRepositoryContract {
  _AuthRepository({this.logoutError = false, this.logoutPending});
  final bool logoutError;
  final Completer<void>? logoutPending;
  int logoutCalls = 0;

  @override
  Future<AuthUser> currentUser() async => _user;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => _user;

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutPending != null) await logoutPending!.future;
    if (logoutError) {
      throw const BusinessException('退出失败', code: 50004);
    }
  }

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
