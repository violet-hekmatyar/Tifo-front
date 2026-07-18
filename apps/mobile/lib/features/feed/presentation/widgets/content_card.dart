import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../domain/feed_card.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.card,
    required this.onTap,
    this.coverUrl,
    this.authorAvatarUrl,
    super.key,
  });

  final ContentFeedCard card;
  final VoidCallback onTap;
  final String? coverUrl;
  final String? authorAvatarUrl;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppContentImage(imageUrl: coverUrl),
                if (card.contentType == 'POST')
                  const Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: _TypeBadge(label: '帖子'),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  if (card.hotComment case final comment?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        comment.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      AppEntityAvatar(
                        identity: 'user:${card.author?.userId ?? card.cardId}',
                        semanticLabel: '${card.author?.nickname ?? '南看台用户'}头像',
                        fallbackIcon: Icons.person_outline_rounded,
                        fallbackText: _initial(card.author?.nickname),
                        imageUrl: authorAvatarUrl,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          card.author?.nickname ?? '南看台用户',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (card.publishTime case final time?)
                        Expanded(
                          child: Text(
                            _date(time),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        )
                      else
                        const Spacer(),
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 2),
                      Text('${card.likeCount}'),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 2),
                      Text('${card.commentCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String? _initial(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text.characters.first;
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
