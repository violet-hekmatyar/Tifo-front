import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/auth_brand_header.dart';
import '../controllers/auth_controller.dart';

class AuthenticatedPlaceholderPage extends ConsumerWidget {
  const AuthenticatedPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final user = controller.state.user;
    final displayName = user?.nickname?.isNotEmpty == true
        ? user!.nickname!
        : user?.username ?? '';
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthBrandHeader(title: '看台已就绪', subtitle: '你的账号与首次偏好已经安全保存'),
            Transform.translate(
              offset: const Offset(0, -AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFE2F5EC),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Icon(
                                Icons.check_rounded,
                                size: 38,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            '登录与首次设置已完成',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (displayName.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              displayName,
                              style: const TextStyle(color: AppColors.inkMuted),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Text(
                              'F04 主框架与首页待开发',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.brandDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppSecondaryButton(
                            label: '退出登录',
                            icon: Icons.logout_rounded,
                            onPressed: controller.logout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
