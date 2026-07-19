import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/content/data/content_api.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/interaction/data/interaction_api.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/user_center/data/user_center_api.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real F07 user center follow and feed linkage',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true.');
        return;
      }
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final a = _TestAccount(baseUrl);
      final b = _TestAccount(baseUrl);
      final userA = await a.create('f07a', suffix);
      final userB = await b.create('f07b', suffix);

      expect((await b.users.profile(userB)).currentUser, isTrue);
      final first = await b.content.createPost(
        title: 'F07 my posts $suffix',
        body: 'F07 dedicated current-user content query.',
        mediaFileIds: const [],
      );
      final myPosts = await b.users.myContents(1, 20);
      expect(
        myPosts.records.map((item) => item.contentId),
        contains(first.contentId),
      );

      final before = await a.users.profile(userB);
      if (before.followed) await a.users.follow(userB, false);
      expect((await a.users.profile(userB)).followed, isFalse);

      final followed = await a.users.follow(userB, true);
      expect(followed.followed, isTrue);
      final followings = await a.users.followings(userA, 1, 20);
      expect(followings.records.map((item) => item.userId), contains(userB));
      final followers = await b.users.followers(userB, 1, 20);
      expect(followers.records.map((item) => item.userId), contains(userA));

      final second = await b.content.createPost(
        title: 'F07 following feed $suffix',
        body: 'F07 real followed-author feed linkage.',
        mediaFileIds: const [],
      );
      int? foundPage;
      for (var page = 1; page <= 20; page++) {
        final result = await a.feed.loadFeed(
          filter: FeedFilter.following,
          pageNum: page,
          pageSize: 10,
        );
        if (result.cards.whereType<ContentFeedCard>().any(
          (item) => item.contentId == second.contentId,
        )) {
          foundPage = page;
          break;
        }
        if (!result.hasMore) break;
      }
      expect(
        foundPage,
        isNotNull,
        reason: 'followed user post must be present in following Feed',
      );

      expect(
        (await a.interaction.toggleFavorite(second.contentId)).active,
        isTrue,
      );
      final favorites = await a.users.myFavorites(1, 20);
      expect(
        favorites.records.map((item) => item.contentId),
        contains(second.contentId),
      );
      final commentId = await a.interaction.createComment(
        contentId: second.contentId,
        content: 'F07 comment $suffix',
      );
      final comments = await a.users.myComments(1, 20);
      expect(
        comments.records.map((item) => item.commentId),
        contains(commentId),
      );
      await a.interaction.deleteComment(commentId);
      await a.interaction.toggleFavorite(second.contentId);

      await a.users.follow(userB, false);
      expect((await a.users.profile(userB)).followed, isFalse);
      final afterFollowings = await a.users.followings(userA, 1, 20);
      expect(
        afterFollowings.records.map((item) => item.userId),
        isNot(contains(userB)),
      );

      // IDs and the page number are safe diagnostics; credentials and tokens are never printed.
      // ignore: avoid_print
      print(
        'F07 linkage myPost=${first.contentId} followedPost=${second.contentId} followingPage=$foundPage messages=unsupported',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class _TestAccount {
  _TestAccount(String baseUrl) {
    final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
    final dio = Dio();
    dio.interceptors.add(
      buildRequestHeadersInterceptor(() async {
        final token = await storage.readAccessToken();
        return token == null ? const {} : {'Authorization': 'Bearer $token'};
      }),
    );
    final client = ApiClient(config, dio);
    auth = AuthRepository(AuthApi(client), storage);
    content = ContentRepository(ContentApi(client));
    feed = FeedRepository(FeedApi(client));
    interaction = InteractionRepository(InteractionApi(client));
    users = UserCenterRepository(UserCenterApi(client));
  }
  final InMemoryTokenStorage storage = InMemoryTokenStorage();
  late final AuthRepository auth;
  late final ContentRepository content;
  late final FeedRepository feed;
  late final InteractionRepository interaction;
  late final UserCenterRepository users;

  Future<int> create(String prefix, String suffix) async {
    final tail = suffix.substring(suffix.length - 10);
    final username = '${prefix}_$tail';
    final password = 'T!${suffix.substring(suffix.length - 9)}z';
    await auth.register(
      username: username,
      phone:
          '13${prefix == 'f07a' ? '6' : '7'}${suffix.substring(suffix.length - 8)}',
      password: password,
    );
    return (await auth.login(username: username, password: password)).id;
  }
}
