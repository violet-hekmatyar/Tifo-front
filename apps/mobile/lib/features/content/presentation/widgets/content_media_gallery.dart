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
  const ArticleBody({required this.detail, required this.mediaUrls, super.key});
  final ContentDetail detail;
  final List<String> mediaUrls;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (detail.body.isNotEmpty)
        Text(
          detail.body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
        ),
      for (final url in mediaUrls) ...[
        const SizedBox(height: AppSpacing.md),
        AppContentImage(imageUrl: url),
      ],
    ],
  );
}
