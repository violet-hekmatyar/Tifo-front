import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';
import '../widgets/profile_hero.dart';
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
      backgroundColor: AppColors.page,
      body: switch (state.status) {
        PublicProfileStatus.loading => const SafeArea(
          child: AppStateView(
            kind: AppStateKind.loading,
            title: '正在加载用户主页',
            message: '正在读取公开资料。',
          ),
        ),
        PublicProfileStatus.notFound => const SafeArea(
          child: AppStateView(
            kind: AppStateKind.empty,
            title: '用户不存在',
            message: '该用户不存在或已停用。',
          ),
        ),
        PublicProfileStatus.failure => SafeArea(
          child: AppStateView(
            kind: AppStateKind.error,
            title: '用户主页加载失败',
            message: state.message ?? '请稍后重试。',
            onRetry: controller.load,
          ),
        ),
        PublicProfileStatus.ready => _Body(
          controller: controller,
          tabs: _tabs,
          activeTab: _tabs.index,
          bucket: _pageStorage,
          onBack: () => context.pop(),
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
    required this.onBack,
  });
  final PublicProfileController controller;
  final TabController tabs;
  final int activeTab;
  final PageStorageBucket bucket;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = controller.state.profile!;
    final canFollow =
        !p.isSelf &&
        {
          'NONE',
          'FOLLOWING',
          'FOLLOWED_BY',
          'MUTUAL',
        }.contains(p.relationStatus);
    final actions = [
      ProfileHeroAction(
        label: p.isSelf ? '本人' : _followActionLabel(p),
        icon: p.followed
            ? Icons.person_remove_outlined
            : Icons.person_add_alt_rounded,
        busy: controller.state.followBusy,
        key: canFollow ? const ValueKey('public_user_follow') : null,
        onPressed: canFollow
            ? () => _confirmFollow(context, controller, p)
            : null,
      ),
      ProfileHeroAction(
        label: '他的关注',
        icon: Icons.favorite_border_rounded,
        onPressed: () => context.push('/users/${p.userId}/relations'),
      ),
      ProfileHeroAction(
        label: '他的粉丝',
        icon: Icons.people_outline_rounded,
        onPressed: () => context.push('/users/${p.userId}/relations'),
      ),
    ];
    return Column(
      children: [
        const Text(
          '用户主页',
          style: TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
        ),
        UserProfileHero(
          key: const ValueKey('public_profile_hero'),
          userId: p.userId,
          nickname: p.nickname,
          username: p.username,
          avatarUrl: p.avatarUrl,
          bio: p.bio,
          mainTeam: p.mainTeam,
          contentCount: p.contentCount,
          followingCount: p.followingCount,
          followerCount: p.followerCount,
          likeReceivedCount: p.likeReceivedCount,
          actions: actions,
          relationLabel: p.isSelf ? null : p.relationLabel,
          onBack: onBack,
          followBusy: controller.state.followBusy,
        ),
        if (controller.state.message case final message?)
          _ErrorStrip(message: message, onRetry: controller.refresh),
        Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: TabBar(
            controller: tabs,
            labelColor: AppColors.brand,
            unselectedLabelColor: AppColors.inkMuted,
            indicatorColor: AppColors.brand,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(key: ValueKey('public_tab_posts'), text: '发布'),
              Tab(key: ValueKey('public_tab_favorites'), text: '收藏'),
              Tab(key: ValueKey('public_tab_comments'), text: '评论'),
            ],
          ),
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
