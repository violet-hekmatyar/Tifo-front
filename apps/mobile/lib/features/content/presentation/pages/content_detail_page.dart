import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../feed/presentation/controllers/feed_refresh_coordinator.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../../user_center/presentation/controllers/user_center_controllers.dart';
import '../../domain/content_detail.dart';
import '../controllers/content_detail_controller.dart';
import 'content_interaction_page.dart';
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
  final _detailScrollController = ScrollController();

  @override
  void dispose() {
    _detailScrollController.dispose();
    super.dispose();
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

  Future<void> _showComments(ContentDetailController controller) async {
    final detail = controller.state.detail;
    if (detail == null) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => Scaffold(
          backgroundColor: AppColors.surface,
          body: ContentCommentsSheet(
            contentId: detail.contentId,
            commentCount: detail.commentCount,
            currentUserId: ref.read(authControllerProvider).state.user?.id,
            onCommentsChanged: () =>
                unawaited(controller.refreshCommentCount()),
            onShare: _showShareSheet,
          ),
        ),
      ),
    );
  }

  Future<void> _showShareSheet() async {
    final detail = ref
        .read(contentDetailControllerProvider(widget.contentId))
        .state
        .detail;
    final title = detail?.title ?? '南看台内容';
    final copied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: false,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '分享至',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('content_share_close'),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
                children: [
                  _ShareAction(
                    icon: Icons.link_rounded,
                    label: '复制链接',
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: '/contents/${widget.contentId}'),
                      );
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                  ),
                  _ShareAction(
                    icon: Icons.title_rounded,
                    label: '复制标题',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: title));
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                  ),
                  _ShareAction(
                    icon: Icons.ios_share_rounded,
                    label: '更多',
                    onTap: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: '$title\n/contents/${widget.contentId}',
                          subject: title,
                        ),
                      );
                      if (context.mounted) Navigator.of(context).pop(false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  key: const ValueKey('content_share_cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
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
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            key: const ValueKey('content_detail_back'),
            tooltip: '返回',
            onPressed: _returnToPreviousPage,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('南看台'),
          actions: [
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
            scrollController: _detailScrollController,
          ),
        },
        bottomNavigationBar: s.status == DetailStatus.ready
            ? _DetailActionBar(
                detail: s.detail!,
                controller: c,
                onComment: () => _showComments(c),
                onShare: _showShareSheet,
                recommendationSource: widget.recommendationSource,
              )
            : null,
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.controller, required this.scrollController});
  final ContentDetailController controller;
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl + 72),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            d.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: InkWell(
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
                if (d.author.userId != null)
                  _AuthorFollowButton(userId: d.author.userId!),
                const SizedBox(width: AppSpacing.xs),
                Text('${d.viewCount} 阅读'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (d.contentType != 'ARTICLE') ...[
          if (urls.isNotEmpty)
            ContentMediaGallery(mediaUrls: urls, aspectRatio: 3 / 4),
          if (d.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                d.body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ArticleBody(
              detail: d,
              mediaUrls: urls,
              blockMediaUrls: blockMediaUrls,
            ),
          ),
        if (d.relations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
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
          ),
        ],
        if (controller.state.message != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              controller.state.message!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _AuthorFollowButton extends ConsumerStatefulWidget {
  const _AuthorFollowButton({required this.userId});
  final int userId;

  @override
  ConsumerState<_AuthorFollowButton> createState() =>
      _AuthorFollowButtonState();
}

class _AuthorFollowButtonState extends ConsumerState<_AuthorFollowButton> {
  bool _loadingStarted = false;

  @override
  Widget build(BuildContext context) {
    final provider = publicProfileControllerProvider(widget.userId);
    ref.listen<PublicProfileController>(provider, (previous, next) {
      final nextMessage = next.state.message;
      if (!mounted || nextMessage == null) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(nextMessage)));
    });
    final controller = ref.watch(provider);
    if (!_loadingStarted) {
      _loadingStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(controller.load());
      });
    }
    final profile = controller.state.profile;
    if (profile == null || profile.isSelf) return const SizedBox.shrink();
    final button = profile.followed
        ? OutlinedButton(
            key: const ValueKey('content_author_follow'),
            onPressed: controller.state.followBusy
                ? null
                : () => unawaited(controller.toggleFollow()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(54, 32),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('已关注'),
          )
        : FilledButton(
            key: const ValueKey('content_author_follow'),
            onPressed: controller.state.followBusy
                ? null
                : () => unawaited(controller.toggleFollow()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brand.withValues(alpha: .55),
              disabledForegroundColor: Colors.white.withValues(alpha: .85),
              minimumSize: const Size(54, 32),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('关注'),
          );
    return button;
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surfaceMuted,
          child: Icon(icon, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label),
      ],
    ),
  );
}

class _DetailActionBar extends ConsumerWidget {
  const _DetailActionBar({
    required this.detail,
    required this.controller,
    required this.onComment,
    required this.onShare,
    required this.recommendationSource,
  });

  final ContentDetail detail;
  final ContentDetailController controller;
  final VoidCallback onComment;
  final VoidCallback onShare;
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
                child: InkWell(
                  key: const ValueKey('content_detail_comment_input'),
                  onTap: onComment,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppColors.inkMuted),
                        SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            '发表评论',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('content_detail_comment_action'),
                tooltip: '评论',
                onPressed: onComment,
                icon: Badge(
                  isLabelVisible: detail.commentCount > 0,
                  label: Text('${detail.commentCount}'),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
              IconButton(
                key: const ValueKey('content_detail_like_action'),
                tooltip: '点赞',
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
              ),
              IconButton(
                key: const ValueKey('content_detail_favorite_action'),
                tooltip: '收藏',
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
              ),
              IconButton(
                key: const ValueKey('content_detail_share'),
                tooltip: '分享',
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
