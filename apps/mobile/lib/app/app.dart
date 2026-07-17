import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TifoApp extends ConsumerStatefulWidget {
  const TifoApp({super.key});

  @override
  ConsumerState<TifoApp> createState() => _TifoAppState();
}

class _TifoAppState extends ConsumerState<TifoApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = ref.read(authControllerProvider);
    _router = createAppRouter(_authController);
    unawaited(Future<void>(_authController.initialize));
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: '南看台',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: _router,
  );
}
