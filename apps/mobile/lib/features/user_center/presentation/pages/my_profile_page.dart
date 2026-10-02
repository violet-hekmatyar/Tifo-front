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
import '../widgets/profile_hero.dart';
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
      backgroundColor: AppColors.page,
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
      return const SafeArea(
        child: AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载个人主页',
          message: '正在读取你的资料与统计。',
        ),
      );
    }
    if (state.summary == null &&
        state.summaryStatus == MyProfileResourceStatus.failure) {
      return SafeArea(
        child: AppStateView(
          kind: AppStateKind.error,
          title: '个人主页加载失败',
          message: state.summaryMessage ?? '请检查网络后重试。',
          onRetry: controller.retrySummary,
        ),
      );
    }
    final summary = state.summary!;
    final actions = [
      ProfileHeroAction(
        label: '编辑资料',
        icon: Icons.edit_outlined,
        onPressed: () => context.push('/users/me/edit', extra: summary),
      ),
      ProfileHeroAction(
        label: '我的关注',
        icon: Icons.favorite_border_rounded,
        onPressed: () => context.push('/users/me/relations'),
      ),
      ProfileHeroAction(
        label: '我的粉丝',
        icon: Icons.people_outline_rounded,
        onPressed: () => context.push('/users/me/relations'),
      ),
    ];
    return Column(
      children: [
        UserProfileHero(
          key: const ValueKey('my_profile_hero'),
          userId: summary.userId,
          nickname: summary.nickname,
          username: summary.username,
          avatarUrl: summary.avatarUrl,
          bio: summary.bio,
          mainTeam: summary.mainTeam,
          contentCount: summary.postCount,
          followingCount: summary.followingCount,
          followerCount: summary.followerCount,
          likeReceivedCount: summary.favoriteCount,
          actions: actions,
          onSettings: () => context.push('/settings'),
        ),
        if (state.summaryMessage case final message?)
          _ErrorStrip(message: message, onRetry: controller.retrySummary),
        _ProfileTabs(controller: _tabs),
        Expanded(
          child: PageStorage(
            bucket: _pageStorage,
            child: TabBarView(
              controller: _tabs,
              children: [
                _StandView(
                  summary: summary,
                  state: state,
                  retry: controller.retryStand,
                ),
                UserListView(
                  key: const ValueKey('my_list_posts'),
                  request: const UserListRequest(UserListKind.myContents),
                  active: _tabs.index == 1,
                ),
                UserListView(
                  key: const ValueKey('my_list_likes'),
                  request: const UserListRequest(UserListKind.myLikes),
                  active: _tabs.index == 2,
                ),
                UserListView(
                  key: const ValueKey('my_list_favorites'),
                  request: const UserListRequest(UserListKind.myFavorites),
                  active: _tabs.index == 3,
                ),
                UserListView(
                  key: const ValueKey('my_list_comments'),
                  request: const UserListRequest(UserListKind.myComments),
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

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: TabBar(
      controller: controller,
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.inkMuted,
      indicatorColor: AppColors.brand,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(key: ValueKey('my_tab_stand'), text: '看台'),
        Tab(key: ValueKey('my_tab_posts'), text: '发布'),
        Tab(key: ValueKey('my_tab_likes'), text: '点赞'),
        Tab(key: ValueKey('my_tab_favorites'), text: '收藏'),
        Tab(key: ValueKey('my_tab_comments'), text: '评论'),
      ],
    ),
  );
}

class _StandView extends StatelessWidget {
  const _StandView({
    required this.summary,
    required this.state,
    required this.retry,
  });
  final MySummary summary;
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
    return ListView(
      key: const ValueKey('my_stand_scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      children: [
        if (state.standMessage case final message?)
          _ErrorStrip(message: message, onRetry: retry),
        _StandCard(
          actionKey: const ValueKey('my_profile_main_team'),
          title: '我的主队',
          description: '你心中的那支球队，始终与你同在',
          icon: Icons.star_rounded,
          items: summary.mainTeam == null ? const [] : [summary.mainTeam!],
          onTap: summary.mainTeam == null || summary.mainTeam!.id <= 0
              ? null
              : () => context.push('/teams/${summary.mainTeam!.id}'),
        ),
        _StandCard(
          title: '我关注的球队',
          description: '支持的球队，一起见证每一次胜利',
          icon: Icons.checkroom_rounded,
          items: stand.teams,
          onTap: () => context.push('/users/me/followed-teams'),
        ),
        _StandCard(
          title: '我关注的球星',
          description: '那些闪耀的名字，激励着我们前行',
          icon: Icons.person_rounded,
          items: stand.players,
          onTap: () => context.push('/users/me/followed-players'),
        ),
      ],
    );
  }
}

class _StandCard extends ConsumerWidget {
  const _StandCard({
    this.actionKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
    required this.onTap,
  });
  final Key? actionKey;
  final String title;
  final String description;
  final IconData icon;
  final List<EntityBrief> items;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        key: ValueKey('my_stand_card_$title'),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(icon, color: AppColors.brand, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  SizedBox(
                    width: 84,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        for (var i = 0; i < items.take(3).length; i++)
                          Positioned(
                            right: i * 17,
                            child: AppEntityAvatar(
                              identity: '$title:${items[i].id}',
                              semanticLabel: '${items[i].name}图片',
                              fallbackIcon: Icons.shield_outlined,
                              fallbackText: items[i].name.characters.first,
                              imageUrl: resolveMediaUrl(
                                config,
                                items[i].imageUrl,
                              ),
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (actionKey case final key?)
                  TextButton(
                    key: key,
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.inkMuted,
                    ),
                    child: const Icon(Icons.chevron_right_rounded),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
