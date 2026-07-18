import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/app_design_tokens.dart';
import '../../../shared/widgets/app_entity_avatar.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class ProfilePlaceholderPage extends ConsumerWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final user = controller.state.user;
    final name = user?.nickname?.isNotEmpty == true
        ? user!.nickname!
        : user?.username ?? '南看台用户';
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    AppEntityAvatar(
                      identity: 'user:${user?.id ?? name}',
                      semanticLabel: '$name 头像',
                      fallbackIcon: Icons.person_outline_rounded,
                      fallbackText: name.characters.first,
                      size: 72,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    if (user?.username case final username?)
                      Text(
                        username,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      '个人资料、关注和互动记录将在 F07 完善。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppSecondaryButton(
                      key: const ValueKey('profile_logout'),
                      label: '退出登录',
                      icon: Icons.logout_rounded,
                      onPressed: controller.logout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
