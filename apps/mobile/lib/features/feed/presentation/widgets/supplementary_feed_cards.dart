import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/feed_card.dart';

class HotCommentCard extends StatelessWidget {
  const HotCommentCard({
    required this.card,
    required this.onTap,
    this.avatarUrl,
    super.key,
  });

  final HotCommentFeedCard card;
  final VoidCallback onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => _CardSurface(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeading(
          icon: Icons.local_fire_department_rounded,
          label: '热门评论',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '“${card.commentText}”',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (card.contentTitle case final title?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppEntityAvatar(
              identity: 'user:${card.commentAuthor?.userId ?? card.cardId}',
              semanticLabel: '${card.commentAuthor?.nickname ?? '用户'}头像',
              fallbackIcon: Icons.person_outline_rounded,
              fallbackText: _initial(card.commentAuthor?.nickname),
              imageUrl: avatarUrl,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(card.commentAuthor?.nickname ?? '南看台用户')),
            const Icon(
              Icons.favorite_border_rounded,
              size: 17,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text('${card.likeCount}'),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.forum_outlined,
              size: 17,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text('${card.replyCount}'),
          ],
        ),
      ],
    ),
  );
}

class DiscussionCard extends StatelessWidget {
  const DiscussionCard({
    required this.card,
    required this.onTap,
    this.avatarUrl,
    super.key,
  });

  final DiscussionFeedCard card;
  final VoidCallback onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => _CardSurface(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeading(icon: Icons.forum_rounded, label: '正在热议'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          card.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (card.summary case final summary?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (card.hotComment case final comment?) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${comment.nickname ?? '用户'}：${comment.content}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppEntityAvatar(
              identity: 'user:${card.author?.userId ?? card.cardId}',
              semanticLabel: '${card.author?.nickname ?? '用户'}头像',
              fallbackIcon: Icons.person_outline_rounded,
              fallbackText: _initial(card.author?.nickname),
              imageUrl: avatarUrl,
              size: 30,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                card.author?.nickname ?? '南看台用户',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.favorite_border_rounded,
              size: 17,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text('${card.likeCount}'),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 17,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text('${card.commentCount}'),
          ],
        ),
      ],
    ),
  );
}

class RankingCard extends StatelessWidget {
  const RankingCard({
    required this.card,
    required this.resolveImage,
    this.onTeamTap,
    this.onPlayerTap,
    super.key,
  });

  final RankingFeedCard card;
  final String? Function(String?) resolveImage;
  final ValueChanged<int>? onTeamTap;
  final ValueChanged<int>? onPlayerTap;

  @override
  Widget build(BuildContext context) => _CardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeading(icon: Icons.leaderboard_rounded, label: card.title),
        if (card.leagueName case final league?) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            league,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (card.items.isEmpty)
          const Text('当前暂无排名数据')
        else
          ...card.items.take(5).map((item) {
            final isPlayer = card.rankingType == 'PLAYER';
            final targetId = isPlayer
                ? item.entityId
                : item.teamId ?? item.entityId;
            final onTap = targetId == null
                ? null
                : isPlayer
                ? onPlayerTap == null
                      ? null
                      : () => onPlayerTap!(targetId)
                : onTeamTap == null
                ? null
                : () => onTeamTap!(targetId);
            return InkWell(
              key: ValueKey(
                'ranking_${isPlayer ? 'player' : 'team'}_${targetId ?? item.name}',
              ),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${item.rank}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isPlayer)
                      AppPlayerAvatar(
                        identity: 'ranking:${item.entityId ?? item.name}',
                        name: item.name,
                        imageUrl: resolveImage(item.imageUrl),
                        size: 30,
                      )
                    else
                      AppTeamLogo(
                        identity: 'ranking:${targetId ?? item.name}',
                        name: item.name,
                        imageUrl: resolveImage(item.imageUrl),
                        size: 30,
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  );
}

class PlayerRatingCard extends StatelessWidget {
  const PlayerRatingCard({
    required this.card,
    required this.onTap,
    required this.resolveImage,
    this.onPlayerTap,
    super.key,
  });

  final PlayerRatingFeedCard card;
  final VoidCallback onTap;
  final String? Function(String?) resolveImage;
  final ValueChanged<int>? onPlayerTap;

  @override
  Widget build(BuildContext context) => _CardSurface(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeading(icon: Icons.star_rounded, label: '赛后球员评分'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                card.homeTeam.teamName,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                card.homeScore == null || card.awayScore == null
                    ? 'vs'
                    : '${card.homeScore} : ${card.awayScore}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: Text(
                card.awayTeam.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (card.topPlayers.isEmpty)
          const Text('当前暂无球员评分')
        else
          ...card.topPlayers
              .take(3)
              .map(
                (player) => InkWell(
                  onTap: onPlayerTap == null
                      ? null
                      : () => onPlayerTap!(player.playerId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        AppPlayerAvatar(
                          identity: 'player:${player.playerId}',
                          name: player.playerName,
                          imageUrl: resolveImage(player.avatarUrl),
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            player.playerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          (player.userRatingAverage ?? player.officialRating)
                                  ?.toStringAsFixed(1) ??
                              '暂无',
                          style: const TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        if (card.ratingUserCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${card.ratingUserCount} 人参与评分',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ],
    ),
  );
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: child,
      ),
    ),
  );
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.brand),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

String? _initial(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text.characters.first;
}
