import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../domain/comment.dart';
import '../controllers/comment_controller.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    required this.contentId,
    required this.currentUserId,
    this.onCommentCreated,
    super.key,
  });
  final int contentId;
  final int? currentUserId;
  final VoidCallback? onCommentCreated;
  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final input = TextEditingController();
  CommentItem? replyTo;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(commentControllerProvider(widget.contentId));
    final s = c.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('评论', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            SegmentedButton<CommentSort>(
              segments: const [
                ButtonSegment(value: CommentSort.hot, label: Text('热门')),
                ButtonSegment(value: CommentSort.latest, label: Text('最新')),
              ],
              selected: {s.sort},
              onSelectionChanged: (v) => unawaited(c.load(sort: v.first)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (s.status == CommentsStatus.loading)
          const Center(child: CircularProgressIndicator())
        else if (s.status == CommentsStatus.failure)
          _Message(text: s.message ?? '评论加载失败', onTap: c.load)
        else if (s.status == CommentsStatus.empty)
          const _Message(text: '还没有评论，来坐第一排吧')
        else
          for (final item in s.items)
            _CommentTile(
              item: item,
              currentUserId: widget.currentUserId,
              onReply: () {
                setState(() => replyTo = item);
              },
              onViewReplies: () => _showReplies(context, c, item),
              onLike: () => unawaited(c.toggleLike(item)),
              onDelete: () => _confirmDelete(context, c, item),
            ),
        if (s.hasMore)
          TextButton(
            onPressed: s.loadingMore ? null : c.more,
            child: Text(s.loadingMore ? '加载中…' : '加载更多评论'),
          ),
        if (s.message != null)
          Text(s.message!, style: const TextStyle(color: AppColors.error)),
        const Divider(),
        if (replyTo != null)
          Row(
            children: [
              Expanded(child: Text('回复 @${replyTo!.author.nickname}')),
              IconButton(
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
                controller: input,
                maxLength: 1000,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(hintText: '友善讨论，分享你的看法'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: s.submitting
                  ? null
                  : () async {
                      final ok = await c.submit(input.text, replyTo: replyTo);
                      if (ok && mounted) {
                        widget.onCommentCreated?.call();
                        input.clear();
                        setState(() => replyTo = null);
                      }
                    },
              child: Text(s.submitting ? '发送中' : '发送'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CommentController c,
    CommentItem item,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (yes == true) await c.delete(item);
  }

  Future<void> _showReplies(
    BuildContext context,
    CommentController controller,
    CommentItem root,
  ) async {
    final selected = await showModalBottomSheet<CommentItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: FutureBuilder<CommentPage>(
            future: controller.replies(root),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('回复加载失败，请关闭后重试'));
              }
              final replies = snapshot.data?.records ?? const [];
              return Column(
                children: [
                  ListTile(
                    title: Text('${root.author.nickname} 的回复'),
                    trailing: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: replies.length,
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return ListTile(
                          title: Text(reply.author.nickname),
                          subtitle: Text(
                            '${reply.replyToNickname == null ? '' : '回复 @${reply.replyToNickname}：'}${reply.content}',
                          ),
                          trailing: TextButton(
                            onPressed: () => Navigator.pop(context, reply),
                            child: const Text('回复'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => replyTo = selected);
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
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
                  TextButton(onPressed: onReply, child: const Text('回复')),
                  TextButton.icon(
                    onPressed: onLike,
                    icon: Icon(
                      item.liked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                    ),
                    label: Text('${item.likeCount}'),
                  ),
                  if (currentUserId != null &&
                      currentUserId == item.author.userId)
                    TextButton(onPressed: onDelete, child: const Text('删除')),
                ],
              ),
              if (item.replies.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: AppColors.surfaceMuted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final reply in item.replies)
                        Text(
                          '${reply.author.nickname}${reply.replyToNickname == null ? '' : ' 回复 @${reply.replyToNickname}'}：${reply.content}',
                        ),
                      if (item.replyCount > item.replies.length)
                        TextButton(
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

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(text),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('重试')),
      ],
    ),
  );
}
