import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../interaction/domain/comment.dart';
import '../../../interaction/presentation/controllers/comment_controller.dart';

class ContentCommentsSheet extends ConsumerStatefulWidget {
  const ContentCommentsSheet({
    required this.contentId,
    required this.commentCount,
    required this.currentUserId,
    this.onCommentsChanged,
    this.onShare,
    super.key,
  });

  final int contentId;
  final int commentCount;
  final int? currentUserId;
  final VoidCallback? onCommentsChanged;
  final VoidCallback? onShare;

  @override
  ConsumerState<ContentCommentsSheet> createState() =>
      _ContentCommentsSheetState();
}

class _ContentCommentsSheetState extends ConsumerState<ContentCommentsSheet> {
  late int _commentCount = widget.commentCount;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(commentControllerProvider(widget.contentId));
    final config = ref.watch(appConfigProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('content_comments_back'),
                    tooltip: '返回',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '评论（$_commentCount）',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('content_comments_share'),
                    tooltip: '分享',
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _CommentsBody(
                state: controller.state,
                config: config,
                currentUserId: widget.currentUserId,
                onRefresh: () => controller.load(sort: controller.state.sort),
                onSort: (sort) => controller.load(sort: sort),
                onLike: (item) => unawaited(controller.toggleLike(item)),
                onDelete: (item) async {
                  if (await controller.delete(item)) {
                    setState(() => _commentCount--);
                    widget.onCommentsChanged?.call();
                  }
                },
                onReply: (item) => _openComposer(context, controller, item),
                onViewReplies: (item) =>
                    _openReplies(context, controller, item, config),
                onMore: controller.more,
              ),
            ),
            _CommentInputCapsule(
              key: const ValueKey('content_comments_input_capsule'),
              onTap: () => _openComposer(context, controller, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComposer(
    BuildContext context,
    CommentController controller,
    CommentItem? replyTo,
  ) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) =>
          _ContentComposerSheet(controller: controller, replyTo: replyTo),
    );
    if (submitted == true && mounted) {
      setState(() => _commentCount++);
      widget.onCommentsChanged?.call();
    }
  }

  Future<void> _openReplies(
    BuildContext context,
    CommentController controller,
    CommentItem root,
    AppConfig config,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _ContentRepliesSheet(
        controller: controller,
        root: root,
        config: config,
        currentUserId: widget.currentUserId,
        onReply: (reply) => _openComposer(context, controller, reply),
      ),
    );
  }
}

class _CommentsBody extends StatelessWidget {
  const _CommentsBody({
    required this.state,
    required this.config,
    required this.currentUserId,
    required this.onRefresh,
    required this.onSort,
    required this.onLike,
    required this.onDelete,
    required this.onReply,
    required this.onViewReplies,
    required this.onMore,
  });

  final CommentsState state;
  final AppConfig config;
  final int? currentUserId;
  final Future<void> Function() onRefresh;
  final ValueChanged<CommentSort> onSort;
  final ValueChanged<CommentItem> onLike;
  final Future<void> Function(CommentItem) onDelete;
  final ValueChanged<CommentItem> onReply;
  final ValueChanged<CommentItem> onViewReplies;
  final Future<void> Function() onMore;

  @override
  Widget build(BuildContext context) {
    if (state.status == CommentsStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == CommentsStatus.failure && state.items.isEmpty) {
      return _InteractionMessage(
        text: state.message ?? '评论加载失败',
        action: onRefresh,
      );
    }
    if (state.status == CommentsStatus.empty && state.items.isEmpty) {
      return const _InteractionMessage(text: '还没有评论，来坐第一排吧');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        itemCount:
            state.items.length + (state.hasMore || state.moreFailure ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return state.moreFailure
                ? _InlineInteractionError(
                    text: state.message ?? '加载失败',
                    onRetry: onMore,
                  )
                : TextButton(
                    key: const ValueKey('content_comments_load_more'),
                    onPressed: onMore,
                    child: Text(state.loadingMore ? '加载中…' : '加载更多评论'),
                  );
          }
          final item = state.items[index];
          return _ContentCommentTile(
            item: item,
            config: config,
            currentUserId: currentUserId,
            onLike: () => onLike(item),
            onDelete: () => onDelete(item),
            onReply: () => onReply(item),
            onViewReplies: () => onViewReplies(item),
          );
        },
      ),
    );
  }
}

