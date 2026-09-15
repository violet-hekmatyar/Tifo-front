import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';
import 'user_list_page.dart';

class PublicUserPage extends ConsumerStatefulWidget {
  const PublicUserPage({required this.userId, super.key});
  final int userId;

  @override
  ConsumerState<PublicUserPage> createState() => _PublicUserPageState();
}

class _PublicUserPageState extends ConsumerState<PublicUserPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pageStorage = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(publicProfileControllerProvider(widget.userId)).load(),
    );
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      publicProfileControllerProvider(widget.userId),
    );
    final state = controller.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户主页'),
        actions: [
          IconButton(
            key: const ValueKey('public_user_refresh'),
            tooltip: '刷新用户主页',
            onPressed: state.refreshing ? null : controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: switch (state.status) {
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
          message: state.message ?? '请稍后重试。',
          onRetry: controller.load,
        ),
        PublicProfileStatus.ready => _Body(
          controller: controller,
          tabs: _tabs,
          activeTab: _tabs.index,
          bucket: _pageStorage,
        ),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.tabs,
    required this.activeTab,
    required this.bucket,
  });
  final PublicProfileController controller;
  final TabController tabs;
  final int activeTab;
  final PageStorageBucket bucket;

  @override
  Widget build(BuildContext context) {
    final p = controller.state.profile!;
    return Column(
      children: [
        if (controller.state.refreshing)
          const LinearProgressIndicator(minHeight: 2),
        _Header(profile: p, controller: controller),
        if (controller.state.message case final message?)
          _ErrorStrip(message: message, onRetry: controller.refresh),
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(key: ValueKey('public_tab_posts'), text: '发布'),
            Tab(key: ValueKey('public_tab_favorites'), text: '收藏'),
            Tab(key: ValueKey('public_tab_comments'), text: '评论'),
          ],
        ),
        Expanded(
          child: PageStorage(
            bucket: bucket,
            child: TabBarView(
              controller: tabs,
              children: [
                UserListView(
                  key: const ValueKey('public_list_posts'),
                  request: UserListRequest(
                    UserListKind.userContents,
                    userId: p.userId,
                  ),
                  allowUserActions: false,
                  active: activeTab == 0,
                ),
                UserListView(
                  key: const ValueKey('public_list_favorites'),
                  request: UserListRequest(
                    UserListKind.userFavorites,
                    userId: p.userId,
                  ),
                  allowUserActions: false,
                  active: activeTab == 1,
                ),
                UserListView(
                  key: const ValueKey('public_list_comments'),
                  request: UserListRequest(
                    UserListKind.userComments,
                    userId: p.userId,
                  ),
                  allowUserActions: false,
                  active: activeTab == 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile, required this.controller});
  final UserProfile profile;
  final PublicProfileController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final canFollow =
        !profile.isSelf &&
        {
          'NONE',
          'FOLLOWING',
          'FOLLOWED_BY',
          'MUTUAL',
        }.contains(profile.relationStatus);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppEntityAvatar(
              identity: 'user:${profile.userId}',
              semanticLabel: '${profile.nickname}头像',
              fallbackIcon: Icons.person_outline_rounded,
              fallbackText: profile.nickname,
              imageUrl: resolveMediaUrl(config, profile.avatarUrl),
              size: 78,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              profile.nickname,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '@${profile.username}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              profile.isSelf ? '本人' : profile.relationLabel,
              style: const TextStyle(color: Colors.white),
            ),
            if (profile.bio case final bio?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (profile.mainTeam case final team?)
              TextButton.icon(
                key: const ValueKey('public_user_main_team'),
                onPressed: team.id > 0
                    ? () => context.push('/teams/${team.id}')
                    : null,
                icon: const Icon(Icons.shield_outlined, color: Colors.white),
                label: Text(
                  '主队：${team.name}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Stat('${profile.contentCount}', '发布'),
                _Stat(
                  '${profile.followingCount}',
                  '关注',
                  onTap: () =>
                      context.push('/users/${profile.userId}/relations'),
                ),
                _Stat(
                  '${profile.followerCount}',
                  '粉丝',
                  onTap: () =>
                      context.push('/users/${profile.userId}/relations'),
                ),
                _Stat('${profile.likeReceivedCount}', '获赞'),
              ],
            ),
            if (canFollow) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('public_user_follow'),
                  onPressed: controller.state.followBusy
                      ? null
                      : () => _confirmFollow(context, controller, profile),
                  icon: Icon(
                    profile.followed
                        ? Icons.person_remove_outlined
                        : Icons.person_add_alt_rounded,
                  ),
                  label: Text(_followActionLabel(profile)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _followActionLabel(UserProfile profile) =>
    switch (profile.relationStatus) {
      'FOLLOWED_BY' => '回关',
      'MUTUAL' => '取消互关',
      'FOLLOWING' => '取消关注',
      _ => '关注',
    };

Future<void> _confirmFollow(
  BuildContext context,
  PublicProfileController controller,
  UserProfile profile,
) async {
  final follow = !profile.followed;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(follow ? '确认关注' : '确认取消关注'),
      content: Text(
        follow ? '确认关注 ${profile.nickname}？' : '确认取消关注 ${profile.nickname}？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  if (confirmed == true) await controller.toggleFollow();
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.onTap});
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.error.withValues(alpha: .08),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.info_outline_rounded, color: AppColors.error),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('重试')),
    ),
  );
}
