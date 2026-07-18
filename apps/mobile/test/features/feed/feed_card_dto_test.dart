import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/feed/data/dto/feed_card_dto.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';

void main() {
  test('parses the real CONTENT response shape and optional fields', () {
    final card = FeedCardDto.fromRaw({
      'cardId': 'CONTENT_9',
      'cardType': 'CONTENT',
      'contentId': 9,
      'contentType': 'POST',
      'title': '赛后观察',
      'coverUrl': '/uploads/cover.jpg',
      'author': {'userId': 2, 'nickname': '看台作者', 'verified': true},
      'hotComment': {'content': '关键换人改变比赛'},
      'likeCount': 12,
      'commentCount': 3,
      'publishTime': '2026-07-17T10:00:00',
    }).toDomain();

    expect(card, isA<ContentFeedCard>());
    final content = card as ContentFeedCard;
    expect(content.contentId, 9);
    expect(content.author?.nickname, '看台作者');
    expect(content.hotComment?.content, '关键换人改变比赛');
    expect(content.publishTime, isNotNull);
  });

  test('parses MATCH and does not invent absent scores', () {
    final card =
        FeedCardDto.fromRaw({
              'cardType': 'MATCH',
              'matchId': 8,
              'leagueName': '测试联赛',
              'homeTeam': {'teamId': 1, 'teamName': '主队'},
              'awayTeam': {'teamId': 2, 'teamName': '客队'},
              'matchStatus': 'SCHEDULED',
            }).toDomain()
            as MatchFeedCard;

    expect(card.cardId, 'MATCH_8');
    expect(card.hasScore, isFalse);
    expect(card.homeScore, isNull);
    expect(card.awayScore, isNull);
  });

  test('keeps documented aliases compatible', () {
    final content = FeedCardDto.fromRaw({
      'cardType': 'CONTENT_CARD',
      'contentId': 1,
      'title': '兼容内容',
    }).toDomain();
    final match = FeedCardDto.fromRaw({
      'cardType': 'MATCH_CARD',
      'matchId': 2,
      'homeTeam': {'teamName': 'A'},
      'awayTeam': {'teamName': 'B'},
    }).toDomain();
    expect(content, isA<ContentFeedCard>());
    expect(match, isA<MatchFeedCard>());
  });

  test('unknown and malformed cards degrade locally', () {
    expect(
      FeedCardDto.fromRaw({'cardId': 'x', 'cardType': 'POLL'}).toDomain(),
      isA<UnknownFeedCard>(),
    );
    expect(FeedCardDto.fromRaw('bad').toDomain(), isA<UnknownFeedCard>());
    expect(
      FeedCardDto.fromRaw({'cardType': 'CONTENT', 'contentId': 1}).toDomain(),
      isA<UnknownFeedCard>(),
    );
  });
}
