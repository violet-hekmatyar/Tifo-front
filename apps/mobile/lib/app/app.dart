import 'package:flutter/material.dart';
import 'package:tifo/app/router/app_router.dart';
import 'package:tifo/app/theme/app_theme.dart';

class TifoApp extends StatelessWidget {
  const TifoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '南看台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
