import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_state_illustration.dart';
import '../../../feed/domain/feed_card.dart';
import '../../../feed/presentation/widgets/content_card.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({required this.title, required this.request, super.key});
  final String title;
  final UserListRequest request;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: UserListView(request: request),
  );
}

class UserListView extends ConsumerStatefulWidget {
  const UserListView({
    required this.request,
    this.scrollController,
    this.showSearch = false,
    this.searchHint = '搜索已加载用户',
    this.allowUserActions = true,
    this.active = true,
    super.key,
  });
  final UserListRequest request;
  final ScrollController? scrollController;
  final bool showSearch;
  final String searchHint;
  final bool allowUserActions;
  final bool active;

  @override
  ConsumerState<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scroll;
  final _search = TextEditingController();
  String _query = '';
  double _savedScrollOffset = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll = widget.scrollController ?? ScrollController();
    _scroll.addListener(_onScroll);
    _loadWhenActive();
  }

  @override
  void didUpdateWidget(covariant UserListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _loadWhenActive();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients || _savedScrollOffset <= 0) {
          return;
        }
        _scroll.jumpTo(
          math.min(_savedScrollOffset, _scroll.position.maxScrollExtent),
        );
      });
    }
  }

  void _loadWhenActive() {
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(userListControllerProvider(widget.request)).loadInitial(),
    );
  }

  void _onScroll() {
    _savedScrollOffset = _scroll.hasClients ? _scroll.position.pixels : 0;
    if (_scroll.hasClients && _scroll.position.extentAfter < 360) {
      ref.read(userListControllerProvider(widget.request)).loadMore();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = ref.watch(userListControllerProvider(widget.request));
    final state = controller.state;
    if (state.status == UserListStatus.loading && state.items.isEmpty) {
      return const SingleChildScrollView(
        child: SizedBox(
          height: 260,
          child: AppStateView(
            kind: AppStateKind.loading,
            title: '正在加载',
            message: '正在读取真实数据。',
          ),
        ),
      );
    }
    if (state.status == UserListStatus.failure && state.items.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 260,
          child: AppStateView(
            kind: AppStateKind.error,
            title: '加载失败',
            message: state.message ?? '请稍后重试。',
            onRetry: controller.retry,
          ),
        ),
      );
    }
    if (state.status == UserListStatus.restricted && state.items.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 260,
          child: AppStateView(
            kind: AppStateKind.error,
            title: '该列表不可查看',
            message: state.message ?? '该列表受隐私保护。',
            onRetry: controller.retry,
          ),
        ),
      );
    }
    final values = _filtered(state.items);
    final compactContentList = switch (widget.request.kind) {
      UserListKind.myContents ||
      UserListKind.myLikes ||
      UserListKind.myFavorites ||
      UserListKind.userContents ||
      UserListKind.userFavorites => true,
      _ => false,
    };
    final emptyIllustration = switch (widget.request.kind) {
      UserListKind.myComments ||
      UserListKind.userComments => AppStateIllustrationType.noComments,
      UserListKind.myFavorites ||
      UserListKind.userFavorites => AppStateIllustrationType.noFavorites,
      UserListKind.followings ||
      UserListKind.followers => AppStateIllustrationType.noFollowing,
      _ => null,
    };
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        key: PageStorageKey<String>(
          'user-list-${widget.request.kind.name}-${widget.request.userId ?? 'me'}',
        ),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          compactContentList ? 6 : AppSpacing.md,
          AppSpacing.sm,
          compactContentList ? 6 : AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          if (widget.showSearch) _searchField(),
          if (state.refreshing) const LinearProgressIndicator(minHeight: 2),
          if (state.message != null && state.items.isNotEmpty)
            _MessageBanner(
              message: state.message!,
              onRetry: controller.refresh,
            ),
          if (state.status == UserListStatus.restricted)
            _MessageBanner(
              message: state.message ?? '该列表受隐私保护。',
              onRetry: controller.retry,
            ),
          if (values.isEmpty)
            SizedBox(
              height: 420,
              child: AppStateView(
                kind: AppStateKind.empty,
                title: '暂无内容',
                message: '这里还没有可展示的真实记录。',
                illustration: emptyIllustration,
              ),
            )
          else
            _records(values, controller),
          if (state.status == UserListStatus.ready &&
              _query.isEmpty &&
              state.items.isNotEmpty)
            _Footer(state: state, retry: controller.loadMore),
        ],
      ),
    );
  }

  Widget _searchField() => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextField(
      key: const ValueKey('user_list_search'),
      controller: _search,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: '清空搜索',
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.2),
        ),
        isDense: true,
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );

  List<Object> _filtered(List<Object> values) {
    if (!widget.showSearch || _query.isEmpty) return values;
    return values.where((value) {
      if (value is! UserBrief) return true;
      return [
        value.nickname,
        value.username,
        value.bio,
      ].whereType<String>().any((text) => text.toLowerCase().contains(_query));
    }).toList();
  }

  Widget _records(List<Object> values, UserListController controller) {
    final isContentList = values.every(
      (value) =>
          value is UserContentItem ||
          value is UserLikeItem ||
          value is UserFavoriteItem,
    );
    if (!isContentList) {
      return Column(
        children: [for (final value in values) _item(value, controller)],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final single =
            MediaQuery.sizeOf(context).width <= 360 ||
            MediaQuery.textScalerOf(context).scale(14) > 16.5;
        if (single) {
          return Column(
            children: [
              for (var i = 0; i < values.length; i++)
                _contentItem(values[i], index: i, singleColumn: true),
            ],
          );
        }
        final left = <Object>[];
        final right = <Object>[];
        for (var i = 0; i < values.length; i++) {
          (i.isEven ? left : right).add(values[i]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < left.length; i++)
                    _contentItem(left[i], index: i * 2),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < right.length; i++)
                    _contentItem(right[i], index: i * 2 + 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _contentItem(
    Object value, {
    required int index,
    bool singleColumn = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: switch (value) {
      UserContentItem item => _contentCard(
        contentId: item.contentId,
        title: item.title,
        summary: item.summary,
        coverUrl: item.coverUrl,
        contentType: item.contentType,
        likeCount: item.likeCount,
        commentCount: item.commentCount,
        authorId: item.authorId,
        authorNickname: item.authorNickname,
        authorAvatarUrl: item.authorAvatarUrl,
        keyPrefix: 'user-content',
        mediaAspectRatio: singleColumn ? 1.2 : (index.isEven ? 1.0 : 1.43),
      ),
      UserLikeItem item => _contentCard(
        contentId: item.contentId,
        title: item.title,
        summary: item.summary,
        coverUrl: item.coverUrl,
        contentType: item.contentType,
        likeCount: item.likeCount,
        commentCount: item.commentCount,
        authorId: item.authorId,
        authorNickname: item.authorNickname,
        authorAvatarUrl: item.authorAvatarUrl,
        visible: item.visible,
        keyPrefix: 'user-like',
        mediaAspectRatio: singleColumn ? 1.2 : (index.isEven ? 1.0 : 1.43),
      ),
      UserFavoriteItem item => _contentCard(
        contentId: item.contentId,
        title: item.title,
        summary: item.summary,
        coverUrl: item.coverUrl,
        contentType: 'POST',
        likeCount: 0,
        commentCount: 0,
        authorId: item.authorId,
        authorNickname: item.authorNickname,
        authorAvatarUrl: item.authorAvatarUrl,
        removable: widget.request.kind == UserListKind.myFavorites,
        keyPrefix: 'user-favorite',
        mediaAspectRatio: singleColumn ? 1.2 : (index.isEven ? 1.0 : 1.43),
      ),
      _ => const SizedBox.shrink(),
    },
  );

  Widget _contentCard({
    required int contentId,
    required String title,
    required String? summary,
    required String? coverUrl,
    required String contentType,
    required int likeCount,
    required int commentCount,
    required int? authorId,
    required String? authorNickname,
    required String? authorAvatarUrl,
    required String keyPrefix,
    bool visible = true,
    bool removable = false,
    double? mediaAspectRatio,
  }) {
    final config = ref.read(appConfigProvider);
    if (!visible) {
      return Card(
        key: ValueKey('user-like-$contentId'),
        child: ListTile(
          leading: const Icon(Icons.visibility_off_outlined),
          title: Text(title),
          subtitle: const Text('内容当前不可见，无法打开。'),
        ),
      );
    }
    final card = ContentFeedCard(
      cardId: '$contentId',
      rawCardType: 'CONTENT',
      contentId: contentId,
      contentType: contentType,
      title: title,
      summary: summary,
      coverUrl: coverUrl,
      likeCount: likeCount,
      commentCount: commentCount,
      author: authorId == null && authorNickname == null
          ? null
          : FeedAuthor(
              userId: authorId,
              nickname: authorNickname ?? '南看台用户',
              avatarUrl: authorAvatarUrl,
            ),
    );
    return Stack(
      children: [
        ContentCard(
          key: ValueKey('$keyPrefix-$contentId'),
          card: card,
          coverUrl: resolveMediaUrl(config, coverUrl),
          authorAvatarUrl: resolveMediaUrl(config, authorAvatarUrl),
          authorFallbackAsset: 'assets/ui/profile/user-demo.png',
          userCenterStyle: true,
          userCenterMediaAspectRatio: mediaAspectRatio,
          showMedia: coverUrl != null && coverUrl.trim().isNotEmpty,
          onTap: () => context.push('/contents/$contentId'),
        ),
        if (widget.request.kind == UserListKind.userFavorites)
          const Positioned(
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        if (removable)
          Positioned(
            right: 4,
            bottom: 4,
            child: IconButton(
              tooltip: '取消收藏',
              onPressed: () => _confirmRemove(
                context,
                ref.read(userListControllerProvider(widget.request)),
                contentId,
              ),
              icon: const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Icon(Icons.bookmark_remove_outlined, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _item(Object value, UserListController controller) => switch (value) {
    UserCommentItem item => Card(
      key: ValueKey('user-comment-${item.commentId}'),
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline_rounded),
        title: Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.contentTitle ?? '内容已删除或不可见'),
        onTap: item.contentId > 0
            ? () => context.push('/contents/${item.contentId}')
            : null,
        trailing: widget.request.kind == UserListKind.myComments
            ? IconButton(
                tooltip: '删除评论',
                onPressed: () =>
                    _confirmRemove(context, controller, item.commentId),
                icon: const Icon(Icons.delete_outline_rounded),
              )
            : const Icon(Icons.chevron_right_rounded),
      ),
    ),
    UserBrief item => _userRow(item, controller),
    _ => const SizedBox.shrink(),
  };

  Widget _userRow(UserBrief item, UserListController controller) {
    final busy = controller.state.busyItemKeys.contains('user:${item.userId}');
    final actionable =
        widget.allowUserActions &&
        item.userId > 0 &&
        item.relationStatus != 'SELF' &&
        {
          'NONE',
          'FOLLOWING',
          'FOLLOWED_BY',
          'MUTUAL',
        }.contains(item.relationStatus);
    final config = ref.read(appConfigProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SizedBox(
        height: 62,
        child: ListTile(
          key: ValueKey('user-row-${item.userId}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: AppEntityAvatar(
            identity: 'user:${item.userId}',
            semanticLabel: '${item.nickname}头像',
            fallbackIcon: Icons.person_outline_rounded,
            fallbackText: item.nickname,
            fallbackAsset: 'assets/ui/profile/user-demo.png',
            imageUrl: resolveMediaUrl(config, item.avatarUrl),
            size: 44,
          ),
          title: Text(
            item.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            item.bio?.isNotEmpty == true ? item.bio! : '@${item.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: item.userId > 0
              ? () => context.push('/users/${item.userId}')
              : null,
          trailing: actionable
              ? TextButton(
                  key: ValueKey('user-follow-${item.userId}'),
                  onPressed: busy
                      ? null
                      : () => _confirmUserFollow(context, controller, item),
                  style: TextButton.styleFrom(
                    foregroundColor: _relationActionColor(item.relationStatus),
                    backgroundColor: _relationActionBackground(
                      item.relationStatus,
                    ),
                    minimumSize: Size.zero,
                    fixedSize: Size(
                      item.relationStatus == 'MUTUAL' ? 76 : 56,
                      28,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      busy
                          ? '处理中'
                          : switch (item.relationStatus) {
                              'FOLLOWING' => '已关注',
                              'FOLLOWED_BY' => '回关',
                              'MUTUAL' => '互相关注',
                              _ => '关注',
                            },
                      maxLines: 1,
                    ),
                  ),
                )
              : Text(
                  item.relationLabel,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
        ),
      ),
    );
  }

  Color _relationActionColor(String status) =>
      status == 'FOLLOWING' || status == 'MUTUAL'
      ? AppColors.inkMuted
      : Colors.white;

  Color _relationActionBackground(String status) =>
      status == 'FOLLOWING' || status == 'MUTUAL'
      ? AppColors.surfaceMuted
      : AppColors.brand;

  Future<void> _confirmUserFollow(
    BuildContext context,
    UserListController controller,
    UserBrief item,
  ) async {
    final follow = !item.followed;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(follow ? '确认关注' : '确认取消关注'),
        content: Text(
          follow ? '确认关注 ${item.nickname}？' : '确认取消关注 ${item.nickname}？',
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
    if (confirmed == true) await controller.toggleUser(item);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    UserListController controller,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('此操作无法撤销，确认继续吗？'),
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
    if (confirmed != true) return;
    final item = controller.state.items.firstWhere(
      (value) =>
          (value is UserFavoriteItem && value.contentId == id) ||
          (value is UserCommentItem && value.commentId == id),
      orElse: () => const UserContentItem(
        contentId: -1,
        contentType: 'UNKNOWN',
        title: '',
        likeCount: 0,
        commentCount: 0,
        favoriteCount: 0,
      ),
    );
    if (item is UserContentItem) return;
    await controller.removeItem(item);
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.error.withValues(alpha: .08),
    child: ListTile(
      leading: const Icon(Icons.info_outline_rounded, color: AppColors.error),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('重试')),
    ),
  );
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
