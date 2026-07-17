import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

class AuthenticatedPlaceholderPage extends ConsumerWidget {
  const AuthenticatedPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final user = controller.state.user;
    return Scaffold(
      appBar: AppBar(title: const Text('南看台')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                '登录与首次设置已完成',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                user?.nickname?.isNotEmpty == true
                    ? user!.nickname!
                    : user?.username ?? '',
              ),
              const SizedBox(height: 8),
              const Text('F04 主框架与首页待开发'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
