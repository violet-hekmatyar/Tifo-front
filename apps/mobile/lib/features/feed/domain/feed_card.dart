import '../../../core/network/backend_v1_contract.dart';

sealed class FeedCard {
  const FeedCard({
    required this.cardId,
    required this.rawCardType,
    this.cardKey,
    this.attribution = const RecommendationAttribution(),
    this.payload,
  });

  final String cardId;
  final String rawCardType;
  final String? cardKey;
  final RecommendationAttribution attribution;
  final Map<Object?, Object?>? payload;

  FeedCardType get cardType => FeedCardType.fromWire(rawCardType);
}

final class FeedAuthor {
  const FeedAuthor({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.verified = false,
  });

  final int? userId;
  final String nickname;
  final String? avatarUrl;
  final bool verified;
}

final class FeedHotComment {
  const FeedHotComment({required this.content, this.nickname});

  final String content;
  final String? nickname;
}

final class FeedRelationTag {
  const FeedRelationTag({required this.type, required this.id, this.name});

  final String type;
  final int id;
  final String? name;
}

final class ContentFeedCard extends FeedCard {
  const ContentFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.likeCount,
    required this.commentCount,
    super.cardKey,
    super.attribution,
    this.summary,
    this.coverUrl,
    this.author,
    this.hotComment,
    this.publishTime,
  });

  final int contentId;
  final String contentType;
  final String title;
  final String? summary;
  final String? coverUrl;
  final FeedAuthor? author;
  final FeedHotComment? hotComment;
  final DateTime? publishTime;
  final int likeCount;
  final int commentCount;
}

final class FeedTeam {
  const FeedTeam({required this.teamId, required this.teamName, this.logoUrl});

  final int? teamId;
  final String teamName;
  final String? logoUrl;
}

final class MatchFeedCard extends FeedCard {
  const MatchFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.matchId,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchStatus,
    super.cardKey,
    super.attribution,
    this.homeScore,
    this.awayScore,
    this.matchTime,
    this.eventSummary,
  });

  final int matchId;
  final String leagueName;
  final FeedTeam homeTeam;
  final FeedTeam awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String matchStatus;
  final DateTime? matchTime;
  final String? eventSummary;

  bool get hasScore => homeScore != null && awayScore != null;
}

final class UnknownFeedCard extends FeedCard {
  const UnknownFeedCard({
    required super.cardId,
    required super.rawCardType,
    super.cardKey,
    super.attribution,
    super.payload,
  });
}

final class HotCommentFeedCard extends FeedCard {
  const HotCommentFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.commentId,
    required this.contentId,
    required this.commentText,
    required this.likeCount,
    required this.replyCount,
    super.cardKey,
    super.attribution,
    super.payload,
    this.commentAuthor,
    this.hotScore,
    this.contentTitle,
    this.contentType,
  });

  final int commentId;
  final int contentId;
  final String commentText;
  final FeedAuthor? commentAuthor;
  final int likeCount;
  final int replyCount;
  final double? hotScore;
  final String? contentTitle;
  final String? contentType;
}

final class DiscussionFeedCard extends FeedCard {
  const DiscussionFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.contentId,
    required this.title,
    required this.commentCount,
    required this.likeCount,
    required this.favoriteCount,
    required this.relationTags,
    super.cardKey,
    super.attribution,
    super.payload,
    this.summary,
    this.author,
    this.publishTime,
    this.hotComment,
  });

  final int contentId;
  final String title;
  final String? summary;
  final FeedAuthor? author;
  final DateTime? publishTime;
  final int commentCount;
  final int likeCount;
  final int favoriteCount;
  final FeedHotComment? hotComment;
  final List<FeedRelationTag> relationTags;
}

final class RankingFeedCard extends FeedCard {
  const RankingFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.rankingType,
    required this.rankType,
    required this.title,
    required this.items,
    super.cardKey,
    super.attribution,
    super.payload,
    this.leagueId,
    this.leagueName,
    this.seasonId,
    this.seasonName,
  });

  final String rankingType;
  final String rankType;
  final int? leagueId;
  final String? leagueName;
  final int? seasonId;
  final String? seasonName;
  final String title;
  final List<FeedRankingItem> items;
}

final class FeedRankingItem {
  const FeedRankingItem({
    required this.rank,
    required this.name,
    required this.value,
    this.entityId,
    this.imageUrl,
    this.teamId,
    this.teamName,
  });

  final int rank;
  final int? entityId;
  final String name;
  final String? imageUrl;
  final int? teamId;
  final String? teamName;
  final String value;
}

final class PlayerRatingFeedCard extends FeedCard {
  const PlayerRatingFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.topPlayers,
    required this.ratingUserCount,
    super.cardKey,
    super.attribution,
    super.payload,
    this.leagueId,
    this.leagueName,
    this.matchTime,
    this.homeScore,
    this.awayScore,
  });

  final int matchId;
  final int? leagueId;
  final String? leagueName;
  final DateTime? matchTime;
  final FeedTeam homeTeam;
  final FeedTeam awayTeam;
  final int? homeScore;
  final int? awayScore;
  final List<FeedRatingPlayer> topPlayers;
  final int ratingUserCount;
}

final class FeedRatingPlayer {
  const FeedRatingPlayer({
    required this.playerId,
    required this.playerName,
    required this.userRatingCount,
    this.avatarUrl,
    this.teamId,
    this.officialRating,
    this.userRatingAverage,
  });

  final int playerId;
  final String playerName;
  final String? avatarUrl;
  final int? teamId;
  final double? officialRating;
  final double? userRatingAverage;
  final int userRatingCount;
}

String feedCardStableKey(FeedCard card) => switch (card) {
  ContentFeedCard card => 'content:${card.contentId}',
  MatchFeedCard card => 'match:${card.matchId}',
  HotCommentFeedCard card => 'comment:${card.commentId}',
  DiscussionFeedCard card => 'discussion:${card.contentId}',
  RankingFeedCard card => card.cardKey ?? 'ranking:${card.cardId}',
  PlayerRatingFeedCard card => 'player-rating:${card.matchId}',
  UnknownFeedCard card => 'unknown:${card.cardId}',
};
