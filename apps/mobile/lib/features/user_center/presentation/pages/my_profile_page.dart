import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mySummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: value.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载个人主页',
          message: '正在读取你的资料与统计。',
        ),
        error: (_, _) => AppStateView(
          kind: AppStateKind.error,
          title: '个人主页加载失败',
          message: '请检查网络后重试。',
          onRetry: () => ref.invalidate(mySummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(mySummaryProvider),
          child: _ProfileBody(
            summary: summary,
            onLogout: ref.read(authControllerProvider).logout,
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.summary, required this.onLogout});
  final MySummary summary;
  final Future<void> Function() onLogout;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final avatar = ref.watch(avatarUpdateControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                AppEntityAvatar(
                  identity: 'user:${summary.userId}',
                  semanticLabel: '${summary.nickname}头像',
                  fallbackIcon: Icons.person_outline_rounded,
                  fallbackText: summary.nickname.characters.first,
                  imageUrl: resolveMediaUrl(
                    config,
                    avatar.state.avatarUrl ?? summary.avatarUrl,
                  ),
                  size: 68,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.nickname,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '@${summary.username}',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      if (summary.bio case final bio?)
                        Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (summary.mainTeam case final team?)
                        Text('主队：${team.name}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Counts(summary: summary),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push('/users/me/edit', extra: summary),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('编辑资料'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const ValueKey('change_avatar'),
          onPressed: avatar.state.busy ? null : avatar.chooseAndUpload,
          icon: avatar.state.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(avatar.state.busy ? '头像上传中' : '更换头像'),
        ),
        if (avatar.state.message case final message?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: '内容与互动',
          children: [
            _Entry(
              icon: Icons.article_outlined,
              label: '我的发布',
              count: summary.postCount,
              onTap: () => context.push('/users/me/posts'),
            ),
            _Entry(
              icon: Icons.favorite_border_rounded,
              label: '我的点赞',
              onTap: () => context.push('/users/me/likes'),
            ),
            _Entry(
              icon: Icons.bookmark_border_rounded,
              label: '我的收藏',
              count: summary.favoriteCount,
              onTap: () => context.push('/users/me/favorites'),
            ),
            _Entry(
              icon: Icons.chat_bubble_outline_rounded,
              label: '我的评论',
              count: summary.commentCount,
              onTap: () => context.push('/users/me/comments'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: '我的关注',
          children: [
            _Entry(
              icon: Icons.person_add_alt_rounded,
              label: '关注的人',
              count: summary.followingCount,
              onTap: () => context.push('/users/me/following'),
            ),
            _Entry(
              icon: Icons.people_outline_rounded,
              label: '我的粉丝',
              count: summary.followerCount,
              onTap: () => context.push('/users/me/followers'),
            ),
            _Entry(
              icon: Icons.shield_outlined,
              label: '关注的球队',
              count: summary.teamFollowCount,
              onTap: () => context.push('/users/me/followed-teams'),
            ),
            _Entry(
              icon: Icons.sports_soccer_rounded,
              label: '关注的球员',
              count: summary.playerFollowCount,
              onTap: () => context.push('/users/me/followed-players'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.summary});
  final MySummary summary;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          _Count(label: '发布', value: summary.postCount),
          _Count(label: '关注', value: summary.followingCount),
          _Count(label: '粉丝', value: summary.followerCount),
          _Count(label: '收藏', value: summary.favoriteCount),
        ],
      ),
    ),
  );
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: AppColors.inkMuted)),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.label,
    this.count,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.brand),
    title: Text(label),
    trailing: onTap == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count != null) Text('$count'),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
    enabled: onTap != null,
    onTap: onTap,
  );
}
