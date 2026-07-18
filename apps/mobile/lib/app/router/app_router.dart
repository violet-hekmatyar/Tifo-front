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
import '../../features/content/presentation/pages/publish_post_page.dart';
import '../../features/main_shell/presentation/feature_placeholder_page.dart';
import '../../features/main_shell/presentation/main_shell_page.dart';
import '../../features/main_shell/presentation/messages_placeholder_page.dart';
import '../../features/main_shell/presentation/profile_placeholder_page.dart';
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
              builder: (context, state) => const MessagesPlaceholderPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/profile',
              name: RouteNames.profile,
              builder: (context, state) => const ProfilePlaceholderPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      name: RouteNames.search,
      builder: (context, state) => const FeaturePlaceholderPage(
        title: '搜索',
        message: '搜索入口已建立',
        detail: '内容、球队和用户搜索将在后续阶段接入。',
      ),
    ),
    GoRoute(
      path: '/publish/post',
      name: RouteNames.publishPost,
      builder: (context, state) => const PublishPostPage(),
    ),
    GoRoute(
      path: '/contents/:contentId',
      name: RouteNames.contentDetail,
      builder: (context, state) => ContentDetailPage(
        contentId: int.tryParse(state.pathParameters['contentId'] ?? '') ?? -1,
        refreshFeedOnExit: state.extra is PublishedContentNavigation,
      ),
    ),
    GoRoute(
      path: '/matches/:matchId',
      name: RouteNames.matchDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => MatchDetailPage(
        matchId: int.tryParse(state.pathParameters['matchId'] ?? '') ?? -1,
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
      ),
    ),
    GoRoute(
      path: '/players/:playerId',
      name: RouteNames.playerDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => PlayerDetailPage(
        playerId: int.tryParse(state.pathParameters['playerId'] ?? '') ?? -1,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('南看台')),
    body: const Center(child: Text('页面不存在')),
  ),
);
