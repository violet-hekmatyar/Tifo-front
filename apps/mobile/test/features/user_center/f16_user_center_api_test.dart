import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/user_center/data/user_center_api.dart';

void main() {
  const base = 'https://api.test';
  late DioAdapter adapter;
  late UserCenterApi api;
  setUp(() {
    final dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = UserCenterApi(ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio));
  });

  test(
    'likes avatar and private public lists follow Backend V1 contract',
    () async {
      adapter
        ..onGet(
          '$base/api/app/users/me/likes',
          (server) => server.reply(
            200,
            _result(
              _page({
                'contentId': 80,
                'contentType': 'UNKNOWN_TYPE',
                'title': '真实点赞',
                'visible': true,
                'likeCount': 3,
                'commentCount': 2,
                'favoriteCount': 1,
              }),
            ),
          ),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onPost(
          '$base/api/app/users/me/avatar',
          (server) =>
              server.reply(200, _result({'avatarUrl': '/uploads/avatar.png'})),
          data: {'fileId': 90},
        )
        ..onGet(
          '$base/api/app/users/22/favorites',
          (server) => server.reply(200, {
            'code': 40301,
            'message': '无权限',
            'data': null,
          }),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        );

      final likes = await api.myLikes(1, 10);
      expect(likes.records.single.contentType, 'UNKNOWN_TYPE');
      expect(likes.records.single.visible, isTrue);
      expect(await api.bindAvatar(90), '/uploads/avatar.png');
      await expectLater(
        api.userFavorites(22, 1, 10),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 40301)),
      );
    },
  );
}

Map<String, Object?> _result(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};
Map<String, Object?> _page(Map<String, Object?> item) => {
  'records': [item],
  'total': 1,
  'pageNum': 1,
  'pageSize': 10,
  'pages': 1,
};
