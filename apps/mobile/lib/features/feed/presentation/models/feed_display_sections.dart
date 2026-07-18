import '../../domain/feed_card.dart';

/// A presentation-only grouping of the original paged feed cards.
///
/// Cross-type order intentionally becomes MATCH -> CONTENT -> compatibility,
/// while the backend arrival order inside each group stays unchanged.
final class FeedDisplaySections {
  FeedDisplaySections._({
    required this.matches,
    required this.contents,
    required this.compatibility,
  });

  factory FeedDisplaySections.fromCards(Iterable<FeedCard> cards) {
    final matches = <MatchFeedCard>[];
    final contents = <ContentFeedCard>[];
    final compatibility = <UnknownFeedCard>[];
    final seen = <String>{};
    for (final card in cards) {
      if (!seen.add(feedCardStableKey(card))) continue;
      switch (card) {
        case MatchFeedCard card:
          matches.add(card);
        case ContentFeedCard card:
          contents.add(card);
        case UnknownFeedCard card:
          compatibility.add(card);
      }
    }
    return FeedDisplaySections._(
      matches: List.unmodifiable(matches),
      contents: List.unmodifiable(contents),
      compatibility: List.unmodifiable(compatibility),
    );
  }

  final List<MatchFeedCard> matches;
  final List<ContentFeedCard> contents;
  final List<UnknownFeedCard> compatibility;

  int get cardCount => matches.length + contents.length + compatibility.length;
}
