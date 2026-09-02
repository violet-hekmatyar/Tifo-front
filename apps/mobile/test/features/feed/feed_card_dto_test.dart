import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
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
      'algorithmVersion': 'CF_V1',
      'impressionId': 'imp-9',
      'position': 3,
      'reasonCode': 'INTEREST',
      'reason': '因为你关注这支球队',
    }).toDomain();

    expect(card, isA<ContentFeedCard>());
    final content = card as ContentFeedCard;
    expect(content.contentId, 9);
    expect(content.author?.nickname, '看台作者');
    expect(content.hotComment?.content, '关键换人改变比赛');
    expect(content.publishTime, isNotNull);
    expect(content.cardType, FeedCardType.content);
    expect(content.attribution.algorithmVersion, 'CF_V1');
    expect(content.attribution.impressionId, 'imp-9');
    expect(content.attribution.position, 3);
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

  test('parses all four Backend V1 payload card types', () {
    final hotComment = FeedCardDto.fromRaw({
      'cardId': 'HOT_COMMENT_1',
      'cardType': 'HOT_COMMENT',
      'payload': {
        'commentId': 1,
        'contentId': 2,
        'commentText': '高质量评论',
        'commentAuthor': {'userId': 3, 'nickname': '用户'},
        'likeCount': 20,
        'replyCount': 4,
        'hotScore': 28.5,
        'contentTitle': '比赛讨论',
        'contentType': 'POST',
      },
    }).toDomain();
    final discussion = FeedCardDto.fromRaw({
      'cardId': 'DISCUSSION_2',
      'cardType': 'DISCUSSION',
      'payload': {
        'contentId': 2,
        'title': '谁是本场最佳？',
        'publishTime': '2026-08-30T12:30:00',
        'commentCount': 8,
        'likeCount': 5,
        'favoriteCount': 1,
        'relationTags': [
          {
            'relationType': 'TEAM',
            'relationId': 9007199254740991,
            'relationName': '主队',
          },
        ],
      },
    }).toDomain();
    final ranking = FeedCardDto.fromRaw({
      'cardId': 'RANKING_PLAYER_GOALS',
      'cardType': 'RANKING',
      'payload': {
        'rankingType': 'PLAYER',
        'rankType': 'GOALS',
        'leagueId': 1,
        'seasonId': 2,
        'title': '射手榜',
        'items': [
          {'rank': 1, 'entityId': 3, 'name': '球员', 'value': '9'},
        ],
      },
    }).toDomain();
    final rating = FeedCardDto.fromRaw({
      'cardId': 'PLAYER_RATING_8',
      'cardType': 'PLAYER_RATING',
      'payload': {
        'matchId': 8,
        'homeTeam': {'teamId': 1, 'teamName': '主队'},
        'awayTeam': {'teamId': 2, 'teamName': '客队'},
        'topPlayers': [
          {
            'playerId': 7,
            'playerName': '球员',
            'officialRating': 8.2,
            'userRatingAverage': 8.5,
            'userRatingCount': 12,
          },
        ],
        'ratingUserCount': 20,
      },
    }).toDomain();

    expect(hotComment, isA<HotCommentFeedCard>());
    expect((hotComment as HotCommentFeedCard).hotScore, 28.5);
    expect(discussion, isA<DiscussionFeedCard>());
    expect(
      (discussion as DiscussionFeedCard).relationTags.single.id,
      9007199254740991,
    );
    expect(ranking, isA<RankingFeedCard>());
    expect((ranking as RankingFeedCard).items.single.value, '9');
    expect(rating, isA<PlayerRatingFeedCard>());
    expect(
      (rating as PlayerRatingFeedCard).topPlayers.single.userRatingAverage,
      8.5,
    );
  });

  test('legacy card aliases no longer masquerade as frozen card types', () {
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
    expect(content, isA<UnknownFeedCard>());
    expect(content.cardType, FeedCardType.unknown);
    expect(match, isA<UnknownFeedCard>());
    expect(match.cardType, FeedCardType.unknown);
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

  test('discussion keeps relation identity when its display name is null', () {
    final card =
        FeedCardDto.fromRaw({
              'cardType': 'DISCUSSION',
              'payload': {
                'contentId': 2,
                'title': '讨论',
                'relationTags': [
                  {
                    'relationType': 'TEAM',
                    'relationId': 7,
                    'relationName': null,
                  },
                ],
              },
            }).toDomain()
            as DiscussionFeedCard;

    expect(card.relationTags.single.id, 7);
    expect(card.relationTags.single.name, isNull);
  });
}
