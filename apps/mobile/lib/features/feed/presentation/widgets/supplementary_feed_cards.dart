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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '“${card.commentText}”',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (card.contentTitle case final title?
            when title.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: AppSpacing.sm),
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
        Container(
          key: const ValueKey('discussion_topic_panel'),
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2355BA), Color(0xFF3975E5)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '话题讨论',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                card.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              if (card.summary case final summary?
                  when summary.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        if (card.hotComment case final comment?
            when comment.content.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '热门评论  ${comment.nickname ?? '用户'}：${comment.content}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, height: 1.3),
            ),
          ),
        ],
        const SizedBox(height: 7),
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
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '排名',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '球队',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '积分',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (card.items.isEmpty)
          const Text('当前暂无排名数据')
        else
          ...card.items.take(4).map((item) {
            final isPlayer = card.rankingType == 'PLAYER';
            final isTeam =
                card.rankingType == 'STANDING' || card.rankingType == 'TEAM';
            final targetId = isPlayer
                ? item.entityId
                : isTeam
                ? item.teamId ?? item.entityId
                : null;
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
                padding: const EdgeInsets.symmetric(vertical: 3),
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
                        maxLines: 2,
                        softWrap: true,
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
        const SizedBox(height: 6),
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
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
        const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        AppPlayerAvatar(
                          identity: 'player:${player.playerId}',
                          name: player.playerName,
                          imageUrl: resolveImage(player.avatarUrl),
                          size: 36,
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
        if (card.topPlayers.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              for (var index = 0; index < 5; index++)
                Icon(
                  Icons.star_rounded,
                  size: 15,
                  color:
                      index <
                          ((card.topPlayers.first.userRatingAverage ??
                                      card.topPlayers.first.officialRating ??
                                      0) /
                                  2)
                              .round()
                      ? const Color(0xFFFFC928)
                      : AppColors.border,
                ),
              const SizedBox(width: 4),
              Text(
                (card.topPlayers.first.userRatingAverage ??
                            card.topPlayers.first.officialRating)
                        ?.toStringAsFixed(1) ??
                    '暂无',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (card.ratingUserCount > 0)
                Text(
                  '${card.ratingUserCount} 人评分',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 5),
        Text(
          '${card.leagueName ?? '比赛'}  ${card.homeTeam.teamName} ${card.homeScore ?? '-'} : ${card.awayScore ?? '-'} ${card.awayTeam.teamName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 9),
        ),
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
    borderRadius: BorderRadius.circular(AppRadius.sm),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: AppShadows.card,
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
      Icon(icon, size: 17, color: AppColors.brand),
      const SizedBox(width: 5),
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
