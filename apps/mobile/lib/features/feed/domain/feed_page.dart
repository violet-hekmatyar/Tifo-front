import 'feed_card.dart';
import '../../../core/network/backend_v1_contract.dart';

final class FeedPage {
  const FeedPage({
    required this.cards,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
    this.nextCursor,
    this.attribution = const RecommendationAttribution(),
  });

  final List<FeedCard> cards;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;
  final String? nextCursor;
  final RecommendationAttribution attribution;

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
