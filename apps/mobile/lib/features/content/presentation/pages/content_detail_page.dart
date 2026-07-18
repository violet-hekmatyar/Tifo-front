import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../interaction/presentation/widgets/comment_section.dart';
import '../../../feed/presentation/controllers/feed_refresh_coordinator.dart';
import '../controllers/content_detail_controller.dart';
import '../widgets/content_media_gallery.dart';

class ContentDetailPage extends ConsumerStatefulWidget {
  const ContentDetailPage({
    required this.contentId,
    this.refreshFeedOnExit = false,
    super.key,
  });
  final int contentId;
  final bool refreshFeedOnExit;

  @override
  ConsumerState<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends ConsumerState<ContentDetailPage> {
  bool _returning = false;

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

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(contentDetailControllerProvider(widget.contentId));
    final s = c.state;
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
          ),
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.controller, required this.currentUserId});
  final ContentDetailController controller;
  final int? currentUserId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = controller.state.detail!;
    final config = ref.watch(appConfigProvider);
    final urls = d.media
        .where((m) => m.mediaType == 'IMAGE')
        .map((m) => resolveMediaUrl(config, m.mediaUrl))
        .whereType<String>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          d.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
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
        const SizedBox(height: AppSpacing.lg),
        if (d.contentFormat == 'POST_FORMAT') ...[
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
          ArticleBody(detail: d, mediaUrls: urls),
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
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: controller.state.likeBusy
                    ? null
                    : controller.toggleLike,
                icon: Icon(d.liked ? Icons.favorite : Icons.favorite_border),
                label: Text('${d.likeCount} 点赞'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: controller.state.favoriteBusy
                    ? null
                    : controller.toggleFavorite,
                icon: Icon(
                  d.favorited ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text('${d.favoriteCount} 收藏'),
              ),
            ),
          ],
        ),
        if (controller.state.message != null)
          Text(
            controller.state.message!,
            style: const TextStyle(color: AppColors.error),
          ),
        const SizedBox(height: AppSpacing.xl),
        CommentSection(contentId: d.contentId, currentUserId: currentUserId),
      ],
    );
  }
}
