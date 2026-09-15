import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../interaction/presentation/widgets/comment_section.dart';
import '../../../feed/presentation/controllers/feed_refresh_coordinator.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../domain/content_detail.dart';
import '../controllers/content_detail_controller.dart';
import '../widgets/content_media_gallery.dart';

class ContentDetailPage extends ConsumerStatefulWidget {
  const ContentDetailPage({
    required this.contentId,
    this.refreshFeedOnExit = false,
    this.recommendationSource,
    super.key,
  });
  final int contentId;
  final bool refreshFeedOnExit;
  final RecommendationSourceContext? recommendationSource;

  @override
  ConsumerState<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends ConsumerState<ContentDetailPage> {
  bool _returning = false;
  bool _detailReported = false;
  final _commentInputAnchorKey = GlobalKey();
  final _commentInputFocus = FocusNode();
  final _detailScrollController = ScrollController();

  @override
  void dispose() {
    _commentInputFocus.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  Future<void> _focusCommentInput() async {
    final target = _commentInputAnchorKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: .2,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else if (_detailScrollController.hasClients) {
      await _detailScrollController.animateTo(
        _detailScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentTarget = _commentInputAnchorKey.currentContext;
      if (currentTarget != null) {
        Scrollable.ensureVisible(
          currentTarget,
          alignment: .2,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      _commentInputFocus.requestFocus();
    });
  }

  void _report(RecommendationBehaviorType behavior) => ref
      .read(recommendationBehaviorDispatcherProvider)
      .record(behavior, widget.recommendationSource);

  void _returnToPreviousPage() {
    if (_returning) return;
    _returning = true;
    if (widget.refreshFeedOnExit) {
      requestPublishedContentFeedRefresh(ref, widget.contentId);
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/home');
    }
  }

  Future<void> _showShareSheet() async {
    final copied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('分享内容', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_rounded),
                title: const Text('复制链接'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '/contents/${widget.contentId}'),
                  );
                  if (context.mounted) Navigator.of(context).pop(true);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.close_rounded),
                title: const Text('取消'),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    if (copied == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('链接已复制')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(contentDetailControllerProvider(widget.contentId));
    final s = c.state;
    if (s.status == DetailStatus.ready && !_detailReported) {
      _detailReported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report(RecommendationBehaviorType.detail);
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToPreviousPage();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey('content_detail_back'),
            tooltip: '返回',
            onPressed: _returnToPreviousPage,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('内容详情'),
          actions: [
            IconButton(
              key: const ValueKey('content_detail_share'),
              tooltip: '分享',
              onPressed: s.status == DetailStatus.ready
                  ? _showShareSheet
                  : null,
              icon: const Icon(Icons.share_outlined),
            ),
            if (s.detail case final detail?
                when s.status == DetailStatus.ready &&
                    detail.contentType == 'ARTICLE' &&
                    (detail.author.userId ==
                            ref.watch(authControllerProvider).state.user?.id ||
                        ref
                                .watch(authControllerProvider)
                                .state
                                .user
                                ?.roleType ==
                            'ADMIN'))
              IconButton(
                key: const ValueKey('article_edit'),
                tooltip: '编辑文章',
                onPressed: () async {
                  final updated = await context.push<bool>(
                    '/contents/${detail.contentId}/edit',
                  );
                  if (updated == true) await c.load();
                },
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: switch (s.status) {
          DetailStatus.loading => const AppStateView(
            kind: AppStateKind.loading,
            title: '正在加载内容',
            message: '正在读取正文与互动状态…',
          ),
          DetailStatus.notFound => AppStateView(
            kind: AppStateKind.empty,
            title: s.message ?? '内容不存在或已下架',
            message: '请返回首页选择其他内容。',
          ),
          DetailStatus.failure => AppStateView(
            kind: AppStateKind.error,
            title: '内容加载失败',
            message: s.message ?? '请检查网络后重试。',
            onRetry: c.load,
          ),
          DetailStatus.ready => _DetailBody(
            controller: c,
            currentUserId: ref.watch(authControllerProvider).state.user?.id,
            recommendationSource: widget.recommendationSource,
            commentInputAnchorKey: _commentInputAnchorKey,
            commentInputFocus: _commentInputFocus,
            scrollController: _detailScrollController,
          ),
        },
        bottomNavigationBar: s.status == DetailStatus.ready
            ? _DetailActionBar(
                detail: s.detail!,
                controller: c,
                onComment: _focusCommentInput,
                recommendationSource: widget.recommendationSource,
              )
            : null,
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.controller,
    required this.currentUserId,
    required this.recommendationSource,
    required this.commentInputAnchorKey,
    required this.commentInputFocus,
    required this.scrollController,
  });
  final ContentDetailController controller;
  final int? currentUserId;
  final RecommendationSourceContext? recommendationSource;
  final GlobalKey commentInputAnchorKey;
  final FocusNode commentInputFocus;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = controller.state.detail!;
    final config = ref.watch(appConfigProvider);
    final urls = d.media
        .where((m) => m.mediaType == 'IMAGE')
        .map((m) => resolveMediaUrl(config, m.mediaUrl))
        .whereType<String>()
        .toList();
    final blockMediaUrls = <ArticleBlock, String>{};
    for (final block in d.blocks) {
      final url = resolveMediaUrl(config, block.mediaUrl);
      if (url != null) blockMediaUrls[block] = url;
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl + 72,
      ),
      children: [
        Text(
          d.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: d.author.userId == null
              ? null
              : () => context.push('/users/${d.author.userId}'),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Row(
            children: [
              AppEntityAvatar(
                identity: 'user:${d.author.userId ?? d.author.nickname}',
                semanticLabel: '${d.author.nickname}头像',
                fallbackIcon: Icons.person_outline_rounded,
                fallbackText: d.author.nickname.characters.first,
                imageUrl: resolveMediaUrl(config, d.author.avatarUrl),
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${d.author.nickname}${d.author.verified ? ' · 已认证' : ''}',
                ),
              ),
              Text('${d.viewCount} 阅读'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (d.contentType != 'ARTICLE') ...[
          if (d.body.isNotEmpty)
            Text(
              d.body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          const SizedBox(height: AppSpacing.md),
          ContentMediaGallery(mediaUrls: urls),
        ] else
          ArticleBody(
            detail: d,
            mediaUrls: urls,
            blockMediaUrls: blockMediaUrls,
          ),
        if (d.relations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final r in d.relations)
                ActionChip(
                  label: Text('# ${r.name}'),
                  onPressed: switch (r.type) {
                    'TEAM' => () => context.push('/teams/${r.id}'),
                    'PLAYER' => () => context.push('/players/${r.id}'),
                    'MATCH' => () => context.push('/matches/${r.id}'),
                    _ => null,
                  },
                ),
            ],
          ),
        ],
        if (controller.state.message != null)
          Text(
            controller.state.message!,
            style: const TextStyle(color: AppColors.error),
          ),
        const SizedBox(height: AppSpacing.xl),
        CommentSection(
          inputFocusNode: commentInputFocus,
          inputAnchorKey: commentInputAnchorKey,
          contentId: d.contentId,
          currentUserId: currentUserId,
          commentCount: d.commentCount,
          onCommentCreated: () => ref
              .read(recommendationBehaviorDispatcherProvider)
              .record(RecommendationBehaviorType.comment, recommendationSource),
          onCommentsChanged: () => unawaited(controller.refreshCommentCount()),
        ),
      ],
    );
  }
}

class _DetailActionBar extends ConsumerWidget {
  const _DetailActionBar({
    required this.detail,
    required this.controller,
    required this.onComment,
    required this.recommendationSource,
  });

  final ContentDetail detail;
  final ContentDetailController controller;
  final VoidCallback onComment;
  final RecommendationSourceContext? recommendationSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: const ValueKey('content_detail_comment_action'),
                  onPressed: onComment,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text('${detail.commentCount}'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  key: const ValueKey('content_detail_like_action'),
                  onPressed: controller.state.likeBusy
                      ? null
                      : () async {
                          if (await controller.toggleLike()) {
                            ref
                                .read(recommendationBehaviorDispatcherProvider)
                                .record(
                                  RecommendationBehaviorType.like,
                                  recommendationSource,
                                );
                          }
                        },
                  icon: Icon(
                    detail.liked ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text('${detail.likeCount}'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  key: const ValueKey('content_detail_favorite_action'),
                  onPressed: controller.state.favoriteBusy
                      ? null
                      : () async {
                          if (await controller.toggleFavorite()) {
                            ref
                                .read(recommendationBehaviorDispatcherProvider)
                                .record(
                                  RecommendationBehaviorType.favorite,
                                  recommendationSource,
                                );
                          }
                        },
                  icon: Icon(
                    detail.favorited ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: Text('${detail.favoriteCount}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
