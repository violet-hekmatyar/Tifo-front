import 'feed_card.dart';

final class FeedPage {
  const FeedPage({
    required this.cards,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  final List<FeedCard> cards;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;

  bool get hasMore => pageNum < pages;
}

final class FollowedTeam {
  const FollowedTeam({
    required this.teamId,
    required this.teamName,
    this.logoUrl,
  });

  final int teamId;
  final String teamName;
  final String? logoUrl;
}
