import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/presentation/pages/user_list_page.dart';
import 'package:tifo/features/user_center/presentation/pages/user_relations_page.dart';
import 'package:tifo/features/user_center/presentation/widgets/profile_hero.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/shared/widgets/app_entity_avatar.dart';

void main() {
  test('VR9 stand counters remain nullable-safe and typed', () {
    const stand = UserStand(
      teams: [],
      players: [],
      followingUserCount: 10,
      followerCount: 10,
      contentCount: 2,
      likeReceivedCount: 8,
    );

    expect(stand.followingUserCount, 10);
    expect(stand.followerCount, 10);
    expect(stand.contentCount, 2);
    expect(stand.likeReceivedCount, 8);
  });

  testWidgets('VR9 profile hero keeps action row and bounded header geometry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UserProfileHero(
              key: ValueKey('vr9_profile_hero'),
              userId: 10002,
              nickname: 'Demo Fan',
              username: 'test_user',
              avatarUrl: null,
              bio: '足球是生活的热爱',
              mainTeam: EntityBrief(id: 12, name: '主队'),
              contentCount: 2,
              followingCount: 10,
              followerCount: 10,
              likeReceivedCount: 8,
              actions: [
                ProfileHeroAction(
                  label: '编辑资料',
                  icon: Icons.edit_outlined,
                  onPressed: null,
                ),
                ProfileHeroAction(
                  label: '我的关注',
                  icon: Icons.favorite_border,
                  onPressed: null,
                ),
                ProfileHeroAction(
                  label: '我的粉丝',
                  icon: Icons.people_outline,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final hero = tester.getSize(find.byKey(const ValueKey('vr9_profile_hero')));
    expect(hero.height, inInclusiveRange(260, 430));
    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(find.text('Demo Fan'), findsOneWidget);
    expect(find.text('10'), findsNWidgets(2));
    expect(find.text('发布'), findsNothing);
    expect(find.byKey(const ValueKey('my_profile_refresh')), findsNothing);
    expect(find.text('@test_user'), findsNothing);

    final avatar = tester.getRect(
      find.byKey(const ValueKey('profile_hero_avatar')),
    );
    final nickname = tester.getRect(find.text('Demo Fan'));
    final stats = tester.getRect(
      find.byKey(const ValueKey('profile_hero_stats')),
    );
    expect(stats.left, greaterThanOrEqualTo(avatar.right));
    expect(stats.top, greaterThan(nickname.bottom));
    expect(stats.left, greaterThan(avatar.left + 60));
    expect(hero.height, inInclusiveRange(260, 300));
  });

  testWidgets('VR9-R1 user center uses image fallback for normal avatars', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEntityAvatar(
            identity: 'user:10002',
            semanticLabel: '用户头像',
            fallbackIcon: Icons.person_outline_rounded,
            fallbackText: 'D',
            fallbackAsset: 'assets/ui/profile/user-demo.png',
            size: 48,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
  });

  testWidgets('VR9-R1 six content records keep a continuous grid', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(
            _R1UserCenterRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UserListView(
              request: UserListRequest(UserListKind.myContents),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ContentCard), findsAtLeastNWidgets(4));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('已经到底了'), findsOneWidget);
    expect(find.text('帖子'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR9-R2 full relations page uses compact controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(
            _R1UserCenterRepository(),
          ),
        ],
        child: const MaterialApp(home: UserRelationsPage(userId: 10002)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('relations_following')), findsOneWidget);
    final search = tester.getSize(
      find.byKey(const ValueKey('user_list_search')),
    );
    expect(search.height, inInclusiveRange(38, 42));
    final first = tester.getRect(find.byKey(const ValueKey('user-row-1')));
    final second = tester.getRect(find.byKey(const ValueKey('user-row-2')));
    expect(second.top - first.top, inInclusiveRange(58, 70));
    final followButton = tester.getSize(
      find.byKey(const ValueKey('user-follow-1')),
    );
    expect(followButton.width, lessThanOrEqualTo(78));
    expect(followButton.height, lessThanOrEqualTo(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR9-R1 relation rows use compact vertical rhythm', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(
            _R1UserCenterRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UserListView(
              request: UserListRequest(UserListKind.followings, userId: 10002),
              showSearch: true,
              searchHint: '搜索已关注的人',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final search = find.byKey(const ValueKey('user_list_search'));
    expect(tester.getSize(search).height, inInclusiveRange(40, 50));
    final first = tester.getRect(find.byKey(const ValueKey('user-row-1')));
    final second = tester.getRect(find.byKey(const ValueKey('user-row-2')));
    expect(second.top - first.top, inInclusiveRange(58, 72));
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR9 relation search uses compact pill geometry at 360dp', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);

    final request = const UserListRequest(
      UserListKind.followings,
      userId: 10002,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(
            _EmptyUserCenterRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UserListView(
              request: request,
              showSearch: true,
              searchHint: '搜索已关注的人',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final search = tester.widget<TextField>(
      find.byKey(const ValueKey('user_list_search')),
    );
    final searchSize = tester.getSize(
      find.byKey(const ValueKey('user_list_search')),
    );
    expect(search.decoration?.hintText, '搜索已关注的人');
    expect(searchSize.width, greaterThan(300));
    expect(searchSize.height, lessThan(70));
    expect(tester.takeException(), isNull);
  });
}

final class _R1UserCenterRepository extends _EmptyUserCenterRepository {
  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) async =>
      UserPage(
        records: [
          for (var i = 1; i <= 6; i++)
            UserContentItem(
              contentId: i,
              contentType: 'POST',
              title: 'R1 内容 $i',
              summary: '真实内容摘要',
              coverUrl: '/demo/p1-media/cover-stadium.png',
              likeCount: i,
              commentCount: 1,
              favoriteCount: 0,
            ),
        ],
        pageNum: page,
        pages: 1,
        total: 6,
      );

  @override
  Future<UserPage<UserBrief>> followings(
    int userId,
    int page,
    int size,
  ) async => UserPage(
    records: [
      for (var i = 1; i <= 8; i++)
        UserBrief(
          userId: i,
          username: 'r1_user_$i',
          nickname: 'R1 用户 $i',
          relationStatus: i.isEven ? 'FOLLOWING' : 'MUTUAL',
        ),
    ],
    pageNum: page,
    pages: 1,
    total: 8,
  );
}

final class _EmptyUserCenterRepository implements UserCenterRepositoryContract {
  @override
  Future<MySummary> summary() => throw UnimplementedError();

  @override
  Future<UserStand> stand() => throw UnimplementedError();

  @override
  Future<UserProfile> profile(int userId) => throw UnimplementedError();

  @override
  Future<void> updateProfile({required String nickname, required String bio}) =>
      throw UnimplementedError();

  @override
  Future<void> setMainTeam(int teamId) => throw UnimplementedError();

  @override
  Future<UserProfile> follow(int userId, bool follow) =>
      throw UnimplementedError();

  @override
  Future<bool> toggleEntity(String type, int id) => throw UnimplementedError();

  @override
  Future<void> removeFavorite(int contentId) => throw UnimplementedError();

  @override
  Future<void> deleteComment(int commentId) => throw UnimplementedError();

  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<UserPage<UserCommentItem>> userComments(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<String> bindAvatar(int fileId) => throw UnimplementedError();

  @override
  Future<UserPage<UserBrief>> followings(
    int userId,
    int page,
    int size,
  ) async => const UserPage(records: [], pageNum: 1, pages: 1, total: 0);

  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) async =>
      const UserPage(records: [], pageNum: 1, pages: 1, total: 0);
}
