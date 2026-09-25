import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/features/feed/presentation/widgets/feed_card_renderer.dart';
import 'package:tifo/features/feed/presentation/widgets/match_card.dart';
import 'package:tifo/features/feed/presentation/widgets/supplementary_feed_cards.dart';
import 'package:tifo/features/feed/presentation/widgets/unknown_card.dart';

void main() {
  testWidgets('match card keeps score, scheduled time and event summary', (
    tester,
  ) async {
    var matchTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                MatchCard(
                  card: MatchFeedCard(
                    cardId: 'finished-with-event',
                    rawCardType: 'MATCH',
                    matchId: 11,
                    leagueName: '旗舰联赛',
                    homeTeam: const FeedTeam(teamId: 1, teamName: '主队'),
                    awayTeam: const FeedTeam(teamId: 2, teamName: '客队'),
                    matchStatus: 'FINISHED',
                    homeScore: 2,
                    awayScore: 1,
                    matchTime: DateTime(2026, 9, 18, 20),
                    eventSummary: '主队下半场完成反超，比赛进入关键阶段。',
                  ),
                  onTap: () => matchTapped = true,
                ),
                MatchCard(
                  card: MatchFeedCard(
                    cardId: 'scheduled-without-score',
                    rawCardType: 'MATCH',
                    matchId: 12,
                    leagueName: '青年联赛',
                    homeTeam: const FeedTeam(teamId: 3, teamName: '主队二'),
                    awayTeam: const FeedTeam(teamId: 4, teamName: '客队二'),
                    matchStatus: 'SCHEDULED',
                    matchTime: DateTime(2026, 9, 19, 19, 30),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('2 : 1'), findsOneWidget);
    expect(find.text('09-19\n19:30'), findsOneWidget);
    expect(find.textContaining('完成反超'), findsOneWidget);
    expect(find.text('0 : 0'), findsNothing);
    await tester.tap(find.text('旗舰联赛'));
    expect(matchTapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'special cards collapse optional fields and keep safe fallbacks',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const DiscussionCard(
                    card: DiscussionFeedCard(
                      cardId: 'empty-discussion',
                      rawCardType: 'DISCUSSION',
                      contentId: 91,
                      title: '没有摘要的讨论',
                      summary: '',
                      commentCount: 0,
                      likeCount: 0,
                      favoriteCount: 0,
                      relationTags: [],
                    ),
                    onTap: _noop,
                  ),
                  const RankingCard(
                    card: RankingFeedCard(
                      cardId: 'empty-ranking',
                      rawCardType: 'RANKING',
                      rankingType: 'STANDING',
                      rankType: 'POINTS',
                      title: '积分榜',
                      items: [],
                    ),
                    resolveImage: _noImage,
                  ),
                  const PlayerRatingCard(
                    card: PlayerRatingFeedCard(
                      cardId: 'empty-rating',
                      rawCardType: 'PLAYER_RATING',
                      matchId: 92,
                      homeTeam: FeedTeam(teamId: 1, teamName: '主队'),
                      awayTeam: FeedTeam(teamId: 2, teamName: '客队'),
                      topPlayers: [],
                      ratingUserCount: 0,
                    ),
                    onTap: _noop,
                    resolveImage: _noImage,
                  ),
                  const HotCommentCard(
                    card: HotCommentFeedCard(
                      cardId: 'comment-with-author',
                      rawCardType: 'HOT_COMMENT',
                      commentId: 93,
                      contentId: 94,
                      commentText: '这条评论保留正文和互动数',
                      likeCount: 6,
                      replyCount: 2,
                    ),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('没有摘要的讨论'), findsOneWidget);
      expect(find.text('当前暂无排名数据'), findsOneWidget);
      expect(find.text('当前暂无球员评分'), findsOneWidget);
      expect(find.textContaining('这条评论保留正文和互动数'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supplementary cards handle nullable data and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var rankingTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HotCommentCard(
                    card: HotCommentFeedCard(
                      cardId: 'boundary-comment',
                      rawCardType: 'HOT_COMMENT',
                      commentId: 1,
                      contentId: 1,
                      commentText: '很长的评论' * 20,
                      likeCount: 3,
                      replyCount: 4,
                    ),
                    onTap: () {},
                  ),
                  DiscussionCard(
                    card: DiscussionFeedCard(
                      cardId: 'boundary-discussion',
                      rawCardType: 'DISCUSSION',
                      contentId: 2,
                      title: '很长的讨论标题' * 12,
                      commentCount: 2,
                      likeCount: 1,
                      favoriteCount: 0,
                      relationTags: [],
                    ),
                    onTap: () {},
                  ),
                  RankingCard(
                    card: const RankingFeedCard(
                      cardId: 'boundary-empty-ranking',
                      rawCardType: 'RANKING',
                      rankingType: 'UNKNOWN',
                      rankType: 'UNKNOWN',
                      title: '未知榜单',
                      items: [],
                    ),
                    resolveImage: (_) => null,
                    onTeamTap: (_) => rankingTapped = true,
                  ),
                  RankingCard(
                    card: const RankingFeedCard(
                      cardId: 'boundary-unknown-ranking',
                      rawCardType: 'RANKING',
                      rankingType: 'UNKNOWN',
                      rankType: 'UNKNOWN',
                      title: '未知类型',
                      items: [
                        FeedRankingItem(
                          rank: 1,
                          name: '不可跳转',
                          value: '1',
                          entityId: 99,
                          teamId: 88,
                        ),
                      ],
                    ),
                    resolveImage: (_) => null,
                    onTeamTap: (_) => rankingTapped = true,
                  ),
                  PlayerRatingCard(
                    card: PlayerRatingFeedCard(
                      cardId: 'boundary-rating',
                      rawCardType: 'PLAYER_RATING',
                      matchId: 3,
                      homeTeam: FeedTeam(teamId: 1, teamName: '主队' * 10),
                      awayTeam: FeedTeam(teamId: 2, teamName: '客队' * 10),
                      topPlayers: [],
                      ratingUserCount: 0,
                    ),
                    onTap: () {},
                    resolveImage: (_) => null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('当前暂无排名数据'), findsOneWidget);
    expect(find.text('当前暂无球员评分'), findsOneWidget);
    expect(find.text('vs'), findsOneWidget);
    expect(find.byType(HotCommentCard), findsOneWidget);
    final widths = [
      tester.getSize(find.byType(HotCommentCard)).width,
      tester.getSize(find.byType(DiscussionCard)).width,
      tester.getSize(find.byType(RankingCard).at(0)).width,
      tester.getSize(find.byType(RankingCard).at(1)).width,
      tester.getSize(find.byType(PlayerRatingCard)).width,
    ];
    for (final width in widths) {
      expect(width, closeTo(412, 0.1));
    }
    await tester.ensureVisible(find.text('不可跳转'));
    await tester.tap(find.text('不可跳转'));
    expect(rankingTapped, isFalse);
    expect(find.byType(HotCommentCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known ranking entities keep their click callbacks', (
    tester,
  ) async {
    var teamId = 0;
    var playerId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RankingCard(
                card: const RankingFeedCard(
                  cardId: 'known-team',
                  rawCardType: 'RANKING',
                  rankingType: 'TEAM',
                  rankType: 'POINTS',
                  title: '球队榜',
                  items: [
                    FeedRankingItem(rank: 1, name: '球队', value: '1', teamId: 7),
                  ],
                ),
                resolveImage: (_) => null,
                onTeamTap: (id) => teamId = id,
              ),
              RankingCard(
                card: const RankingFeedCard(
                  cardId: 'known-player',
                  rawCardType: 'RANKING',
                  rankingType: 'PLAYER',
                  rankType: 'GOALS',
                  title: '球员榜',
                  items: [
                    FeedRankingItem(
                      rank: 1,
                      name: '球员',
                      value: '1',
                      entityId: 8,
                    ),
                  ],
                ),
                resolveImage: (_) => null,
                onPlayerTap: (id) => playerId = id,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('ranking_team_7')));
    await tester.tap(find.byKey(const ValueKey('ranking_player_8')));
    expect(teamId, 7);
    expect(playerId, 8);
  });

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

void _noop() {}
String? _noImage(String? _) => null;

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
