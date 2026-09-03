import '../../../../core/network/backend_v1_contract.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../domain/feed_card.dart';

RecommendationSourceContext? recommendationSourceFor(FeedCard card) {
  final (type, id) = switch (card) {
    ContentFeedCard card => (RecommendationTargetType.content, card.contentId),
    MatchFeedCard card => (RecommendationTargetType.match, card.matchId),
    HotCommentFeedCard card => (
      RecommendationTargetType.comment,
      card.commentId,
    ),
    DiscussionFeedCard card => (
      RecommendationTargetType.content,
      card.contentId,
    ),
    RankingFeedCard card => (
      RecommendationTargetType.ranking,
      card.leagueId ?? card.seasonId ?? -1,
    ),
    PlayerRatingFeedCard card => (
      RecommendationTargetType.playerRating,
      card.matchId,
    ),
    UnknownFeedCard() => (RecommendationTargetType.unknown, -1),
  };
  if (id <= 0 || type == RecommendationTargetType.unknown) return null;
  return RecommendationSourceContext(
    targetType: type,
    targetId: id,
    attribution: card.attribution,
  );
}
