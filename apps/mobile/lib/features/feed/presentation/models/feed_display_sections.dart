import '../../domain/feed_card.dart';

sealed class FeedDisplayEntry {
  const FeedDisplayEntry();
}

final class FeedSingleEntry extends FeedDisplayEntry {
  const FeedSingleEntry(this.card);
  final FeedCard card;
}

final class FeedContentRowEntry extends FeedDisplayEntry {
  const FeedContentRowEntry(this.left, [this.right]);
  final ContentFeedCard left;
  final ContentFeedCard? right;
}

/// Builds visual rows without changing the backend/page arrival order.
final class FeedDisplaySections {
  FeedDisplaySections._(this.entries);

  factory FeedDisplaySections.fromCards(Iterable<FeedCard> cards) {
    final unique = <FeedCard>[];
    final seen = <String>{};
    for (final card in cards) {
      if (!seen.add(feedCardStableKey(card))) continue;
      unique.add(card);
    }
    final entries = <FeedDisplayEntry>[];
    for (var index = 0; index < unique.length; index++) {
      final card = unique[index];
      if (card is ContentFeedCard) {
        final next = index + 1 < unique.length ? unique[index + 1] : null;
        if (next is ContentFeedCard) {
          entries.add(FeedContentRowEntry(card, next));
          index++;
        } else {
          entries.add(FeedContentRowEntry(card));
        }
      } else {
        entries.add(FeedSingleEntry(card));
      }
    }
    return FeedDisplaySections._(List.unmodifiable(entries));
  }

  final List<FeedDisplayEntry> entries;
  List<MatchFeedCard> get matches => List.unmodifiable(
    entries
        .whereType<FeedSingleEntry>()
        .map((entry) => entry.card)
        .whereType<MatchFeedCard>(),
  );
  List<ContentFeedCard> get contents => List.unmodifiable(
    entries.expand((entry) sync* {
      if (entry is FeedContentRowEntry) {
        yield entry.left;
        if (entry.right case final right?) yield right;
      }
    }),
  );
  List<FeedCard> get compatibility => List.unmodifiable(
    entries
        .whereType<FeedSingleEntry>()
        .map((entry) => entry.card)
        .where((card) => card is! MatchFeedCard),
  );
  int get cardCount => entries.fold(
    0,
    (count, entry) =>
        count + (entry is FeedContentRowEntry && entry.right != null ? 2 : 1),
  );
}
