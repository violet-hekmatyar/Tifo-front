import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/user_center/presentation/pages/settings_pages.dart';

void main() {
  testWidgets('SET-01 settings matches the four prototype entries', (
    tester,
  ) async {
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsPage(authController: auth)),
      ),
    );

    expect(find.byKey(const ValueKey('settings_account')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_general')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings_notifications')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings_language')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_logout')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_edit_profile')), findsNothing);
    expect(find.text('账号与安全'), findsOneWidget);
    expect(find.text('通用设置'), findsOneWidget);
    expect(find.text('通知设置'), findsOneWidget);
    expect(find.text('语言设置'), findsOneWidget);
  });

  testWidgets('SET-02 account page renders the masked phone security rows', (
    tester,
  ) async {
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AccountInfoPage(authController: auth)),
      ),
    );

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('+86 185****9583'), findsOneWidget);
    expect(find.byKey(const ValueKey('account_phone')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_password')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_delete')), findsOneWidget);
    expect(find.text('真实昵称'), findsNothing);
    expect(find.text('account_user'), findsNothing);
    expect(find.text('18512349583'), findsNothing);
  });

  testWidgets('SET-09 settings page uses dark icons on a light system bar', (
    tester,
  ) async {
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsPage(authController: auth)),
      ),
    );

    _expectLightPageSystemUi(tester, 'settings_system_ui');
  });

  testWidgets('SET-10 account page uses dark icons on a light system bar', (
    tester,
  ) async {
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AccountInfoPage(authController: auth)),
      ),
    );

    _expectLightPageSystemUi(tester, 'account_system_ui');
  });

  testWidgets(
    'SET-05 unsupported settings actions show an explicit closed state',
    (tester) async {
      final auth = await _readyAuth();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SettingsPage(authController: auth)),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('settings_general')));
      await tester.pump();
      expect(find.text('通用设置暂未开放'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AccountInfoPage(authController: auth)),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('account_password')));
      await tester.pump();
      expect(find.text('修改密码暂未开放'), findsOneWidget);
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
    'R13A-08 settings account entry returns and unsupported entries stay local',
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
          overrides: [],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings_account')));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings_notifications')));
      await tester.pump();
      expect(find.text('通知设置暂未开放'), findsOneWidget);
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
        expect(find.text('+86 185****9583'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('SET-07 settings geometry follows the 375dp prototype rhythm', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    final auth = await _readyAuth();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SettingsPage(authController: auth)),
      ),
    );
    await tester.pumpAndSettle();
    final group = tester.getRect(find.byKey(const ValueKey('settings_group')));
    final logout = tester.getRect(
      find.byKey(const ValueKey('settings_logout')),
    );
    expect(group.left, closeTo(10, 1));
    expect(group.width, closeTo(355, 1));
    expect(group.height, closeTo(200, 1));
    expect(logout.left, closeTo(24, 1));
    expect(logout.width, closeTo(327, 1));
    expect(logout.height, closeTo(54, 1));
    expect(logout.top - group.bottom, closeTo(24, 1));
    expect(find.byKey(const ValueKey('settings_divider_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_divider_2')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_divider_3')), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    for (final index in [1, 2, 3]) {
      final divider = tester.getRect(
        find.byKey(ValueKey('settings_divider_$index')),
      );
      expect(divider.left, closeTo(25, 1));
      expect(divider.right, closeTo(365, 1));
      expect(divider.width, closeTo(340, 1));
    }
    final title = tester.widget<Text>(find.text('设置').first);
    expect(title.style?.fontSize, closeTo(19.5, 1));
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'SET-08 account security geometry stays compact at 360dp and 140%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      final auth = await _readyAuth();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: ProviderScope(
            child: MaterialApp(home: AccountInfoPage(authController: auth)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final group = tester.getRect(
        find.byKey(const ValueKey('account_security_group')),
      );
      expect(group.left, closeTo(10, 1));
      expect(group.width, closeTo(340, 1));
      expect(group.height, closeTo(150, 1));
      expect(find.byKey(const ValueKey('account_divider_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('account_divider_2')), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      for (final index in [1, 2]) {
        final divider = tester.getRect(
          find.byKey(ValueKey('account_divider_$index')),
        );
        expect(divider.left, closeTo(25, 1));
        expect(divider.right, closeTo(350, 1));
        expect(divider.width, closeTo(325, 1));
      }
      final label = tester.getRect(find.text('手机号'));
      final value = tester.getRect(
        find.byKey(const ValueKey('account_phone_value')),
      );
      final arrow = tester.getRect(
        find.byKey(const ValueKey('account_phone_arrow')),
      );
      expect(label.left, closeTo(25, 2));
      expect(value.right, lessThanOrEqualTo(arrow.left));
      expect(arrow.right, closeTo(339, 6));
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}

void _expectLightPageSystemUi(WidgetTester tester, String key) {
  final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
    find.byKey(ValueKey(key)),
  );
  expect(region.value.statusBarColor, isNotNull);
  expect(region.value.statusBarIconBrightness, Brightness.dark);
  expect(region.value.statusBarBrightness, Brightness.light);
  expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
  expect(region.value.systemNavigationBarColor, isNotNull);
  expect(region.value.systemNavigationBarContrastEnforced, isFalse);
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
  phoneMasked: '+86 185****9583',
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
