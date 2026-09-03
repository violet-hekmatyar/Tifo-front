import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/pages/public_user_page.dart';
import 'package:tifo/features/user_center/presentation/pages/user_list_page.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';

void main() {
  testWidgets('my likes render real content and navigate', (tester) async {
    final router = GoRouter(
      initialLocation: '/likes',
      routes: [
        GoRoute(
          path: '/likes',
          builder: (_, _) => const UserListPage(
            title: '我的点赞',
            request: UserListRequest(UserListKind.myLikes),
          ),
        ),
        GoRoute(
          path: '/contents/:id',
          builder: (_, state) => Text('内容 ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('真实点赞内容'), findsOneWidget);
    expect(find.textContaining('后端未提供'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('user-like-80')));
    await tester.pumpAndSettle();
    expect(find.text('内容 80'), findsOneWidget);
  });

  testWidgets('followed-by state asks confirmation then becomes mutual', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
          userCenterRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PublicUserPage(userId: 22)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('关注了你'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('public_user_follow')));
    await tester.pumpAndSettle();
    expect(find.text('确认关注'), findsOneWidget);
    expect(repository.followCalls, 0);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(repository.followCalls, 1);
    expect(find.text('互相关注'), findsOneWidget);
  });

  testWidgets('public favorites do not expose a dead remove action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCenterRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: const MaterialApp(
          home: UserListPage(
            title: '用户收藏',
            request: UserListRequest(UserListKind.userFavorites, userId: 22),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('公开收藏'), findsOneWidget);
    expect(find.byTooltip('取消收藏'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });
}

final class _Repository implements UserCenterRepositoryContract {
  int followCalls = 0;
  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) async =>
      const UserPage(
        records: [
          UserLikeItem(
            contentId: 80,
            contentType: 'POST',
            title: '真实点赞内容',
            visible: true,
            likeCount: 3,
            commentCount: 1,
            favoriteCount: 0,
          ),
        ],
        pageNum: 1,
        pages: 1,
        total: 1,
      );
  @override
  Future<UserProfile> profile(int userId) async => const UserProfile(
    userId: 22,
    username: 'user_b',
    nickname: '用户 B',
    followingCount: 1,
    followerCount: 2,
    contentCount: 3,
    likeReceivedCount: 4,
    relationStatus: 'FOLLOWED_BY',
    currentUser: false,
  );
  @override
  Future<UserProfile> follow(int userId, bool follow) async {
    followCalls++;
    return const UserProfile(
      userId: 22,
      username: 'user_b',
      nickname: '用户 B',
      followingCount: 1,
      followerCount: 3,
      contentCount: 3,
      likeReceivedCount: 4,
      relationStatus: 'MUTUAL',
      currentUser: false,
    );
  }

  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) async => const UserPage(
    records: [UserFavoriteItem(contentId: 81, title: '公开收藏')],
    pageNum: 1,
    pages: 1,
    total: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
