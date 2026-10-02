import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/feed_card.dart';

enum ContentCardLayout { grid, news }

class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.card,
    required this.onTap,
    this.onAuthorTap,
    this.coverUrl,
    this.authorAvatarUrl,
    this.authorFallbackAsset,
    this.userCenterStyle = false,
    this.userCenterMediaAspectRatio,
    this.showMedia = true,
    this.layout = ContentCardLayout.grid,
    this.transferImageResolver,
    super.key,
  });

  final ContentFeedCard card;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;
  final String? coverUrl;
  final String? authorAvatarUrl;
  final String? authorFallbackAsset;
  final bool userCenterStyle;
  final double? userCenterMediaAspectRatio;
  final bool showMedia;
  final ContentCardLayout layout;
  final String? Function(String?)? transferImageResolver;

  @override
  Widget build(BuildContext context) {
    final brief = card.transferBrief;
    if (layout == ContentCardLayout.grid && brief != null) {
      return TransferBriefCard(
        card: card,
        brief: brief,
        onTap: onTap,
        resolveImage: transferImageResolver ?? (url) => url,
      );
    }
    return switch (layout) {
      ContentCardLayout.grid => _GridContentCard(
        card: card,
        onTap: onTap,
        onAuthorTap: onAuthorTap,
        coverUrl: coverUrl,
        authorAvatarUrl: authorAvatarUrl,
        authorFallbackAsset: authorFallbackAsset,
        userCenterStyle: userCenterStyle,
        userCenterMediaAspectRatio: userCenterMediaAspectRatio,
        showMedia: showMedia,
      ),
      ContentCardLayout.news => _NewsContentCard(
        card: card,
        onTap: onTap,
        onAuthorTap: onAuthorTap,
        coverUrl: coverUrl,
        showMedia: showMedia,
      ),
    };
  }
}

class TransferBriefCard extends StatelessWidget {
  const TransferBriefCard({
    required this.card,
    required this.brief,
    required this.onTap,
    required this.resolveImage,
    super.key,
  });

  final ContentFeedCard card;
  final FeedTransferBrief brief;
  final VoidCallback onTap;
  final String? Function(String?) resolveImage;

  @override
  Widget build(BuildContext context) => _CardSurface(
    key: ValueKey('transfer_brief_${card.contentId}'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.brand),
              const SizedBox(width: 5),
              Text(
                '转会快讯',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              AppPlayerAvatar(
                identity: 'transfer-player:${brief.playerId}',
                name: brief.playerName,
                imageUrl: resolveImage(brief.playerAvatarUrl),
                size: 40,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brief.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (brief.playerMeta case final meta?)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TransferTeam(
                  id: brief.fromTeamId,
                  name: brief.fromTeamName,
                  imageUrl: resolveImage(brief.fromTeamLogoUrl),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              Expanded(
                child: _TransferTeam(
                  id: brief.toTeamId,
                  name: brief.toTeamName,
                  imageUrl: resolveImage(brief.toTeamLogoUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _TransferFact(label: '转会费', value: brief.feeLabel),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TransferFact(label: '租借时间', value: brief.durationLabel),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _TransferTeam extends StatelessWidget {
  const _TransferTeam({required this.id, required this.name, this.imageUrl});
  final int id;
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTeamLogo(
        identity: 'transfer-team:$id',
        name: name,
        imageUrl: imageUrl,
        size: 34,
      ),
      const SizedBox(height: 3),
      Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ],
  );
}

class _TransferFact extends StatelessWidget {
  const _TransferFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _GridContentCard extends StatelessWidget {
  const _GridContentCard({
    required this.card,
    required this.onTap,
    required this.onAuthorTap,
    required this.coverUrl,
    required this.authorAvatarUrl,
    required this.authorFallbackAsset,
    required this.userCenterStyle,
    required this.userCenterMediaAspectRatio,
    required this.showMedia,
  });

  final ContentFeedCard card;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;
  final String? coverUrl;
  final String? authorAvatarUrl;
  final String? authorFallbackAsset;
  final bool userCenterStyle;
  final double? userCenterMediaAspectRatio;
  final bool showMedia;

  @override
  Widget build(BuildContext context) => _CardSurface(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMedia)
          Stack(
            children: [
              AppContentImage(
                imageUrl: coverUrl,
                aspectRatio:
                    userCenterMediaAspectRatio ??
                    (userCenterStyle ? 1.2 : 1.28),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                  fontSize: 12,
                ),
              ),
              if (card.hotComment case final comment?) ...[
                const SizedBox(height: 6),
                _HotComment(comment: comment),
              ],
              const SizedBox(height: 6),
              _AuthorRow(
                card: card,
                avatarUrl: authorAvatarUrl,
                fallbackAsset: authorFallbackAsset,
                onTap: onAuthorTap,
              ),
              const SizedBox(height: 6),
              _EngagementRow(card: card),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NewsContentCard extends StatelessWidget {
  const _NewsContentCard({
    required this.card,
    required this.onTap,
    required this.onAuthorTap,
    required this.coverUrl,
    required this.showMedia,
  });

  final ContentFeedCard card;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;
  final String? coverUrl;
  final bool showMedia;

  @override
  Widget build(BuildContext context) => _CardSurface(
    onTap: onTap,
    child: SizedBox(
      height: showMedia ? 104 : 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMedia)
            SizedBox(
              width: 116,
              child: AppContentImage(imageUrl: coverUrl, aspectRatio: 1.3),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (card.summary case final summary?
                      when summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const Spacer(),
                  InkWell(
                    onTap: onAuthorTap,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.author?.nickname ?? '南看台用户',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ),
                        if (card.publishTime case final time?)
                          Text(
                            _date(time),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: child,
      ),
    ),
  );
}

class _HotComment extends StatelessWidget {
  const _HotComment({required this.comment});
  final FeedHotComment comment;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('content_comment_slot'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppColors.error,
          size: 15,
        ),
        const SizedBox(width: 4),
        const Text(
          '热评：',
          style: TextStyle(color: AppColors.error, fontSize: 10),
        ),
        Expanded(
          child: Text(
            comment.content,
            key: const ValueKey('content_comment_summary'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 15),
      ],
    ),
  );
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.card,
    required this.avatarUrl,
    this.fallbackAsset,
    this.onTap,
  });

  final ContentFeedCard card;
  final String? avatarUrl;
  final String? fallbackAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Row(
      children: [
        AppEntityAvatar(
          identity: 'user:${card.author?.userId ?? card.cardId}',
          semanticLabel: '${card.author?.nickname ?? '南看台用户'}头像',
          fallbackIcon: Icons.person_outline_rounded,
          fallbackText: _initial(card.author?.nickname),
          fallbackAsset: fallbackAsset,
          imageUrl: avatarUrl,
          size: 20,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            card.author?.nickname ?? '南看台用户',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({required this.card});
  final ContentFeedCard card;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (card.publishTime case final time?)
        Expanded(
          child: Text(
            _date(time),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        )
      else
        const Spacer(),
      const Icon(
        Icons.favorite_border_rounded,
        size: 14,
        color: AppColors.inkMuted,
      ),
      const SizedBox(width: 2),
      Text('${card.likeCount}'),
      const SizedBox(width: 5),
      const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 14,
        color: AppColors.inkMuted,
      ),
      const SizedBox(width: 2),
      Text('${card.commentCount}'),
    ],
  );
}

String? _initial(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text.characters.first;
}

String _date(DateTime value) => '${value.month}/${value.day}';
