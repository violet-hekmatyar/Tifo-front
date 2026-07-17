import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_user.dart';

enum AuthStatus {
  bootstrapping,
  unauthenticated,
  authenticatedNeedsOnboarding,
  authenticatedReady,
  failure,
}

final class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.message,
    this.traceId,
    this.isSubmitting = false,
    this.registeredUsername,
  });

  const AuthState.bootstrapping() : this(status: AuthStatus.bootstrapping);

  final AuthStatus status;
  final AuthUser? user;
  final String? message;
  final String? traceId;
  final bool isSubmitting;
  final String? registeredUsername;
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepositoryContract _repository;
  AuthState _state = const AuthState.bootstrapping();
  bool _initialized = false;

  AuthState get state => _state;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await retryBootstrap();
  }

  Future<void> retryBootstrap() async {
    _setState(const AuthState.bootstrapping());
    final token = await _repository.storedToken();
    if (token == null || token.trim().isEmpty) {
      _setState(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      _setAuthenticated(await _repository.restore());
    } on BusinessException catch (error) {
      if (error.code == 40101 || error.code == 40102) {
        await _repository.logout();
        _setState(const AuthState(status: AuthStatus.unauthenticated));
      } else {
        _setFailure(error);
      }
    } on AppNetworkException catch (error) {
      _setFailure(error);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_state.isSubmitting) return false;
    _setState(
      AuthState(
        status: AuthStatus.unauthenticated,
        isSubmitting: true,
        registeredUsername: _state.registeredUsername,
      ),
    );
    try {
      _setAuthenticated(
        await _repository.login(username: username.trim(), password: password),
      );
      return true;
    } on AppNetworkException catch (error) {
      _setState(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: _messageFor(error),
          traceId: _traceIdFor(error),
          registeredUsername: _state.registeredUsername,
        ),
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    if (_state.isSubmitting) return false;
    _setState(
      const AuthState(status: AuthStatus.unauthenticated, isSubmitting: true),
    );
    try {
      await _repository.register(
        username: username.trim(),
        phone: phone.trim(),
        password: password,
      );
      _setState(
        AuthState(
          status: AuthStatus.unauthenticated,
          registeredUsername: username.trim(),
        ),
      );
      return true;
    } on AppNetworkException catch (error) {
      _setState(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: _messageFor(error),
          traceId: _traceIdFor(error),
        ),
      );
      return false;
    }
  }

  Future<void> refreshAfterOnboarding() async {
    _setAuthenticated(await _repository.currentUser());
  }

  Future<void> logout() async {
    await _repository.logout();
    _setState(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _setAuthenticated(AuthUser user) {
    _setState(
      AuthState(
        status: user.onboardingCompleted
            ? AuthStatus.authenticatedReady
            : AuthStatus.authenticatedNeedsOnboarding,
        user: user,
      ),
    );
  }

  void _setFailure(AppNetworkException error) {
    _setState(
      AuthState(
        status: AuthStatus.failure,
        message: _messageFor(error),
        traceId: _traceIdFor(error),
      ),
    );
  }

  String _messageFor(AppNetworkException error) => switch (error) {
    NetworkException() => '网络连接失败，请检查后重试。',
    TimeoutException() => '请求超时，请稍后重试。',
    BusinessException(code: 40103) => '登录失败次数过多，请稍后再试。',
    BusinessException() => error.message,
    HttpException(statusCode: 403) => '当前账号无权访问。',
    _ => '请求失败，请稍后重试。',
  };

  String? _traceIdFor(AppNetworkException error) => switch (error) {
    BusinessException() => error.traceId,
    HttpException() => error.traceId,
    _ => null,
  };

  void _setState(AuthState value) {
    _state = value;
    notifyListeners();
  }
}
