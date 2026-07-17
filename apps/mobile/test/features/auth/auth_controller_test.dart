import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  test('cold start without token becomes unauthenticated', () async {
    final repository = _FakeAuthRepository();
    final controller = AuthController(repository);
    await controller.initialize();
    expect(controller.state.status, AuthStatus.unauthenticated);
  });

  test('cold start with valid token restores ready session', () async {
    final repository = _FakeAuthRepository(
      token: 'stored',
      restoreUser: _readyUser,
    );
    final controller = AuthController(repository);
    await controller.initialize();
    expect(controller.state.status, AuthStatus.authenticatedReady);
  });

  test('40101 and 40102 clear stored token', () async {
    for (final code in [40101, 40102]) {
      final repository = _FakeAuthRepository(
        token: 'stored',
        restoreError: BusinessException('expired', code: code),
      );
      final controller = AuthController(repository);
      await controller.initialize();
      expect(repository.logoutCalls, 1);
      expect(controller.state.status, AuthStatus.unauthenticated);
    }
  });

  test('network and 403 restore failures preserve token', () async {
    for (final error in <AppNetworkException>[
      const NetworkException('offline'),
      const BusinessException('forbidden', code: 40301),
    ]) {
      final repository = _FakeAuthRepository(
        token: 'stored',
        restoreError: error,
      );
      final controller = AuthController(repository);
      await controller.initialize();
      expect(repository.logoutCalls, 0);
      expect(controller.state.status, AuthStatus.failure);
    }
  });

  test('login succeeds and routes by onboarding state', () async {
    final repository = _FakeAuthRepository(loginUser: _needsOnboardingUser);
    final controller = AuthController(repository);
    await controller.initialize();
    expect(
      await controller.login(username: 'user', password: 'secret'),
      isTrue,
    );
    expect(controller.state.status, AuthStatus.authenticatedNeedsOnboarding);
  });

  test('login separates business, lock, and network errors', () async {
    for (final entry in <(AppNetworkException, String)>[
      (
        const BusinessException('bad credentials', code: 40101),
        'bad credentials',
      ),
      (const BusinessException('locked', code: 40103), '登录失败次数过多'),
      (const NetworkException('offline'), '网络连接失败'),
    ]) {
      final repository = _FakeAuthRepository(loginError: entry.$1);
      final controller = AuthController(repository);
      await controller.initialize();
      expect(
        await controller.login(username: 'user', password: 'bad'),
        isFalse,
      );
      expect(controller.state.message, contains(entry.$2));
    }
  });

  test('login prevents duplicate submission', () async {
    final completer = Completer<AuthUser>();
    final repository = _FakeAuthRepository(loginCompleter: completer);
    final controller = AuthController(repository);
    await controller.initialize();
    final first = controller.login(username: 'user', password: 'secret');
    final second = await controller.login(username: 'user', password: 'secret');
    expect(second, isFalse);
    expect(repository.loginCalls, 1);
    completer.complete(_readyUser);
    expect(await first, isTrue);
  });

  test('register success records username and does not authenticate', () async {
    final repository = _FakeAuthRepository();
    final controller = AuthController(repository);
    await controller.initialize();
    expect(
      await controller.register(
        username: 'new_user',
        phone: '13900000000',
        password: 'secret',
      ),
      isTrue,
    );
    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.registeredUsername, 'new_user');
  });

  test('logout clears local session', () async {
    final repository = _FakeAuthRepository(loginUser: _readyUser);
    final controller = AuthController(repository);
    await controller.initialize();
    await controller.login(username: 'user', password: 'secret');
    await controller.logout();
    expect(repository.logoutCalls, 1);
    expect(controller.state.status, AuthStatus.unauthenticated);
  });
}

const _needsOnboardingUser = AuthUser(
  id: 1,
  username: 'user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: false,
);
const _readyUser = AuthUser(
  id: 1,
  username: 'user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

final class _FakeAuthRepository implements AuthRepositoryContract {
  _FakeAuthRepository({
    this.token,
    this.restoreUser,
    this.restoreError,
    this.loginUser,
    this.loginError,
    this.loginCompleter,
  });

  String? token;
  AuthUser? restoreUser;
  AppNetworkException? restoreError;
  AuthUser? loginUser;
  AppNetworkException? loginError;
  Completer<AuthUser>? loginCompleter;
  int logoutCalls = 0;
  int loginCalls = 0;

  @override
  Future<AuthUser> currentUser() async => _readyUser;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    if (loginCompleter != null) return loginCompleter!.future;
    return loginUser ?? _needsOnboardingUser;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    token = null;
  }

  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => _needsOnboardingUser;

  @override
  Future<AuthUser> restore() async {
    if (restoreError != null) throw restoreError!;
    return restoreUser ?? _needsOnboardingUser;
  }

  @override
  Future<String?> storedToken() async => token;
}
