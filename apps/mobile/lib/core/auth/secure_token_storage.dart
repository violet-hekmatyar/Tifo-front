import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

final class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: TokenStorageKeys.accessToken);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: TokenStorageKeys.accessToken, value: token);

  @override
  Future<void> deleteAccessToken() =>
      _storage.delete(key: TokenStorageKeys.accessToken);
}
