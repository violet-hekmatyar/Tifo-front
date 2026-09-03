import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/presentation/models/feed_recommendation_source.dart';
import 'package:tifo/features/feed/presentation/widgets/recommendation_exposure.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/recommendation/presentation/recommendation_behavior_dispatcher.dart';

void main() {
  test('all six feed cards map to real recommendation targets', () {
    const team = FeedTeam(teamId: 1, teamName: 'team');
    final cards = <FeedCard>[
      const ContentFeedCard(
        cardId: 'c',
        rawCardType: 'CONTENT',
        contentId: 1,
        contentType: 'POST',
        title: 'content',
        likeCount: 0,
        commentCount: 0,
      ),
      const MatchFeedCard(
        cardId: 'm',
        rawCardType: 'MATCH',
        matchId: 2,
        leagueName: 'league',
        homeTeam: team,
        awayTeam: team,
        matchStatus: 'FINISHED',
      ),
      const HotCommentFeedCard(
        cardId: 'h',
        rawCardType: 'HOT_COMMENT',
        commentId: 3,
        contentId: 1,
        commentText: 'comment',
        likeCount: 0,
        replyCount: 0,
      ),
      const DiscussionFeedCard(
        cardId: 'd',
        rawCardType: 'DISCUSSION',
        contentId: 4,
        title: 'discussion',
        commentCount: 0,
        likeCount: 0,
        favoriteCount: 0,
        relationTags: [],
      ),
      const RankingFeedCard(
        cardId: 'r',
        rawCardType: 'RANKING',
        rankingType: 'TEAM',
        rankType: 'POINTS',
        leagueId: 5,
        title: 'ranking',
        items: [],
      ),
      const PlayerRatingFeedCard(
        cardId: 'p',
        rawCardType: 'PLAYER_RATING',
        matchId: 6,
        homeTeam: team,
        awayTeam: team,
        topPlayers: [],
        ratingUserCount: 0,
      ),
    ];
    expect(cards.map((card) => recommendationSourceFor(card)!.targetType), [
      RecommendationTargetType.content,
      RecommendationTargetType.match,
      RecommendationTargetType.comment,
      RecommendationTargetType.content,
      RecommendationTargetType.ranking,
      RecommendationTargetType.playerRating,
    ]);
  });

  testWidgets('EXPOSE is sent only after the card becomes visible', (
    tester,
  ) async {
    final repository = _Repository();
    final dispatcher = RecommendationBehaviorDispatcher(
      repository,
      batchDelay: const Duration(days: 1),
    );
    addTearDown(dispatcher.dispose);
    const source = RecommendationSourceContext(
      targetType: RecommendationTargetType.content,
      targetId: 9,
      attribution: RecommendationAttribution(impressionId: 'visible-9'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationBehaviorDispatcherProvider.overrideWithValue(
            dispatcher,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 1200),
                  RecommendationExposure(
                    source: source,
                    child: SizedBox(height: 100, child: Text('target')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await dispatcher.flush();
    expect(repository.events, isEmpty);

    await tester.scrollUntilVisible(find.text('target'), 400);
    await tester.pump();
    await dispatcher.flush();
    expect(
      repository.events.single.behaviorType,
      RecommendationBehaviorType.expose,
    );
    expect(
      repository.events.single.source.attribution.impressionId,
      'visible-9',
    );

    const refreshedSource = RecommendationSourceContext(
      targetType: RecommendationTargetType.content,
      targetId: 9,
      attribution: RecommendationAttribution(
        impressionId: 'visible-9',
        requestId: 'new-request',
        position: 2,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationBehaviorDispatcherProvider.overrideWithValue(
            dispatcher,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 1200),
                  RecommendationExposure(
                    source: refreshedSource,
                    child: SizedBox(height: 100, child: Text('target')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await dispatcher.flush();
    expect(repository.events, hasLength(2));
    expect(repository.events.last.source.attribution.requestId, 'new-request');
  });
}

final class _Repository implements RecommendationBehaviorRepositoryContract {
  final List<RecommendationBehaviorEvent> events = [];

  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> value,
  ) async {
    events.addAll(value);
    return RecommendationBehaviorBatchResult(
      received: value.length,
      saved: value.length,
      duplicated: 0,
      rejected: 0,
    );
  }
}
