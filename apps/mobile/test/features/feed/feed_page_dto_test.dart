import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/feed/data/dto/feed_page_dto.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';

void main() {
  test(
    'parses page metadata, attribution, empty arrays, and nullable fields',
    () {
      final page = FeedPageDto.fromRaw({
        'records': <Object>[],
        'total': 0,
        'pageNum': 1,
        'pageSize': 10,
        'pages': 0,
        'nextCursor': null,
        'algorithmVersion': 'RULE_V2',
        'modelVersion': null,
        'experimentId': 'home-v1',
        'experimentBucket': 'B',
        'requestId': 'request-1',
      }).toDomain();

      expect(page.cards, isEmpty);
      expect(page.nextCursor, isNull);
      expect(page.attribution.algorithmVersion, 'RULE_V2');
      expect(page.attribution.modelVersion, isNull);
      expect(page.attribution.requestId, 'request-1');
    },
  );

  test('parses six card types without requiring their UI widgets', () {
    final page = FeedPageDto.fromRaw({
      'records': [
        {'cardType': 'CONTENT', 'contentId': 1, 'title': '内容'},
        {
          'cardType': 'MATCH',
          'matchId': 2,
          'homeTeam': {'teamName': 'A'},
          'awayTeam': {'teamName': 'B'},
        },
        {
          'cardType': 'HOT_COMMENT',
          'payload': {'commentId': 3, 'contentId': 1, 'commentText': '评论'},
        },
        {
          'cardType': 'DISCUSSION',
          'payload': {'contentId': 4, 'title': '讨论'},
        },
        {
          'cardType': 'RANKING',
          'payload': {
            'rankingType': 'PLAYER',
            'rankType': 'GOALS',
            'title': '射手榜',
          },
        },
        {
          'cardType': 'PLAYER_RATING',
          'payload': {
            'matchId': 5,
            'homeTeam': {'teamName': 'A'},
            'awayTeam': {'teamName': 'B'},
          },
        },
      ],
      'total': 6,
      'pageNum': 1,
      'pageSize': 10,
      'pages': 1,
    }).toDomain();

    expect(page.cards[0], isA<ContentFeedCard>());
    expect(page.cards[1], isA<MatchFeedCard>());
    expect(page.cards[2], isA<HotCommentFeedCard>());
    expect(page.cards[3], isA<DiscussionFeedCard>());
    expect(page.cards[4], isA<RankingFeedCard>());
    expect(page.cards[5], isA<PlayerRatingFeedCard>());
  });
}
