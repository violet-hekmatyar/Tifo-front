import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/interaction/data/interaction_api.dart';
import 'package:tifo/features/user_center/data/user_center_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real likes avatar mutual follow and private list boundaries',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final client = ApiClient(config, dio);
      final auth = AuthRepository(AuthApi(client), storage);
      final users = UserCenterApi(client);
      final interactions = InteractionApi(client);
      final files = FileUploadRepository(client, config: config);
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final tail = suffix.substring(suffix.length - 12);
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      final aName = 'f16a_$tail';
      final bName = 'f16b_$tail';
      final a = await auth.register(
        username: aName,
        phone: '136${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      final b = await auth.register(
        username: bName,
        phone: '135${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      final dir = await Directory.systemTemp.createTemp('f16-avatar');
      final image = File('${dir.path}/avatar.png');
      await image.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      var liked = false;
      var aFollowsB = false;
      var bFollowsA = false;
      try {
        await auth.login(username: aName, password: password);
        liked = (await interactions.toggleLike(20005)).active;
        expect(liked, isTrue);
        expect((await users.myLikes(1, 20)).records, isNotEmpty);

        final uploaded = await files.uploadAvatar(image.path, 'avatar.png');
        final avatarUrl = await users.bindAvatar(uploaded.fileId);
        expect(avatarUrl, isNotEmpty);
        expect((await users.summary()).avatarUrl, avatarUrl);

        expect((await users.profile(b.id)).relationStatus, 'NONE');
        expect((await users.follow(b.id, true)).relationStatus, 'FOLLOWING');
        aFollowsB = true;

        await auth.login(username: bName, password: password);
        expect((await users.profile(a.id)).relationStatus, 'FOLLOWED_BY');
        expect((await users.follow(a.id, true)).relationStatus, 'MUTUAL');
        bFollowsA = true;
        await expectLater(
          users.userFavorites(a.id, 1, 10),
          throwsA(
            isA<BusinessException>().having((e) => e.code, 'code', 40301),
          ),
        );
        await expectLater(
          users.userComments(a.id, 1, 10),
          throwsA(
            isA<BusinessException>().having((e) => e.code, 'code', 40301),
          ),
        );

        await auth.login(username: aName, password: password);
        expect((await users.profile(b.id)).relationStatus, 'MUTUAL');
      } finally {
        try {
          await auth.login(username: aName, password: password);
          if (aFollowsB) await users.follow(b.id, false);
          if (liked) await interactions.toggleLike(20005);
          await auth.login(username: bName, password: password);
          if (bFollowsA) await users.follow(a.id, false);
        } finally {
          if (await dir.exists()) await dir.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
