import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../controllers/user_center_controllers.dart';

class PublicUserPage extends ConsumerStatefulWidget {
  const PublicUserPage({required this.userId, super.key});
  final int userId;
  @override
  ConsumerState<PublicUserPage> createState() => _PublicUserPageState();
}

class _PublicUserPageState extends ConsumerState<PublicUserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(publicProfileControllerProvider(widget.userId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(publicProfileControllerProvider(widget.userId));
    final s = c.state;
    return Scaffold(
      appBar: AppBar(title: const Text('用户主页')),
      body: switch (s.status) {
        PublicProfileStatus.loading => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载用户主页',
          message: '正在读取公开资料。',
        ),
        PublicProfileStatus.notFound => const AppStateView(
          kind: AppStateKind.empty,
          title: '用户不存在',
          message: '该用户不存在或已停用。',
        ),
        PublicProfileStatus.failure => AppStateView(
          kind: AppStateKind.error,
          title: '用户主页加载失败',
          message: s.message ?? '请稍后重试。',
          onRetry: c.load,
        ),
        PublicProfileStatus.ready => _Body(controller: c),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.controller});
  final PublicProfileController controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = controller.state.profile!;
    final config = ref.watch(appConfigProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                AppEntityAvatar(
                  identity: 'user:${p.userId}',
                  semanticLabel: '${p.nickname}头像',
                  fallbackIcon: Icons.person_outline_rounded,
                  fallbackText: p.nickname.characters.first,
                  imageUrl: resolveMediaUrl(config, p.avatarUrl),
                  size: 76,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(p.nickname, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '@${p.username}',
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                if (p.bio case final bio?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(bio, textAlign: TextAlign.center),
                ],
                if (p.mainTeam case final team?)
                  TextButton.icon(
                    onPressed: () => context.push('/teams/${team.id}'),
                    icon: const Icon(Icons.shield_outlined),
                    label: Text('主队：${team.name}'),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _Stat('${p.contentCount}', '发布'),
                    _Stat('${p.followingCount}', '关注'),
                    _Stat('${p.followerCount}', '粉丝'),
                    _Stat('${p.likeReceivedCount}', '获赞'),
                  ],
                ),
                if (!p.currentUser) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('public_user_follow'),
                      onPressed: controller.state.followBusy
                          ? null
                          : controller.toggleFollow,
                      icon: Icon(
                        p.followed
                            ? Icons.person_remove_outlined
                            : Icons.person_add_alt_rounded,
                      ),
                      label: Text(p.followed ? '取消关注' : '关注'),
                    ),
                  ),
                ],
                if (controller.state.message case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('发布内容'),
                subtitle: const Text('查看该用户公开发布的内容'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/users/${p.userId}/posts'),
              ),
              ListTile(
                title: const Text('关注的人'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/users/${p.userId}/following'),
              ),
              ListTile(
                title: const Text('粉丝'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/users/${p.userId}/followers'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: AppColors.inkMuted)),
      ],
    ),
  );
}
