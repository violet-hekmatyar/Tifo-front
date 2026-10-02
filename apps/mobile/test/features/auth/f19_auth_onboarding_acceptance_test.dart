import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/app/router/auth_redirect.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/auth/presentation/pages/bootstrap_page.dart';
import 'package:tifo/features/auth/presentation/pages/login_page.dart';
import 'package:tifo/features/auth/presentation/pages/register_page.dart';
import 'package:tifo/shared/widgets/app_text_field.dart';

void main() {
  testWidgets(
    'AUTH-01/02 login exposes only username/password and validates before request',
    (tester) async {
      final repository = _AuthRepository();
      final controller = await _controller(repository);
      await _pump(tester, LoginPage(), controller);

      expect(find.byKey(const ValueKey('login_username')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password')), findsOneWidget);
      expect(find.text('手机号'), findsNothing);
      expect(find.text('微信'), findsNothing);
      expect(find.text('游客'), findsNothing);
      expect(find.text('找回密码'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      expect(repository.loginCalls, 0);
      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('login_username')),
        'valid_user',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password')),
        'secret',
      );
      expect(_passwordIsObscured(tester), isTrue);
      await tester.tap(find.byTooltip('显示密码'));
      await tester.pump();
      expect(_passwordIsObscured(tester), isFalse);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repository.loginCalls, 0);
      expect(
        find.byKey(const ValueKey('auth_agreement_accept')),
        findsOneWidget,
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth_agreement_decline')));
      await tester.pumpAndSettle();
      expect(repository.loginCalls, 0);
    },
  );

  testWidgets(
    'AUTH-03 agreement decline does not submit and acceptance submits once',
    (tester) async {
      final repository = _AuthRepository(loginPending: Completer<AuthUser>());
      final controller = await _controller(repository);
      await _pump(tester, const LoginPage(), controller);
      await _fillLogin(tester);

      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      expect(find.text('服务协议及隐私保护'), findsOneWidget);
      expect(repository.loginCalls, 0);
      await tester.tap(find.byKey(const ValueKey('auth_agreement_decline')));
      await tester.pumpAndSettle();
      expect(repository.loginCalls, 0);

      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth_agreement_accept')));
      await tester.pump();
      expect(repository.loginCalls, 1);
      expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
      repository.loginPending!.complete(_readyUser);
      await tester.pumpAndSettle();
      expect(controller.state.status, AuthStatus.authenticatedReady);
    },
  );

  testWidgets(
    'AUTH-05 login failure retains values and shows business feedback',
    (tester) async {
      final repository = _AuthRepository(
        loginError: const BusinessException('账号已锁定', code: 40103),
      );
      final controller = await _controller(repository);
      await _pump(tester, const LoginPage(), controller);
      await _fillLogin(tester);
      await tester.tap(find.byKey(const ValueKey('auth_agreement_checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('登录失败次数过多'), findsOneWidget);
      expect(
        tester
            .widget<AppTextField>(find.byKey(const ValueKey('login_username')))
            .controller
            .text,
        'valid_user',
      );
      expect(
        tester
            .widget<AppTextField>(find.byKey(const ValueKey('login_password')))
            .controller
            .text,
        'secret',
      );
      expect(controller.state.status, AuthStatus.unauthenticated);
    },
  );

  testWidgets(
    'AUTH-04/11 login routes by onboarding state and protects routes',
    (tester) async {
      for (final entry in <(AuthUser, String)>[
        (_needsOnboardingUser, '/onboarding'),
        (_readyUser, '/app/home'),
      ]) {
        final controller = await _controller(
          _AuthRepository(loginUser: entry.$1),
        );
        final router = GoRouter(
          initialLocation: '/login',
          refreshListenable: controller,
          redirect: (_, state) =>
              authRedirect(controller.state.status, state.matchedLocation),
          routes: [
            GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
            GoRoute(path: '/onboarding', builder: (_, _) => const Text('首次引导')),
            GoRoute(path: '/app/home', builder: (_, _) => const Text('首页')),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey('auth_route_${entry.$2}'),
            overrides: [authControllerProvider.overrideWith((_) => controller)],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _fillLogin(tester);
        await tester.tap(find.byKey(const ValueKey('auth_agreement_checkbox')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('login_submit')));
        await tester.pumpAndSettle();
        expect(
          find.text(entry.$2 == '/onboarding' ? '首次引导' : '首页'),
          findsOneWidget,
        );
        router.dispose();
      }
    },
  );

  testWidgets(
    'AUTH-06/07/08 register validates, preserves phone contract and pre-fills login',
    (tester) async {
      final repository = _AuthRepository();
      final controller = await _controller(repository);
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
          GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((_) => controller)],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('register_submit')));
      await tester.pumpAndSettle();
      expect(repository.registerCalls, 0);

      await tester.enterText(
        find.byKey(const ValueKey('register_username')),
        'new_user',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_phone')),
        '13900000000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_password')),
        'secret',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_confirmation')),
        'different',
      );
      await tester.tap(find.byKey(const ValueKey('register_submit')));
      await tester.pumpAndSettle();
      expect(repository.registerCalls, 0);
      expect(find.text('两次输入的密码不一致'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('register_confirmation')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey('auth_agreement_checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('register_submit')));
      await tester.pumpAndSettle();
      expect(repository.registerCalls, 1);
      expect(repository.lastPhone, '13900000000');
      expect(find.byKey(const ValueKey('login_username')), findsOneWidget);
      expect(
        tester
            .widget<AppTextField>(find.byKey(const ValueKey('login_username')))
            .controller
            .text,
        'new_user',
      );
      expect(find.byKey(const ValueKey('login_password')), findsOneWidget);
      expect(
        tester
            .widget<AppTextField>(find.byKey(const ValueKey('login_password')))
            .controller
            .text,
        isEmpty,
      );
      expect(find.byKey(const ValueKey('register_phone')), findsNothing);
    },
  );

  testWidgets(
    'AUTH-09/10 bootstrap failure retries and stale restore cannot win',
    (tester) async {
      final restore = Completer<AuthUser>();
      final repository = _AuthRepository(
        token: 'stored',
        restorePending: restore,
      );
      final controller = AuthController(repository);
      final initialize = controller.initialize();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((_) => controller)],
          child: const MaterialApp(home: BootstrapPage()),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('bootstrap_loading_message')),
        findsOneWidget,
      );

      restore.completeError(const NetworkException('网络暂不可用'));
      await initialize;
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('bootstrap_failure_message')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bootstrap_retry')), findsOneWidget);
      repository.restoreError = null;
      repository.restorePending = null;
      repository.restoreUser = _readyUser;
      await tester.tap(find.byKey(const ValueKey('bootstrap_retry')));
      await tester.pump();
      expect(controller.state.status, AuthStatus.authenticatedReady);
    },
  );

  testWidgets('AUTH-12 auth surfaces fit 360/412px with large text', (
    tester,
  ) async {
    final controller = await _controller(_AuthRepository());
    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: ProviderScope(
            overrides: [authControllerProvider.overrideWith((_) => controller)],
            child: const MaterialApp(home: LoginPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  test(
    'AUTH-10 inverse bootstrap restores keep the newest generation',
    () async {
      final old = Completer<AuthUser>();
      final newest = Completer<AuthUser>();
      final repository = _AuthRepository(
        token: 'stored',
        restorePendings: [old, newest],
      );
      final controller = AuthController(repository);
      final first = controller.initialize();
      await Future<void>.delayed(Duration.zero);
      final retry = controller.retryBootstrap();
      newest.complete(_readyUser);
      await retry;
      old.completeError(const NetworkException('旧请求失败'));
      await first;
      expect(controller.state.status, AuthStatus.authenticatedReady);
    },
  );
}

Future<AuthController> _controller(_AuthRepository repository) async {
  final controller = AuthController(repository);
  await controller.initialize();
  return controller;
}

Future<void> _pump(
  WidgetTester tester,
  Widget page,
  AuthController controller,
) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((_) => controller)],
      child: MaterialApp(theme: AppTheme.light, home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('login_username')),
    'valid_user',
  );
  await tester.enterText(
    find.byKey(const ValueKey('login_password')),
    'secret',
  );
}

bool _passwordIsObscured(WidgetTester tester) => tester
    .widget<AppTextField>(find.byKey(const ValueKey('login_password')))
    .obscureText;

const _readyUser = AuthUser(
  id: 1,
  username: 'valid_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

const _needsOnboardingUser = AuthUser(
  id: 1,
  username: 'valid_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: false,
);

final class _AuthRepository implements AuthRepositoryContract {
  _AuthRepository({
    this.token,
    this.restorePending,
    this.restorePendings = const [],
    this.loginError,
    this.loginPending,
    this.loginUser,
  });

  String? token;
  AuthUser? restoreUser;
  AppNetworkException? restoreError;
  Completer<AuthUser>? restorePending;
  final List<Completer<AuthUser>> restorePendings;
  AppNetworkException? loginError;
  Completer<AuthUser>? loginPending;
  AuthUser? loginUser;
  int loginCalls = 0;
  int registerCalls = 0;
  String? lastPhone;
  AppNetworkException? registerError;

  @override
  Future<AuthUser> currentUser() async => _readyUser;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    if (loginPending != null) return loginPending!.future;
    return loginUser ?? _readyUser;
  }

  @override
  Future<void> logout() async => token = null;

  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    registerCalls++;
    lastPhone = phone;
    if (registerError != null) throw registerError!;
    return _readyUser;
  }

  @override
  Future<AuthUser> restore() async {
    if (restoreError != null) throw restoreError!;
    if (restorePendings.isNotEmpty) return restorePendings.removeAt(0).future;
    if (restorePending != null) return restorePending!.future;
    return restoreUser ?? _readyUser;
  }

  @override
  Future<String?> storedToken() async => token;
}
