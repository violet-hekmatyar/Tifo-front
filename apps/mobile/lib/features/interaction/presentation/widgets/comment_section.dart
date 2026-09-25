import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../domain/comment.dart';
import '../controllers/comment_controller.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    required this.contentId,
    required this.currentUserId,
    this.commentCount,
    this.targetType = 'CONTENT',
    this.onCommentCreated,
    this.onCommentsChanged,
    this.focusNode,
    this.inputAnchorKey,
    this.inputFocusNode,
    super.key,
  });
  final int contentId;
  final int? currentUserId;
  final int? commentCount;
  final String targetType;
  final VoidCallback? onCommentCreated;
  final VoidCallback? onCommentsChanged;
  final FocusNode? focusNode;
  final GlobalKey? inputAnchorKey;
  // Kept for the existing detail-page call site while the focus contract is
  // migrated to the clearer focusNode name.
  final FocusNode? inputFocusNode;
  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final input = TextEditingController();
  CommentItem? replyTo;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  late final GlobalKey _inputAnchorKey;

  @override
  void initState() {
    super.initState();
    final suppliedFocus = widget.focusNode ?? widget.inputFocusNode;
    _ownsFocusNode = suppliedFocus == null;
    _focusNode = suppliedFocus ?? FocusNode();
    _inputAnchorKey = widget.inputAnchorKey ?? GlobalKey();
  }

  @override
  void dispose() {
    input.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      widget.targetType == 'PLAYER_RATING'
          ? playerRatingCommentControllerProvider(widget.contentId)
          : commentControllerProvider(widget.contentId),
    );
    final state = controller.state;
    return Column(
      key: const ValueKey('comment_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, controller, state),
        const SizedBox(height: AppSpacing.md),
        _buildComments(context, controller, state),
        if (state.hasMore)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const ValueKey('comments_load_more'),
              onPressed: state.loadingMore ? null : controller.more,
              child: Text(state.loadingMore ? '加载中…' : '加载更多评论'),
            ),
          ),
        if (state.message != null && state.moreFailure)
          _InlineError(
            message: state.message!,
            actionLabel: '重试加载',
            onTap: controller.more,
          ),
        if (state.message != null &&
            !state.moreFailure &&
            state.status != CommentsStatus.failure)
          _InlineError(message: state.message!),
        const Divider(),
        _buildComposer(context, controller, state),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CommentController controller,
    CommentsState state,
  ) => Row(
    children: [
      Expanded(
        child: Text(
          key: const ValueKey('comment_title'),
          widget.commentCount == null ? '评论' : '评论 ${widget.commentCount}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      SegmentedButton<CommentSort>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: CommentSort.hot, label: Text('热门')),
          ButtonSegment(value: CommentSort.latest, label: Text('最新')),
        ],
        selected: {state.sort},
        onSelectionChanged: (value) =>
            unawaited(controller.load(sort: value.first)),
      ),
    ],
  );

  Widget _buildComments(
    BuildContext context,
    CommentController controller,
    CommentsState state,
  ) {
    if (state.status == CommentsStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == CommentsStatus.failure && state.items.isEmpty) {
      return _Message(
        text: state.message ?? '评论加载失败',
        onTap: () => unawaited(controller.load()),
      );
    }
    if (state.status == CommentsStatus.empty && state.items.isEmpty) {
      return const _Message(text: '还没有评论，来坐第一排吧');
    }

    return Column(
      children: [
        for (final item in state.items)
          _CommentTile(
            key: ValueKey('comment_${item.commentId}'),
            item: item,
            currentUserId: widget.currentUserId,
            onReply: () {
              setState(() => replyTo = item);
              _scheduleFocus();
            },
            onViewReplies: () => _showReplies(context, controller, item),
            onLike: () => unawaited(controller.toggleLike(item)),
            onDelete: () => _confirmDelete(context, controller, item),
          ),
        if (!state.hasMore) const Text('已经到底了'),
      ],
    );
  }

  Widget _buildComposer(
    BuildContext context,
    CommentController controller,
    CommentsState state,
  ) => Column(
    key: _inputAnchorKey,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (replyTo case final target?)
        Row(
          key: const ValueKey('reply_target'),
          children: [
            Expanded(child: Text('回复 @${target.author.nickname}')),
            IconButton(
              key: const ValueKey('cancel_reply'),
              tooltip: '取消回复',
              onPressed: () => setState(() => replyTo = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('comment_input'),
              controller: input,
              focusNode: _focusNode,
              maxLength: 1000,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(hintText: '友善讨论，分享你的看法'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            key: const ValueKey('comment_submit'),
            onPressed: state.submitting
                ? null
                : () async {
                    final target = replyTo;
                    final ok = await controller.submit(
                      input.text,
                      replyTo: target,
                    );
                    if (!mounted || !ok) return;
                    input.clear();
                    setState(() => replyTo = null);
                    widget.onCommentCreated?.call();
                    widget.onCommentsChanged?.call();
                  },
            child: Text(state.submitting ? '发送中' : '发送'),
          ),
        ],
      ),
    ],
  );

  void _scheduleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_focusInput());
    });
  }

  Future<void> _focusInput() async {
    final target = _inputAnchorKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: .2,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    if (mounted) _focusNode.requestFocus();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CommentController controller,
    CommentItem item,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            key: const ValueKey('cancel_delete'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (await controller.delete(item)) widget.onCommentsChanged?.call();
  }

  Future<void> _showReplies(
    BuildContext context,
    CommentController controller,
    CommentItem root,
  ) async {
    final selected = await showModalBottomSheet<CommentItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _RepliesSheet(controller: controller, root: root),
    );
    if (selected == null || !mounted) return;
    setState(() => replyTo = selected);
    _scheduleFocus();
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required super.key,
    required this.item,
    required this.currentUserId,
    required this.onReply,
    required this.onViewReplies,
    required this.onLike,
    required this.onDelete,
  });
  final CommentItem item;
  final int? currentUserId;
  final VoidCallback onReply, onLike, onDelete;
  final VoidCallback onViewReplies;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppEntityAvatar(
          identity: 'user:${item.author.userId ?? item.author.nickname}',
          semanticLabel: '${item.author.nickname}头像',
          fallbackIcon: Icons.person_outline_rounded,
          fallbackText: item.author.nickname.characters.first,
          size: 36,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.author.nickname,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (item.replyToNickname != null)
                Text(
                  '回复 @${item.replyToNickname}',
                  style: const TextStyle(color: AppColors.brand),
                ),
              Text(item.content),
              Wrap(
                children: [
                  TextButton(
                    key: ValueKey('reply_${item.commentId}'),
                    onPressed: onReply,
                    child: const Text('回复'),
                  ),
                  TextButton.icon(
                    key: ValueKey('like_${item.commentId}'),
                    onPressed: onLike,
                    icon: Icon(
                      item.liked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                    ),
                    label: Text('${item.likeCount}'),
                  ),
                  if (currentUserId != null &&
                      currentUserId == item.author.userId)
                    TextButton(
                      key: ValueKey('delete_${item.commentId}'),
                      onPressed: onDelete,
                      child: const Text('删除'),
                    ),
                ],
              ),
              if (item.replyCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final reply in item.replies)
                        Text(
                          '${reply.author.nickname}${reply.replyToNickname == null ? '' : ' 回复 @${reply.replyToNickname}'}：${reply.content}',
                        ),
                      if (item.replyCount > item.replies.length)
                        TextButton(
                          key: ValueKey('view_replies_${item.commentId}'),
                          onPressed: onViewReplies,
                          child: Text('查看全部 ${item.replyCount} 条回复'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RepliesSheet extends StatefulWidget {
  const _RepliesSheet({required this.controller, required this.root});

  final CommentController controller;
  final CommentItem root;

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

enum _RepliesStatus { loading, ready, empty, failure }

class _RepliesSheetState extends State<_RepliesSheet> {
  final _scrollController = ScrollController();
  List<CommentItem> _items = const [];
  _RepliesStatus _status = _RepliesStatus.loading;
  String? _message;
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _requestVersion++;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || !_hasMore)) return;
    final version = ++_requestVersion;
    final page = more ? _page + 1 : 1;
    if (more) {
      setState(() {
        _loadingMore = true;
        _message = null;
      });
    } else {
      setState(() {
        _status = _RepliesStatus.loading;
        _message = null;
      });
    }
    try {
      final result = await widget.controller.replies(widget.root, page: page);
      if (!mounted || version != _requestVersion) return;
      final byId = <int, CommentItem>{
        for (final item in (more ? _items : const <CommentItem>[]))
          item.commentId: item,
      };
      for (final item in result.records) {
        byId[item.commentId] = item;
      }
      final items = byId.values.toList(growable: false);
      setState(() {
        _items = items;
        _page = result.pageNum;
        _hasMore = result.hasMore;
        _loadingMore = false;
        _status = items.isEmpty ? _RepliesStatus.empty : _RepliesStatus.ready;
      });
      if (_hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_hasMore || _loadingMore) return;
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent == 0) {
            unawaited(_load(more: true));
          }
        });
      }
    } on AppNetworkException catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _loadingMore = false;
        _message = e.message;
        if (!more) _status = _RepliesStatus.failure;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) {
      unawaited(_load(more: true));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    '回复 ${widget.root.replyCount}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_replies'),
                  tooltip: '关闭回复',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.root.author.nickname),
                Text(widget.root.content),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    if (_status == _RepliesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_status == _RepliesStatus.failure) {
      return _Message(
        text: _message ?? '回复加载失败',
        onTap: () => unawaited(_load()),
        actionLabel: '重试',
      );
    }
    if (_status == _RepliesStatus.empty) {
      return const _Message(text: '还没有回复');
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount:
                _items.length + (_loadingMore || _message != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return _InlineError(
                  message: _message ?? '加载中…',
                  actionLabel: _message == null ? null : '重试加载',
                  onTap: _message == null ? null : () => _load(more: true),
                );
              }
              final reply = _items[index];
              return ListTile(
                key: ValueKey('sheet_reply_${reply.commentId}'),
                contentPadding: EdgeInsets.zero,
                title: Text(reply.author.nickname),
                subtitle: Text(
                  '${reply.replyToNickname == null ? '' : '回复 @${reply.replyToNickname}：'}${reply.content}',
                ),
                trailing: TextButton(
                  key: ValueKey('sheet_reply_action_${reply.commentId}'),
                  onPressed: () => Navigator.pop(context, reply),
                  child: const Text('回复'),
                ),
              );
            },
          ),
        ),
        if (!_hasMore) const Text('已经到底了'),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onTap, this.actionLabel = '重试'});
  final String text;
  final VoidCallback? onTap;
  final String actionLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(text),
        if (onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.actionLabel, this.onTap});

  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(message, style: const TextStyle(color: AppColors.error)),
      ),
      if (actionLabel != null && onTap != null)
        TextButton(onPressed: onTap, child: Text(actionLabel!)),
    ],
  );
}
