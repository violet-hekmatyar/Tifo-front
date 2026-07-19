import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({required this.title, required this.request, super.key});
  final String title;
  final UserListRequest request;
  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_nearEnd);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(userListControllerProvider(widget.request)).loadInitial(),
    );
  }

  void _nearEnd() {
    if (_scroll.position.extentAfter < 360) {
      ref.read(userListControllerProvider(widget.request)).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(userListControllerProvider(widget.request));
    final s = c.state;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: switch (s.status) {
        UserListStatus.loading => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载',
          message: '正在读取真实数据。',
        ),
        UserListStatus.failure => AppStateView(
          kind: AppStateKind.error,
          title: '加载失败',
          message: s.message ?? '请稍后重试。',
          onRetry: c.retry,
        ),
        UserListStatus.empty => RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 520,
                child: AppStateView(
                  kind: AppStateKind.empty,
                  title: '暂无内容',
                  message: '这里还没有可展示的真实记录。',
                ),
              ),
            ],
          ),
        ),
        UserListStatus.ready => RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: s.items.length + 1,
            itemBuilder: (context, index) => index == s.items.length
                ? _Footer(state: s, retry: c.loadMore)
                : _item(context, s.items[index], c),
          ),
        ),
      },
    );
  }

  Widget _item(
    BuildContext context,
    Object value,
    UserListController controller,
  ) => switch (value) {
    UserContentItem item => Card(
      child: ListTile(
        key: ValueKey('user-content-${item.contentId}'),
        leading: const Icon(Icons.article_outlined),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${item.likeCount} 赞 · ${item.commentCount} 评论 · ${item.favoriteCount} 收藏',
        ),
        onTap: () => context.push('/contents/${item.contentId}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    ),
    UserFavoriteItem item => Card(
      child: ListTile(
        leading: const Icon(Icons.bookmark_rounded),
        title: Text(item.title),
        subtitle: item.summary == null
            ? null
            : Text(item.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => context.push('/contents/${item.contentId}'),
        trailing: IconButton(
          tooltip: '取消收藏',
          onPressed: () => controller.removeItem(item),
          icon: const Icon(Icons.bookmark_remove_outlined),
        ),
      ),
    ),
    UserCommentItem item => Card(
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline_rounded),
        title: Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: item.contentTitle == null ? null : Text(item.contentTitle!),
        onTap: () => context.push('/contents/${item.contentId}'),
        trailing: IconButton(
          tooltip: '删除评论',
          onPressed: () => controller.removeItem(item),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    ),
    UserBrief item => Card(
      child: ListTile(
        leading: AppEntityAvatar(
          identity: 'user:${item.userId}',
          semanticLabel: '${item.nickname}头像',
          fallbackIcon: Icons.person_outline_rounded,
          fallbackText: item.nickname.characters.first,
          imageUrl: item.avatarUrl,
          size: 44,
        ),
        title: Text(item.nickname),
        subtitle: Text(
          item.bio ?? '@${item.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/users/${item.userId}'),
      ),
    ),
    _ => const SizedBox.shrink(),
  };
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.retry});
  final UserListState state;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.appendMessage != null) {
      return TextButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text('${state.appendMessage} 点击重试'),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text('已经到底了', style: TextStyle(color: AppColors.inkMuted)),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.lg);
  }
}
