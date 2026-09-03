import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/presentation/models/feed_display_sections.dart';

void main() {
  test('groups interleaved cards while preserving each type order', () {
    final sections = FeedDisplaySections.fromCards([
      _match('m1', 1),
      _content('c1', 1),
      _match('m2', 2),
      _content('c2', 2),
      _match('m3', 3),
    ]);
    expect(sections.matches.map((card) => card.cardId), ['m1', 'm2', 'm3']);
    expect(sections.contents.map((card) => card.cardId), ['c1', 'c2']);
    expect(sections.cardCount, 5);
    expect(
      sections.entries.map(
        (entry) => switch (entry) {
          FeedSingleEntry(:final card) => card.cardId,
          FeedContentRowEntry(:final left) => left.cardId,
        },
      ),
      ['m1', 'c1', 'm2', 'c2', 'm3'],
    );
  });

  test('later pages merge into the same match and content sections', () {
    final loadedCards = <FeedCard>[
      _match('page1-match', 1),
      _content('page1-content', 1),
      _content('page2-content', 2),
      _match('page2-match', 2),
    ];
    final sections = FeedDisplaySections.fromCards(loadedCards);
    expect(sections.matches.map((card) => card.matchId), [1, 2]);
    expect(sections.contents.map((card) => card.contentId), [1, 2]);
  });

  test(
    'unknown cards follow content and stable identities are deduplicated',
    () {
      final sections = FeedDisplaySections.fromCards([
        const UnknownFeedCard(cardId: 'unknown-1', rawCardType: 'POLL'),
        _match('m1', 1),
        _content('c1', 1),
        _match('duplicate-match-card-id', 1),
        _content('duplicate-content-card-id', 1),
        const UnknownFeedCard(cardId: 'unknown-1', rawCardType: 'POLL'),
      ]);
      expect(sections.matches.length, 1);
      expect(sections.contents.length, 1);
      expect(sections.compatibility.map((card) => card.cardId), ['unknown-1']);
      expect(sections.cardCount, 3);
    },
  );

  test('empty card types produce only the available section', () {
    expect(FeedDisplaySections.fromCards([_content('c1', 1)]).matches, isEmpty);
    expect(FeedDisplaySections.fromCards([_match('m1', 1)]).contents, isEmpty);
  });
}

ContentFeedCard _content(String cardId, int contentId) => ContentFeedCard(
  cardId: cardId,
  rawCardType: 'CONTENT',
  contentId: contentId,
  contentType: 'POST',
  title: cardId,
  likeCount: 0,
  commentCount: 0,
);

MatchFeedCard _match(String cardId, int matchId) => MatchFeedCard(
  cardId: cardId,
  rawCardType: 'MATCH',
  matchId: matchId,
  leagueName: '联赛',
  homeTeam: const FeedTeam(teamId: 1, teamName: '主队'),
  awayTeam: const FeedTeam(teamId: 2, teamName: '客队'),
  matchStatus: 'SCHEDULED',
);
