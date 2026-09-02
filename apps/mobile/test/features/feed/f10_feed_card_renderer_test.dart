import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/features/feed/presentation/widgets/feed_card_renderer.dart';
import 'package:tifo/features/feed/presentation/widgets/match_card.dart';
import 'package:tifo/features/feed/presentation/widgets/supplementary_feed_cards.dart';
import 'package:tifo/features/feed/presentation/widgets/unknown_card.dart';

void main() {
  testWidgets(
    'all six Feed card types have production renderers and unknown stays safe',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(
                appEnv: 'test',
                apiBaseUrl: 'http://localhost:8080',
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final card in _cards) FeedCardRenderer(card: card),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ContentCard), findsOneWidget);
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.byType(HotCommentCard), findsOneWidget);
      expect(find.byType(DiscussionCard), findsOneWidget);
      expect(find.byType(RankingCard), findsNWidgets(2));
      expect(find.byKey(const ValueKey('ranking_team_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('ranking_player_9')), findsOneWidget);
      expect(find.byType(PlayerRatingCard), findsOneWidget);
      expect(find.byType(UnknownCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _home = FeedTeam(teamId: 1, teamName: '主队');
const _away = FeedTeam(teamId: 2, teamName: '客队');
const _cards = <FeedCard>[
  ContentFeedCard(
    cardId: 'content',
    rawCardType: 'CONTENT',
    contentId: 1,
    contentType: 'POST',
    title: '内容',
    likeCount: 1,
    commentCount: 2,
  ),
  MatchFeedCard(
    cardId: 'match',
    rawCardType: 'MATCH',
    matchId: 2,
    leagueName: '联赛',
    homeTeam: _home,
    awayTeam: _away,
    matchStatus: 'SCHEDULED',
  ),
  HotCommentFeedCard(
    cardId: 'comment',
    rawCardType: 'HOT_COMMENT',
    commentId: 3,
    contentId: 1,
    commentText: '好评论',
    likeCount: 4,
    replyCount: 1,
  ),
  DiscussionFeedCard(
    cardId: 'discussion',
    rawCardType: 'DISCUSSION',
    contentId: 4,
    title: '讨论',
    commentCount: 5,
    likeCount: 6,
    favoriteCount: 1,
    relationTags: [],
  ),
  RankingFeedCard(
    cardId: 'ranking',
    rawCardType: 'RANKING',
    rankingType: 'STANDING',
    rankType: 'POINTS',
    title: '积分榜',
    items: [FeedRankingItem(rank: 1, name: '主队', value: '40', teamId: 1)],
  ),
  RankingFeedCard(
    cardId: 'player-ranking',
    rawCardType: 'RANKING',
    rankingType: 'PLAYER',
    rankType: 'GOALS',
    title: '射手榜',
    items: [
      FeedRankingItem(rank: 1, entityId: 9, name: '球员', value: '12', teamId: 1),
    ],
  ),
  PlayerRatingFeedCard(
    cardId: 'rating',
    rawCardType: 'PLAYER_RATING',
    matchId: 2,
    homeTeam: _home,
    awayTeam: _away,
    topPlayers: [
      FeedRatingPlayer(
        playerId: 8,
        playerName: '球员',
        officialRating: 8.2,
        userRatingCount: 2,
      ),
    ],
    ratingUserCount: 2,
  ),
  UnknownFeedCard(cardId: 'unknown', rawCardType: 'POLL'),
];
