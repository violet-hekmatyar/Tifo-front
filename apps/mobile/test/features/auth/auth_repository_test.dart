import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';

void main() {
  test('login saves token before validating /me', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final storage = InMemoryTokenStorage();
    final repository = AuthRepository(
      AuthApi(
        ApiClient(AppConfig.fromValues(apiBaseUrl: 'https://api.test'), dio),
      ),
      storage,
    );
    adapter
      ..onPost(
        'https://api.test/api/auth/login',
        (server) => server.reply(
          200,
          _envelope({
            'accessToken': 'test-access-token',
            'tokenType': 'Bearer',
            'expiresIn': 600,
            'user': _user(false),
          }),
        ),
        data: {'username': 'user', 'password': 'secret'},
      )
      ..onGet(
        'https://api.test/api/auth/me',
        (server) => server.replyCallback(200, (options) {
          expect(storage.readAccessToken(), completion('test-access-token'));
          return _envelope(_user(false));
        }),
      );

    final user = await repository.login(username: 'user', password: 'secret');
    expect(user.username, 'user');
    expect(await storage.readAccessToken(), 'test-access-token');
  });
}

Map<String, Object?> _envelope(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
  'traceId': 'test-trace',
};

Map<String, Object?> _user(bool completed) => {
  'id': 1,
  'username': 'user',
  'nickname': 'User',
  'avatarUrl': null,
  'roleType': 'USER',
  'status': 'ACTIVE',
  'onboardingCompleted': completed,
  'mainTeamId': null,
};
