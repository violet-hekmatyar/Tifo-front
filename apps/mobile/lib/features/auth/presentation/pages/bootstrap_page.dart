import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../controllers/auth_controller.dart';

class BootstrapPage extends ConsumerWidget {
  const BootstrapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandDark, AppColors.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: state.status == AuthStatus.failure
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                size: 52,
                                color: AppColors.brandDark,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                state.message ?? '登录状态恢复失败。',
                                key: const ValueKey(
                                  'bootstrap_failure_message',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (state.traceId != null)
                                Text(
                                  '追踪号：${state.traceId}',
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                key: const ValueKey('bootstrap_retry'),
                                onPressed: controller.retryBootstrap,
                                child: const Text('重试'),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_soccer_rounded,
                                size: 42,
                                color: AppColors.brand,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                '南看台',
                                style: TextStyle(
                                  color: AppColors.brandDark,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              CircularProgressIndicator(),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                '正在恢复登录状态…',
                                key: ValueKey('bootstrap_loading_message'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