class _ContentCommentTile extends StatelessWidget {
  const _ContentCommentTile({
    required this.item,
    required this.config,
    required this.currentUserId,
    required this.onLike,
    required this.onDelete,
    required this.onReply,
    required this.onViewReplies,
  });

  final CommentItem item;
  final AppConfig config;
  final int? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final VoidCallback onViewReplies;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppEntityAvatar(
            identity: 'user:${item.author.userId ?? item.author.nickname}',
            semanticLabel: '${item.author.nickname}头像',
            fallbackIcon: Icons.person_outline_rounded,
            fallbackText: item.author.nickname.characters.first,
            imageUrl: resolveMediaUrl(config, item.author.avatarUrl),
            size: 42,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.author.nickname,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _commentTime(item.createTime),
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          TextButton.icon(
            key: ValueKey('content_comment_like_${item.commentId}'),
            onPressed: onLike,
            icon: Icon(
              item.liked ? Icons.favorite : Icons.favorite_border,
              color: item.liked ? AppColors.error : AppColors.inkMuted,
              size: 19,
            ),
            label: Text('${item.likeCount}'),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 50, top: AppSpacing.xs),
        child: Text(item.content, style: Theme.of(context).textTheme.bodyLarge),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 50),
        child: Row(
          children: [
            TextButton(
              key: ValueKey('content_comment_reply_${item.commentId}'),
              onPressed: onReply,
              child: const Text('回复'),
            ),
            if (currentUserId != null && currentUserId == item.author.userId)
              TextButton(
                key: ValueKey('content_comment_delete_${item.commentId}'),
                onPressed: onDelete,
                child: const Text('删除'),
              ),
          ],
        ),
      ),
      if (item.replyCount > 0)
        Container(
          key: ValueKey('content_reply_preview_${item.commentId}'),
          width: double.infinity,
          margin: const EdgeInsets.only(left: 50, top: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final reply in item.replies.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('${reply.author.nickname}：${reply.content}'),
                ),
              TextButton(
                key: ValueKey('content_view_replies_${item.commentId}'),
                onPressed: onViewReplies,
                child: Text('查看全部 ${item.replyCount} 条回复'),
              ),
            ],
          ),
        ),
    ],
  );
}

class _ContentRepliesSheet extends ConsumerStatefulWidget {
  const _ContentRepliesSheet({
    required this.controller,
    required this.root,
    required this.config,
    required this.currentUserId,
    required this.onReply,
  });
  final CommentController controller;
  final CommentItem root;
  final AppConfig config;
  final int? currentUserId;
  final ValueChanged<CommentItem> onReply;

  @override
  ConsumerState<_ContentRepliesSheet> createState() =>
      _ContentRepliesSheetState();
}

