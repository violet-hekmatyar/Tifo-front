import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/media_url_resolver.dart';
import '../../../core/network/network_providers.dart';
import '../../../shared/design_system/app_design_tokens.dart';
import '../../../shared/widgets/app_entity_avatar.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';

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
    if (_scroll.position.extentAfter < 320) {
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
    final controller = ref.watch(notificationControllerProvider);
    final state = controller.state;
    final unread =
        ref.watch(notificationUnreadCountProvider).value ??
        state.items.where((item) => !item.read).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(unread > 0 ? '消息（$unread 条未读）' : '消息'),
        actions: [
          TextButton(
            key: const ValueKey('notification_read_all'),
            onPressed: unread == 0 || state.actionBusy
                ? null
                : controller.markAllRead,
            child: Text(state.actionBusy ? '处理中…' : '全部已读'),
          ),
        ],
      ),
      body: switch (state.status) {
        NotificationLoadStatus.loading => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载消息',
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
            children: const [
              SizedBox(
                height: 420,
                child: AppStateView(
                  kind: AppStateKind.empty,
                  title: '暂无互动通知',
                  message: '点赞、评论、回复和关注消息会显示在这里。',
                ),
              ),
            ],
          ),
        ),
        NotificationLoadStatus.ready => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            key: const PageStorageKey('notifications_list'),
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: state.items.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return _Footer(
                  loading: state.loadingMore,
                  hasMore: state.hasMore,
                  message: state.appendMessage ?? state.message,
                  onRetry: controller.loadMore,
                );
              }
              final item = state.items[index];
              return _NotificationTile(
                item: item,
                onTap: () async {
                  final read = await controller.markRead(item);
                  if (!context.mounted || !read) return;
                  final route = item.route;
                  if (route != null) context.push(route);
                },
              );
            },
          ),
        ),
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = resolveMediaUrl(
      ref.watch(appConfigProvider),
      item.actor?.avatarUrl,
    );
    final preview =
        item.targetPreview?.commentExcerpt ?? item.targetPreview?.contentTitle;
    return Material(
      color: item.read
          ? AppColors.surface
          : AppColors.brand.withValues(alpha: 0.06),
      child: ListTile(
        key: ValueKey('notification_${item.notificationId}'),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            AppEntityAvatar(
              identity: item.actor == null
                  ? 'notification:${item.rawType}'
                  : 'user:${item.actor!.userId}',
              semanticLabel: '${item.actor?.nickname ?? '系统'}头像',
              fallbackIcon: _icon(item.type),
              fallbackText: item.actor?.nickname.characters.firstOrNull,
              imageUrl: avatar,
              size: 44,
            ),
            if (!item.read)
              const Positioned(
                right: -2,
                top: -2,
                child: CircleAvatar(
                  key: ValueKey('notification_unread_dot'),
                  radius: 5,
                  backgroundColor: AppColors.error,
                ),
              ),
          ],
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (preview != null && preview.trim().isNotEmpty)
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            Row(
              children: [
                Text(
                  _date(item.createTime),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (!item.targetAvailable) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    '目标已不可用',
                    key: ValueKey('notification_unavailable'),
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: item.route == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(child: Text(hasMore ? '继续上滑加载' : '没有更多消息了')),
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

String _date(DateTime? value) => value == null
    ? ''
    : '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
