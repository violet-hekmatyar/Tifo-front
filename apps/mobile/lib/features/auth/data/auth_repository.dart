import '../../../core/auth/token_storage.dart';
import '../../../core/network/network_exceptions.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

abstract interface class AuthRepositoryContract {
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  });

  Future<AuthUser> login({required String username, required String password});

  Future<AuthUser> restore();

  Future<AuthUser> currentUser();

  Future<String?> storedToken();

  Future<void> logout();
}

final class AuthRepository implements AuthRepositoryContract {
  const AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final TokenStorage _storage;

  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) => _api.register(username: username, phone: phone, password: password);

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final session = await _api.login(username: username, password: password);
    await _storage.writeAccessToken(session.accessToken);
    try {
      return await _api.me();
    } on BusinessException catch (error) {
      if (error.code == 40101 || error.code == 40102) {
        await _storage.deleteAccessToken();
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> restore() => _api.me();

  @override
  Future<AuthUser> currentUser() => _api.me();

  @override
  Future<String?> storedToken() => _storage.readAccessToken();

  @override
  Future<void> logout() => _storage.deleteAccessToken();
}
