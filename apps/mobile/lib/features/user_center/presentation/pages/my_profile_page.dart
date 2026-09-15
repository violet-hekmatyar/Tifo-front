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

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pageStorage = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(myProfileControllerProvider).load(),
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
    final controller = ref.watch(myProfileControllerProvider);
    final state = controller.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            key: const ValueKey('my_profile_settings'),
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            key: const ValueKey('my_profile_refresh'),
            tooltip: '刷新个人主页',
            onPressed: state.refreshing ? null : controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(context, controller, state),
    );
  }

  Widget _body(
    BuildContext context,
    MyProfileController controller,
    MyProfileState state,
  ) {
    if (state.summary == null &&
        state.summaryStatus == MyProfileResourceStatus.loading) {
      return const AppStateView(
        kind: AppStateKind.loading,
        title: '正在加载个人主页',
        message: '正在读取你的资料与统计。',
      );
    }
    if (state.summary == null &&
        state.summaryStatus == MyProfileResourceStatus.failure) {
      return AppStateView(
        kind: AppStateKind.error,
        title: '个人主页加载失败',
        message: state.summaryMessage ?? '请检查网络后重试。',
        onRetry: controller.retrySummary,
      );
    }
    final summary = state.summary!;
    return Column(
      children: [
        if (state.refreshing) const LinearProgressIndicator(minHeight: 2),
        _Header(summary: summary),
        if (state.summaryMessage != null)
          _ErrorStrip(
            message: state.summaryMessage!,
            onRetry: controller.retrySummary,
          ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(key: ValueKey('my_tab_stand'), text: '看台'),
            Tab(key: ValueKey('my_tab_posts'), text: '发布'),
            Tab(key: ValueKey('my_tab_likes'), text: '点赞'),
            Tab(key: ValueKey('my_tab_favorites'), text: '收藏'),
            Tab(key: ValueKey('my_tab_comments'), text: '评论'),
          ],
        ),
        Expanded(
          child: PageStorage(
            bucket: _pageStorage,
            child: TabBarView(
              controller: _tabs,
              children: [
                _StandView(state: state, retry: controller.retryStand),
                UserListView(
                  key: const ValueKey('my_list_posts'),
                  request: UserListRequest(UserListKind.myContents),
                  active: _tabs.index == 1,
                ),
                UserListView(
                  key: const ValueKey('my_list_likes'),
                  request: UserListRequest(UserListKind.myLikes),
                  active: _tabs.index == 2,
                ),
                UserListView(
                  key: const ValueKey('my_list_favorites'),
                  request: UserListRequest(UserListKind.myFavorites),
                  active: _tabs.index == 3,
                ),
                UserListView(
                  key: const ValueKey('my_list_comments'),
                  request: UserListRequest(UserListKind.myComments),
                  active: _tabs.index == 4,
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
  const _Header({required this.summary});
  final MySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final avatar = ref.watch(avatarUpdateControllerProvider);
    final initial = summary.nickname.trim().isEmpty
        ? '我'
        : summary.nickname.characters.first;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntityAvatar(
                  identity: 'user:${summary.userId}',
                  semanticLabel: '${summary.nickname}头像',
                  fallbackIcon: Icons.person_outline_rounded,
                  fallbackText: initial,
                  imageUrl: resolveMediaUrl(
                    config,
                    avatar.state.avatarUrl ?? summary.avatarUrl,
                  ),
                  size: 72,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.nickname,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '@${summary.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (summary.bio case final bio?)
                        Text(
                          bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      if (summary.mainTeam case final team?)
                        TextButton.icon(
                          key: const ValueKey('my_profile_main_team'),
                          onPressed: team.id > 0
                              ? () => context.push('/teams/${team.id}')
                              : null,
                          icon: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            '主队：${team.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Count('发布', summary.postCount),
                _Count(
                  '关注',
                  summary.followingCount,
                  onTap: () => context.push('/users/me/relations'),
                ),
                _Count(
                  '粉丝',
                  summary.followerCount,
                  onTap: () => context.push('/users/me/relations'),
                ),
                _Count('收藏', summary.favoriteCount),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('edit_profile'),
                    onPressed: () =>
                        context.push('/users/me/edit', extra: summary),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑资料'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('change_avatar'),
                    onPressed: avatar.state.busy
                        ? null
                        : avatar.chooseAndUpload,
                    icon: avatar.state.busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                    label: Text(avatar.state.busy ? '上传中' : '换头像'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (avatar.state.message case final message?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, {this.onTap});
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$value',
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

class _StandView extends StatelessWidget {
  const _StandView({required this.state, required this.retry});
  final MyProfileState state;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    if (state.stand == null &&
        state.standStatus == MyProfileResourceStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.stand == null &&
        state.standStatus == MyProfileResourceStatus.failure) {
      return AppStateView(
        kind: AppStateKind.error,
        title: '看台加载失败',
        message: state.standMessage ?? '请稍后重试。',
        onRetry: retry,
      );
    }
    final stand = state.stand!;
    if (stand.teams.isEmpty && stand.players.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: '看台还是空的',
        message: '关注球队或球员后，它们会出现在这里。',
      );
    }
    return ListView(
      key: const ValueKey('my_stand_scroll'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (state.standMessage case final message?)
          _ErrorStrip(message: message, onRetry: retry),
        _StandSection(
          title: '关注的球队',
          items: stand.teams,
          route: '/teams',
          icon: Icons.shield_outlined,
        ),
        _StandSection(
          title: '关注的球员',
          items: stand.players,
          route: '/players',
          icon: Icons.sports_soccer_rounded,
        ),
      ],
    );
  }
}

class _StandSection extends StatelessWidget {
  const _StandSection({
    required this.title,
    required this.items,
    required this.route,
    required this.icon,
  });
  final String title;
  final List<EntityBrief> items;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text('暂无关注', style: TextStyle(color: AppColors.inkMuted)),
          )
        else
          for (final item in items)
            ListTile(
              leading: Icon(icon, color: AppColors.brand),
              title: Text(item.name),
              subtitle: item.subtitle == null ? null : Text(item.subtitle!),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: item.id > 0
                  ? () => context.push('$route/${item.id}')
                  : null,
            ),
      ],
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
