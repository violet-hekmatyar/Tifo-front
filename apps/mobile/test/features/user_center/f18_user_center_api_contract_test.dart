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
    'USER-18 UserCenterApi decodes profile, stand, lists, avatar, follow and toggle contracts',
    () async {
      adapter
        ..onGet(
          '$base/api/app/users/me/summary',
          (server) => server.reply(
            200,
            _result({
              'userId': 1,
              'username': 'me',
              'nickname': '真实用户',
              'bio': null,
              'mainTeam': null,
              'stats': {
                'postCount': 12,
                'favoriteCount': 3,
                'commentCount': 4,
                'followingCount': 5,
                'followerCount': 6,
                'teamFollowCount': 7,
                'playerFollowCount': 8,
              },
            }),
          ),
        )
        ..onGet(
          '$base/api/app/users/me/stand',
          (server) => server.reply(
            200,
            _result({
              'followTeams': [
                {'teamId': 40, 'teamName': '球队', 'logoUrl': '/team.png'},
              ],
              'followPlayers': [
                {
                  'playerId': 50,
                  'playerName': '球员',
                  'avatarUrl': '/player.png',
                  'teamName': '球队',
                },
              ],
            }),
          ),
        )
        ..onGet(
          '$base/api/app/users/22/profile',
          (server) => server.reply(
            200,
            _result({
              'userId': 22,
              'username': 'user22',
              'nickname': '公开用户',
              'bio': null,
              'mainTeam': null,
              'followingCount': 2,
              'followerCount': 8,
              'contentCount': 9,
              'likeReceivedCount': 10,
              'relationStatus': 'NONE',
              'currentUser': false,
            }),
          ),
        )
        ..onPut(
          '$base/api/app/users/me/profile',
          (server) => server.reply(200, _result(null)),
          data: {'nickname': '新昵称', 'bio': '新简介'},
        )
        ..onPost(
          '$base/api/app/users/me/avatar',
          (server) =>
              server.reply(200, _result({'avatarUrl': '/uploads/avatar.png'})),
          data: {'fileId': 90},
        )
        ..onPost(
          '$base/api/app/users/22/follow',
          (server) => server.reply(
            200,
            _result({'followerCount': 9, 'relationStatus': 'FOLLOWING'}),
          ),
        )
        ..onPost(
          '$base/api/app/follows/toggle',
          (server) => server.reply(200, _result({'followed': false})),
          data: {'followType': 'TEAM', 'targetId': 40},
        )
        ..onPost(
          '$base/api/app/favorites/toggle',
          (server) => server.reply(200, _result(null)),
          data: {'targetType': 'CONTENT', 'targetId': 8},
        )
        ..onDelete(
          '$base/api/app/comments/9',
          (server) => server.reply(200, _result(null)),
        );

      adapter
        ..onGet(
          '$base/api/app/users/me/contents',
          (server) => server.reply(200, _result(_page(_content()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/me/likes',
          (server) => server.reply(200, _result(_page(_like()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/me/favorites',
          (server) => server.reply(200, _result(_page(_favorite()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/me/comments',
          (server) => server.reply(200, _result(_page(_comment()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/22/contents',
          (server) => server.reply(200, _result(_page(_content()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/22/favorites',
          (server) => server.reply(200, _result(_page(_favorite()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/22/comments',
          (server) => server.reply(200, _result(_page(_comment()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/22/followings',
          (server) => server.reply(200, _result(_page(_user()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/22/followers',
          (server) => server.reply(200, _result(_page(_user()))),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        );

      final summary = await api.summary();
      final stand = await api.stand();
      final profile = await api.profile(22);
      await api.updateProfile(nickname: '新昵称', bio: '新简介');
      expect(summary.bio, isNull);
      expect(summary.playerFollowCount, 8);
      expect(stand.teams.single.id, 40);
      expect(stand.players.single.subtitle, '球队');
      expect(profile.mainTeam, isNull);
      expect(await api.bindAvatar(90), '/uploads/avatar.png');
      expect((await api.follow(22, true)).relationStatus, 'FOLLOWING');
      expect(await api.toggleEntity('TEAM', 40), isFalse);

      final pages = [
        await api.myContents(1, 10),
        await api.myLikes(1, 10),
        await api.myFavorites(1, 10),
        await api.myComments(1, 10),
        await api.userContents(22, 1, 10),
        await api.userFavorites(22, 1, 10),
        await api.userComments(22, 1, 10),
        await api.followings(22, 1, 10),
        await api.followers(22, 1, 10),
      ];
      expect(pages, hasLength(9));
      expect(pages.every((page) => page.records.length == 1), isTrue);
      await api.removeFavorite(8);
      await api.deleteComment(9);
    },
  );

  test(
    'USER-18 API preserves authoritative 40301 and 40401 business codes',
    () async {
      adapter
        ..onGet(
          '$base/api/app/users/22/favorites',
          (server) => server.reply(200, {
            'code': 40301,
            'message': '无权限',
            'data': null,
          }),
          queryParameters: {'pageNum': 1, 'pageSize': 10},
        )
        ..onGet(
          '$base/api/app/users/404/profile',
          (server) => server.reply(200, {
            'code': 40401,
            'message': '用户不存在',
            'data': null,
          }),
        );

      await expectLater(
        api.userFavorites(22, 1, 10),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 40301)),
      );
      await expectLater(
        api.profile(404),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 40401)),
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

Map<String, Object?> _content() => {
  'contentId': 10,
  'contentType': 'POST',
  'title': '真实内容',
  'summary': '摘要',
  'coverUrl': '/cover.png',
  'authorId': 22,
  'authorNickname': '作者',
  'publishTime': '2026-01-01T10:00:00Z',
  'likeCount': 3,
  'commentCount': 2,
  'favoriteCount': 1,
};

Map<String, Object?> _like() => {
  'contentId': 10,
  'contentType': 'POST',
  'title': '真实点赞',
  'visible': true,
  'likedAt': '2026-01-01T10:00:00Z',
  'likeCount': 3,
  'commentCount': 2,
  'favoriteCount': 1,
};

Map<String, Object?> _favorite() => {
  'targetId': 10,
  'title': '真实收藏',
  'favoriteTime': '2026-01-01T10:00:00Z',
};

Map<String, Object?> _comment() => {
  'commentId': 9,
  'targetId': 10,
  'contentText': '真实评论',
  'targetTitle': '真实内容',
  'createTime': '2026-01-01T10:00:00Z',
};

Map<String, Object?> _user() => {
  'userId': 3,
  'username': 'user3',
  'nickname': '用户 3',
  'relationStatus': 'FOLLOWING',
};
