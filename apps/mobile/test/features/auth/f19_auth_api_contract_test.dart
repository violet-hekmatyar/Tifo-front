import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/auth/data/auth_api.dart';

void main() {
  test(
    'AUTH-08 register sends the existing username/phone/password contract',
    () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = AuthApi(
        ApiClient(AppConfig.fromValues(apiBaseUrl: 'https://api.test'), dio),
      );
      adapter.onPost(
        'https://api.test/api/auth/register',
        (server) => server.reply(200, _envelope(_user)),
        data: {
          'username': 'new_user',
          'phone': '13900000000',
          'password': 'secret',
        },
      );

      final result = await api.register(
        username: 'new_user',
        phone: '13900000000',
        password: 'secret',
      );
      expect(result.username, 'new_user');
    },
  );
}

const _user = {
  'id': 1,
  'username': 'new_user',
  'nickname': null,
  'avatarUrl': null,
  'roleType': 'USER',
  'status': 'ACTIVE',
  'onboardingCompleted': false,
  'mainTeamId': null,
};

Map<String, Object?> _envelope(Object data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
