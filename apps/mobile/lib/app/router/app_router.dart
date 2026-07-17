import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/router/route_names.dart';
import 'package:tifo/features/skeleton/presentation/pages/skeleton_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.skeleton,
      builder: (context, state) => const SkeletonPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('南看台')),
    body: const Center(child: Text('Page not found')),
  ),
);
