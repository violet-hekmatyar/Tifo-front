import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/bootstrap_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/feed/presentation/pages/home_feed_page.dart';
import '../../features/football/presentation/pages/football_data_page.dart';
import '../../features/football/presentation/pages/match_detail_page.dart';
import '../../features/football/presentation/pages/player_detail_page.dart';
import '../../features/football/presentation/pages/team_detail_page.dart';
import '../../features/content/presentation/pages/content_detail_page.dart';
import '../../features/content/presentation/pages/article_editor_page.dart';
import '../../features/content/presentation/pages/publish_entry_page.dart';
import '../../features/content/presentation/pages/publish_post_page.dart';
import '../../features/main_shell/presentation/main_shell_page.dart';
import '../../features/message/presentation/messages_unavailable_page.dart';
import '../../features/search/presentation/pages/global_search_page.dart';
import '../../features/search/domain/search_models.dart';
import '../../features/recommendation/domain/recommendation_behavior.dart';
import '../../features/user_center/presentation/controllers/user_center_controllers.dart';
import '../../features/user_center/domain/user_center_models.dart';
import '../../features/user_center/presentation/pages/edit_profile_page.dart';
import '../../features/user_center/presentation/pages/followed_entities_page.dart';
import '../../features/user_center/presentation/pages/my_profile_page.dart';
import '../../features/user_center/presentation/pages/public_user_page.dart';
import '../../features/user_center/presentation/pages/unavailable_page.dart';
import '../../features/user_center/presentation/pages/user_list_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'auth_redirect.dart';
import 'route_names.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter(AuthController authController) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/bootstrap',
  refreshListenable: authController,
  redirect: (context, state) =>
      authRedirect(authController.state.status, state.matchedLocation),
  routes: [
    GoRoute(
      path: '/bootstrap',
      name: RouteNames.bootstrap,
      builder: (context, state) => const BootstrapPage(),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: RouteNames.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: RouteNames.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/authenticated',
      name: RouteNames.authenticated,
      redirect: (context, state) => '/app/home',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/home',
              name: RouteNames.home,
              builder: (context, state) => const HomeFeedPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/data',
              name: RouteNames.data,
              builder: (context, state) => const FootballDataPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/messages',
              name: RouteNames.messages,
              builder: (context, state) => const MessagesUnavailablePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/profile',
              name: RouteNames.profile,
              builder: (context, state) => const MyProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/users/me/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final summary = state.extra;
        return summary is MySummary
            ? EditProfilePage(summary: summary)
            : const UnavailablePage(
                title: '编辑资料',
                message: '请从“我的”页面重新进入编辑资料。',
              );
      },
    ),
    GoRoute(
      path: '/users/me/posts',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const UserListPage(
        title: '我的发布',
        request: UserListRequest(UserListKind.myContents),
      ),
    ),
    GoRoute(
      path: '/users/me/likes',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const UserListPage(
        title: '我的点赞',
        request: UserListRequest(UserListKind.myLikes),
      ),
    ),
    GoRoute(
      path: '/users/me/favorites',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const UserListPage(
        title: '我的收藏',
        request: UserListRequest(UserListKind.myFavorites),
      ),
    ),
    GoRoute(
      path: '/users/me/comments',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const UserListPage(
        title: '我的评论',
        request: UserListRequest(UserListKind.myComments),
      ),
    ),
    GoRoute(
      path: '/users/me/following',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = authController.state.user?.id ?? -1;
        return UserListPage(
          title: '关注的人',
          request: UserListRequest(UserListKind.followings, userId: id),
        );
      },
    ),
    GoRoute(
      path: '/users/me/followers',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = authController.state.user?.id ?? -1;
        return UserListPage(
          title: '我的粉丝',
          request: UserListRequest(UserListKind.followers, userId: id),
        );
      },
    ),
    GoRoute(
      path: '/users/me/followed-teams',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FollowedEntitiesPage(teams: true),
    ),
    GoRoute(
      path: '/users/me/followed-players',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FollowedEntitiesPage(teams: false),
    ),
    GoRoute(
      path: '/messages',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MessagesUnavailablePage(),
    ),
    GoRoute(
      path: '/users/:userId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => PublicUserPage(
        userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? -1,
      ),
      routes: [
        GoRoute(
          path: 'posts',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? -1;
            return UserListPage(
              title: '用户发布',
              request: UserListRequest(UserListKind.userContents, userId: id),
            );
          },
        ),
        GoRoute(
          path: 'following',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? -1;
            return UserListPage(
              title: '关注的人',
              request: UserListRequest(UserListKind.followings, userId: id),
            );
          },
        ),
        GoRoute(
          path: 'followers',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? -1;
            return UserListPage(
              title: '粉丝',
              request: UserListRequest(UserListKind.followers, userId: id),
            );
          },
        ),
        GoRoute(
          path: 'favorites',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? -1;
            return UserListPage(
              title: '用户收藏',
              request: UserListRequest(UserListKind.userFavorites, userId: id),
            );
          },
        ),
        GoRoute(
          path: 'comments',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? -1;
            return UserListPage(
              title: '用户评论',
              request: UserListRequest(UserListKind.userComments, userId: id),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      name: RouteNames.search,
      builder: (context, state) => const GlobalSearchPage(),
    ),
    GoRoute(
      path: '/publish',
      name: RouteNames.publish,
      builder: (context, state) => const PublishEntryPage(),
    ),
    GoRoute(
      path: '/publish/post',
      name: RouteNames.publishPost,
      builder: (context, state) => const PublishPostPage(),
    ),
    GoRoute(
      path: '/publish/article',
      name: RouteNames.publishArticle,
      builder: (context, state) => const ArticleEditorPage(),
    ),
    GoRoute(
      path: '/relations/select',
      builder: (context, state) => GlobalSearchPage(
        selectionMode: true,
        initialSelection: state.extra is List
            ? (state.extra as List).whereType<SearchEntity>().toList()
            : const [],
      ),
    ),
    GoRoute(
      path: '/contents/:contentId',
      name: RouteNames.contentDetail,
      builder: (context, state) => ContentDetailPage(
        contentId: int.tryParse(state.pathParameters['contentId'] ?? '') ?? -1,
        refreshFeedOnExit: state.extra is PublishedContentNavigation,
        recommendationSource: state.extra is RecommendationNavigationData
            ? (state.extra as RecommendationNavigationData).source
            : null,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          name: RouteNames.editArticle,
          builder: (context, state) => ArticleEditorPage(
            contentId:
                int.tryParse(state.pathParameters['contentId'] ?? '') ?? -1,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/matches/:matchId',
      name: RouteNames.matchDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => MatchDetailPage(
        matchId: int.tryParse(state.pathParameters['matchId'] ?? '') ?? -1,
        recommendationSource: state.extra is RecommendationNavigationData
            ? (state.extra as RecommendationNavigationData).source
            : null,
      ),
    ),
    GoRoute(
      path: '/match/:matchId',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          '/matches/${state.pathParameters['matchId']}',
    ),
    GoRoute(
      path: '/teams/:teamId',
      name: RouteNames.teamDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => TeamDetailPage(
        teamId: int.tryParse(state.pathParameters['teamId'] ?? '') ?? -1,
        recommendationSource: state.extra is RecommendationNavigationData
            ? (state.extra as RecommendationNavigationData).source
            : null,
      ),
    ),
    GoRoute(
      path: '/players/:playerId',
      name: RouteNames.playerDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => PlayerDetailPage(
        playerId: int.tryParse(state.pathParameters['playerId'] ?? '') ?? -1,
        recommendationSource: state.extra is RecommendationNavigationData
            ? (state.extra as RecommendationNavigationData).source
            : null,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('南看台')),
    body: const Center(child: Text('页面不存在')),
  ),
);
