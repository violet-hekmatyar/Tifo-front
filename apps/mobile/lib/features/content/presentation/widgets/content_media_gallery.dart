import 'package:flutter/material.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../domain/content_detail.dart';

class ContentMediaGallery extends StatefulWidget {
  const ContentMediaGallery({required this.mediaUrls, super.key});
  final List<String> mediaUrls;
  @override
  State<ContentMediaGallery> createState() => _ContentMediaGalleryState();
}

class _ContentMediaGalleryState extends State<ContentMediaGallery> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: widget.mediaUrls.length,
            onPageChanged: (v) => setState(() => index = v),
            itemBuilder: (_, i) => AppContentImage(
              imageUrl: widget.mediaUrls[i],
              aspectRatio: 4 / 3,
            ),
          ),
        ),
        if (widget.mediaUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Text(
              '${index + 1} / ${widget.mediaUrls.length}',
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}

class ArticleBody extends StatelessWidget {
  const ArticleBody({
    required this.detail,
    required this.mediaUrls,
    this.blockMediaUrls = const {},
    super.key,
  });
  final ContentDetail detail;
  final List<String> mediaUrls;
  final Map<ArticleBlock, String> blockMediaUrls;
  @override
  Widget build(BuildContext context) {
    if (detail.blocks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.body.isNotEmpty)
            Text(
              detail.body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          for (final url in mediaUrls) ...[
            const SizedBox(height: AppSpacing.md),
            AppContentImage(imageUrl: url),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in _orderedBlocks(detail.blocks)) ...[
          if (block.type == ArticleBlockType.text && block.text != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                block.text!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.8),
              ),
            )
          else if (block.type == ArticleBlockType.image &&
              block.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppContentImage(
                imageUrl: blockMediaUrls[block] ?? block.mediaUrl,
              ),
            )
          else if (block.type == ArticleBlockType.unknown)
            Container(
              key: ValueKey(
                'unknown_article_block_${block.blockId ?? block.sortOrder}',
              ),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                block.text ?? '暂不支持的内容段：${block.rawType}',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ),
        ],
      ],
    );
  }
}

List<ArticleBlock> _orderedBlocks(List<ArticleBlock> blocks) {
  final indexed = blocks.indexed.toList();
  indexed.sort((a, b) {
    final byOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
    return byOrder == 0 ? a.$1.compareTo(b.$1) : byOrder;
  });
  return indexed.map((item) => item.$2).toList(growable: false);
}
