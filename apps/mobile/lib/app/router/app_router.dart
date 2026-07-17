import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/authenticated_placeholder_page.dart';
import '../../features/auth/presentation/pages/bootstrap_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'auth_redirect.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthController authController) => GoRouter(
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
      builder: (context, state) => const AuthenticatedPlaceholderPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('南看台')),
    body: const Center(child: Text('页面不存在')),
  ),
);
