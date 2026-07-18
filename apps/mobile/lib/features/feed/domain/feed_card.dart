sealed class FeedCard {
  const FeedCard({required this.cardId, required this.rawCardType});

  final String cardId;
  final String rawCardType;
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

final class ContentFeedCard extends FeedCard {
  const ContentFeedCard({
    required super.cardId,
    required super.rawCardType,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.likeCount,
    required this.commentCount,
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
  const UnknownFeedCard({required super.cardId, required super.rawCardType});
}

String feedCardStableKey(FeedCard card) => switch (card) {
  ContentFeedCard card => 'content:${card.contentId}',
  MatchFeedCard card => 'match:${card.matchId}',
  UnknownFeedCard card => 'unknown:${card.cardId}',
};
