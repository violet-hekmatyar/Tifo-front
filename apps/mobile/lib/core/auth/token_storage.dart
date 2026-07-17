abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<void> deleteAccessToken();
}

abstract final class TokenStorageKeys {
  static const accessToken = 'south_stand_access_token';
}

final class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> writeAccessToken(String token) async => _token = token;

  @override
  Future<void> deleteAccessToken() async => _token = null;
}
