import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/media_url_resolver.dart';
import '../../../core/network/network_providers.dart';
import '../../../shared/design_system/app_design_tokens.dart';
import '../../../shared/widgets/app_entity_avatar.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/app_state_illustration.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';

const _notificationLightSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.white,
  systemNavigationBarContrastEnforced: false,
);

class MessagesHomePage extends ConsumerStatefulWidget {
  const MessagesHomePage({super.key});

  @override
  ConsumerState<MessagesHomePage> createState() => _MessagesHomePageState();
}

class _MessagesHomePageState extends ConsumerState<MessagesHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(notificationControllerProvider).loadInitial);
  }

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title暂未开放')));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(notificationControllerProvider);
    final state = controller.state;
    final unread =
        ref.watch(notificationUnreadCountProvider).value ??
        state.items.where((item) => !item.read).length;
    final latest = state.items.isEmpty ? null : state.items.first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _notificationLightSystemUiStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _MessageHeader(
                title: '消息',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('messages_search'),
                      tooltip: '搜索私信',
                      onPressed: () => _showUnavailable('私信搜索'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                    IconButton(
                      key: const ValueKey('messages_archive'),
                      tooltip: '会话管理',
                      onPressed: () => _showUnavailable('私信相关功能'),
                      icon: const Icon(Icons.inventory_2_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 2),
                    children: [
                      _InteractionEntry(
                        unread: unread,
                        latest: latest,
                        loading: state.status == NotificationLoadStatus.loading,
                        failed: state.status == NotificationLoadStatus.failure,
                        onRetry: controller.retry,
                        onTap: () => context.push('/messages/interactions'),
                      ),
                      if (state.message case final message?)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: Text(
                            message,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(ref.read(notificationControllerProvider).loadInitial);
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 320) {
      unawaited(ref.read(notificationControllerProvider).loadMore());
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageContext = context;
    final controller = ref.watch(notificationControllerProvider);
    final state = controller.state;
    final unread =
        ref.watch(notificationUnreadCountProvider).value ??
        state.items.where((item) => !item.read).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _notificationLightSystemUiStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _MessageHeader(
                title: '互动消息',
                onBack: () => context.pop(),
                trailing: unread > 0
                    ? IconButton(
                        key: const ValueKey('notification_read_all'),
                        tooltip: '全部已读',
                        onPressed: state.actionBusy
                            ? null
                            : controller.markAllRead,
                        icon: state.actionBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.done_all_rounded),
                      )
                    : null,
              ),
              Expanded(
                child: switch (state.status) {
                  NotificationLoadStatus.loading => const AppStateView(
                    kind: AppStateKind.loading,
                    title: '正在加载互动消息',
                    message: '正在获取最新互动通知…',
                  ),
                  NotificationLoadStatus.failure => AppStateView(
                    kind: AppStateKind.error,
                    title: '消息加载失败',
                    message: state.message ?? '请稍后重试。',
                    onRetry: controller.retry,
                  ),
                  NotificationLoadStatus.empty => RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 420,
                          child: const AppStateView(
                            kind: AppStateKind.empty,
                            title: '暂无互动消息',
                            message: '点赞、评论、回复和关注消息会显示在这里。',
                            illustration: AppStateIllustrationType.noMessages,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NotificationLoadStatus.ready => RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView.builder(
                      key: const PageStorageKey('notifications_list'),
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return _Footer(
                            loading: state.loadingMore,
                            hasMore: state.hasMore,
                            message: state.appendMessage,
                            onRetry: controller.loadMore,
                          );
                        }
                        final item = state.items[index];
                        return _NotificationRow(
                          item: item,
                          busy: state.readBusyIds.contains(item.notificationId),
                          onTap: () async {
                            final read = await controller.markRead(item);
                            if (!pageContext.mounted || !read) return;
                            final route = item.route;
                            if (route != null) {
                              pageContext.push(route);
                            } else if (!item.targetAvailable) {
                              ScaffoldMessenger.of(pageContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(content: Text('该消息目标暂不可用')),
                                );
                            }
                          },
                        );
                      },
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  const _MessageHeader({required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const ValueKey('notification_back'),
              tooltip: '返回',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
        Text(
          title,
          key: ValueKey('${title}_title'),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null)
          Align(alignment: Alignment.centerRight, child: trailing),
      ],
    ),
  );
}

class _InteractionEntry extends StatelessWidget {
  const _InteractionEntry({
    required this.unread,
    required this.latest,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.onTap,
  });

  final int unread;
  final AppNotification? latest;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = loading
        ? '正在加载互动消息…'
        : failed
        ? '加载失败，点击重试'
        : latest == null
        ? '暂无互动消息'
        : _homeSummary(latest!);
    return InkWell(
      key: const ValueKey('messages_interactions_entry'),
      onTap: failed ? onRetry : onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 20, 9),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: const ValueKey('messages_interaction_icon'),
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                if (unread > 0)
                  const Positioned(
                    right: -1,
                    top: -1,
                    child: CircleAvatar(
                      key: ValueKey('messages_unread_dot'),
                      radius: 6,
                      backgroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '互动消息',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _date(latest?.createTime),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({
    required this.item,
    required this.busy,
    required this.onTap,
  });

  final AppNotification item;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = resolveMediaUrl(
      ref.watch(appConfigProvider),
      item.actor?.avatarUrl,
    );
    final cover = resolveMediaUrl(
      ref.watch(appConfigProvider),
      item.targetPreview?.coverUrl,
    );
    final actorName = item.actor?.nickname;
    final action = _actionText(item);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final rowHeight = textScale > 1.1 ? 64.0 : 60.0;
    return Material(
      color: Colors.white,
      child: InkWell(
        key: ValueKey('notification_${item.notificationId}'),
        onTap: busy ? null : onTap,
        child: SizedBox(
          height: rowHeight,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppEntityAvatar(
                    key: ValueKey('notification_avatar_${item.notificationId}'),
                    identity: item.actor == null
                        ? 'notification:${item.rawType}'
                        : 'user:${item.actor!.userId}',
                    semanticLabel: '${item.actor?.nickname ?? '系统'}头像',
                    fallbackIcon: _icon(item.type),
                    fallbackText: item.actor?.nickname.characters.firstOrNull,
                    imageUrl: avatar,
                    size: 40,
                  ),
                  if (!item.read)
                    const Positioned(
                      right: -1,
                      top: -1,
                      child: CircleAvatar(
                        key: ValueKey('notification_unread_dot'),
                        radius: 5,
                        backgroundColor: AppColors.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (actorName != null) ...[
                      Text(
                        actorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            action,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _date(item.createTime),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (busy)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (cover != null)
                _Cover(
                  key: ValueKey('notification_cover_${item.notificationId}'),
                  url: cover,
                  label: item.targetPreview?.contentTitle ?? '内容封面',
                )
              else if (!item.targetAvailable)
                const SizedBox(
                  key: ValueKey('notification_unavailable'),
                  width: 40,
                  height: 40,
                )
              else
                SizedBox(
                  key: ValueKey(
                    'notification_cover_placeholder_${item.notificationId}',
                  ),
                  width: 40,
                  height: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.label, super.key});
  final String url;
  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      semanticLabel: label,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(Icons.image_not_supported_outlined),
        ),
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.hasMore,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final bool hasMore;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (message != null) {
      return TextButton(onPressed: onRetry, child: Text('$message 点击重试'));
    }
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(child: Text('继续上滑加载')),
    );
  }
}

IconData _icon(AppNotificationType type) => switch (type) {
  AppNotificationType.contentLiked ||
  AppNotificationType.commentLiked => Icons.favorite_rounded,
  AppNotificationType.contentCommented => Icons.chat_bubble_rounded,
  AppNotificationType.commentReplied => Icons.reply_rounded,
  AppNotificationType.userFollowed => Icons.person_add_rounded,
  AppNotificationType.system ||
  AppNotificationType.unknown => Icons.notifications_rounded,
};

String _homeSummary(AppNotification item) {
  if (item.content.trim().isNotEmpty) return item.content.trim();
  return '${item.actor?.nickname ?? '有人'}${_actionText(item)}';
}

String _actionText(AppNotification item) {
  final title = item.title.trim();
  if (title.length <= 4 && title.isNotEmpty) return title;
  return switch (item.type) {
    AppNotificationType.contentLiked => '赞了你的帖子',
    AppNotificationType.contentCommented => '评论了你的帖子',
    AppNotificationType.commentReplied => '回复了你的评论',
    AppNotificationType.commentLiked => '赞了你的评论',
    AppNotificationType.userFollowed => '关注了你',
    AppNotificationType.system ||
    AppNotificationType.unknown => title.isEmpty ? '发来一条互动消息' : title,
  };
}

String _date(DateTime? value) {
  if (value == null) return '';
  final delta = DateTime.now().difference(value);
  if (delta.inMinutes < 1) return '刚刚';
  if (delta.inMinutes < 60) return '${delta.inMinutes} 分钟前';
  if (delta.inHours < 24) return '${delta.inHours} 小时前';
  if (delta.inDays == 1) return '昨天';
  if (delta.inDays < 7) return '${delta.inDays}天前';
  return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