class _ContentRepliesSheetState extends ConsumerState<_ContentRepliesSheet> {
  final _scroll = ScrollController();
  List<CommentItem> _items = const [];
  String? _message;
  bool _loading = true;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || !_hasMore)) return;
    setState(() {
      _message = null;
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });
    try {
      final result = await widget.controller.replies(
        widget.root,
        page: more ? _page + 1 : 1,
      );
      if (!mounted) return;
      final byId = <int, CommentItem>{
        for (final item in (more ? _items : const <CommentItem>[]))
          item.commentId: item,
      };
      for (final item in result.records) {
        byId[item.commentId] = item;
      }
      setState(() {
        _items = byId.values.toList(growable: false);
        _page = result.pageNum;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on AppNetworkException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _message = error.message;
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 160) unawaited(_load(more: true));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .92,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('content_replies_back'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    '回复（${widget.root.replyCount}）',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_content_replies'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntityAvatar(
                  identity:
                      'user:${widget.root.author.userId ?? widget.root.author.nickname}',
                  semanticLabel: '${widget.root.author.nickname}头像',
                  fallbackIcon: Icons.person_outline_rounded,
                  fallbackText: widget.root.author.nickname.characters.first,
                  imageUrl: resolveMediaUrl(
                    widget.config,
                    widget.root.author.avatarUrl,
                  ),
                  size: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.root.author.nickname}\n${widget.root.content}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context)),
          _CommentInputCapsule(
            key: const ValueKey('content_replies_input_capsule'),
            onTap: () => widget.onReply(widget.root),
          ),
        ],
      ),
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_message != null && _items.isEmpty) {
      return _InteractionMessage(text: _message!, action: _load);
    }
    if (_items.isEmpty) return const _InteractionMessage(text: '还没有回复');
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length + (_hasMore || _message != null ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return _message == null
              ? const Center(child: Text('已经到底了'))
              : _InlineInteractionError(
                  text: _message!,
                  onRetry: () => _load(more: true),
                );
        }
        final reply = _items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppEntityAvatar(
              identity: 'user:${reply.author.userId ?? reply.author.nickname}',
              semanticLabel: '${reply.author.nickname}头像',
              fallbackIcon: Icons.person_outline_rounded,
              fallbackText: reply.author.nickname.characters.first,
              imageUrl: resolveMediaUrl(widget.config, reply.author.avatarUrl),
              size: 36,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.author.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _commentTime(reply.createTime),
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(reply.content),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: ValueKey('content_reply_action_${reply.commentId}'),
                      onPressed: () => widget.onReply(reply),
                      child: const Text('回复'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContentComposerSheet extends ConsumerStatefulWidget {
  const _ContentComposerSheet({required this.controller, this.replyTo});
  final CommentController controller;
  final CommentItem? replyTo;

  @override
  ConsumerState<_ContentComposerSheet> createState() =>
      _ContentComposerSheetState();
}

class _ContentComposerSheetState extends ConsumerState<_ContentComposerSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.replyTo;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  target == null ? '发表评论' : '回复 @${target.author.nickname}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const ValueKey('close_content_composer'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (target != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.surfaceMuted,
              child: Text(
                target.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('content_comment_input'),
            controller: _input,
            focusNode: _focus,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: target == null
                  ? '快来发布你的评论吧'
                  : '回复 @${target.author.nickname}',
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (widget.controller.state.message != null)
            Text(
              widget.controller.state.message!,
              style: const TextStyle(color: AppColors.error),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('content_comment_submit'),
              onPressed: widget.controller.state.submitting ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(widget.controller.state.submitting ? '发送中' : '发送'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await widget.controller.submit(
      _input.text,
      replyTo: widget.replyTo,
    );
    if (!mounted) return;
    if (ok) Navigator.pop(context, true);
  }
}

class _CommentInputCapsule extends StatelessWidget {
  const _CommentInputCapsule({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          key: const ValueKey('content_comments_input'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.inkMuted),
              SizedBox(width: AppSpacing.sm),
              Text('快来发布你的评论吧', style: TextStyle(color: AppColors.inkMuted)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InteractionMessage extends StatelessWidget {
  const _InteractionMessage({required this.text, this.action});
  final String text;
  final Future<void> Function()? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (action != null)
          TextButton(onPressed: action, child: const Text('重试')),
      ],
    ),
  );
}

class _InlineInteractionError extends StatelessWidget {
  const _InlineInteractionError({required this.text, required this.onRetry});
  final String text;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(text, style: const TextStyle(color: AppColors.error)),
      ),
      TextButton(onPressed: onRetry, child: const Text('重试')),
    ],
  );
}

String _commentTime(DateTime? value) {
  if (value == null) return '刚刚';
  final local = value.toLocal();
  return '${local.month}月${local.day}日 ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
