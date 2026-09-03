import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../domain/feed_card.dart';
import '../models/feed_recommendation_source.dart';
import 'content_card.dart';
import 'match_card.dart';
import 'recommendation_exposure.dart';
import 'supplementary_feed_cards.dart';
import 'unknown_card.dart';

class FeedCardRenderer extends ConsumerWidget {
  const FeedCardRenderer({required this.card, super.key});

  final FeedCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final source = recommendationSourceFor(card);
    void open(String route) {
      ref
          .read(recommendationBehaviorDispatcherProvider)
          .record(RecommendationBehaviorType.click, source);
      context.push(
        route,
        extra: source == null
            ? null
            : RecommendationNavigationData(source: source),
      );
    }

    final rendered = switch (card) {
      ContentFeedCard card => ContentCard(
        card: card,
        coverUrl: resolveMediaUrl(config, card.coverUrl),
        authorAvatarUrl: resolveMediaUrl(config, card.author?.avatarUrl),
        onAuthorTap: card.author?.userId == null
            ? null
            : () => context.push('/users/${card.author!.userId}'),
        onTap: () => open('/contents/${card.contentId}'),
      ),
      MatchFeedCard card => MatchCard(
        card: card,
        homeLogoUrl: resolveMediaUrl(config, card.homeTeam.logoUrl),
        awayLogoUrl: resolveMediaUrl(config, card.awayTeam.logoUrl),
        onTap: () => open('/matches/${card.matchId}'),
      ),
      HotCommentFeedCard card => HotCommentCard(
        card: card,
        avatarUrl: resolveMediaUrl(config, card.commentAuthor?.avatarUrl),
        onTap: () => open('/contents/${card.contentId}'),
      ),
      DiscussionFeedCard card => DiscussionCard(
        card: card,
        avatarUrl: resolveMediaUrl(config, card.author?.avatarUrl),
        onTap: () => open('/contents/${card.contentId}'),
      ),
      RankingFeedCard card => RankingCard(
        card: card,
        resolveImage: (url) => resolveMediaUrl(config, url),
        onTeamTap: (teamId) => open('/teams/$teamId'),
        onPlayerTap: (playerId) => open('/players/$playerId'),
      ),
      PlayerRatingFeedCard card => PlayerRatingCard(
        card: card,
        resolveImage: (url) => resolveMediaUrl(config, url),
        onTap: () => open('/matches/${card.matchId}'),
        onPlayerTap: (playerId) => open('/players/$playerId'),
      ),
      UnknownFeedCard card => UnknownCard(card: card),
    };
    return RecommendationExposure(source: source, child: rendered);
  }
}
