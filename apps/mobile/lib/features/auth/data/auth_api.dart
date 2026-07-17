import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';

final class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) => _client.post<AuthUser>(
    '/api/auth/register',
    body: {'username': username, 'phone': phone, 'password': password},
    decode: AuthUser.fromJson,
  );

  Future<AuthSession> login({
    required String username,
    required String password,
  }) => _client.post<AuthSession>(
    '/api/auth/login',
    body: {'username': username, 'password': password},
    decode: AuthSession.fromJson,
  );

  Future<AuthUser> me() =>
      _client.get<AuthUser>('/api/auth/me', decode: AuthUser.fromJson);
}
