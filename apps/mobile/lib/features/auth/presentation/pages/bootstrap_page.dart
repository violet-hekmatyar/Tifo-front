import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

class BootstrapPage extends ConsumerWidget {
  const BootstrapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: state.status == AuthStatus.failure
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 52),
                      const SizedBox(height: 16),
                      Text(state.message ?? '登录状态恢复失败。'),
                      if (state.traceId != null) Text('追踪号：${state.traceId}'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.retryBootstrap,
                        child: const Text('重试'),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '南看台',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在恢复登录状态…'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
