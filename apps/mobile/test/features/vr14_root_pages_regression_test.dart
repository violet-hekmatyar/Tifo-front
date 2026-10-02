import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/data/dto/feed_page_dto.dart';
import 'package:tifo/features/feed/data/dto/feed_card_dto.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/feed/domain/feed_page.dart';
import 'package:tifo/features/feed/presentation/controllers/feed_controller.dart';
import 'package:tifo/features/feed/presentation/models/feed_display_sections.dart';
import 'package:tifo/features/feed/presentation/pages/home_feed_page.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/features/feed/presentation/widgets/feed_filter_bar.dart';
import 'package:tifo/features/feed/presentation/widgets/match_card.dart';
import 'package:tifo/features/feed/presentation/widgets/supplementary_feed_cards.dart';

void main() {
  final envelope = _recordedFeedResponse();
  final response = envelope['data'] as Map<String, dynamic>;
  final recordedPage = FeedPageDto.fromRaw(response).toDomain();

  test(
    'VR14 R2 fixture is the real page-one contract and has required mix',
    () {
      expect(envelope['code'], 0);
      expect(response['pageNum'], 1);
      expect(response['pageSize'], 10);
      expect(recordedPage.pageSize, 10);
      expect(recordedPage.cards, hasLength(10));
      expect(recordedPage.cards.first, isA<MatchFeedCard>());
      expect(
        recordedPage.cards.map((card) => card.rawCardType).toList(),
        const [
          'MATCH',
          'CONTENT',
          'RANKING',
          'DISCUSSION',
          'PLAYER_RATING',
          'CONTENT',
          'HOT_COMMENT',
          'CONTENT',
          'CONTENT',
          'CONTENT',
        ],
      );
      expect(recordedPage.cards.whereType<RankingFeedCard>(), hasLength(1));
      expect(
        recordedPage.cards.whereType<PlayerRatingFeedCard>(),
        hasLength(1),
      );
      expect(
        recordedPage.cards.whereType<DiscussionFeedCard>().length +
            recordedPage.cards.whereType<HotCommentFeedCard>().length,
        greaterThanOrEqualTo(1),
      );
      expect(
        recordedPage.cards.whereType<ContentFeedCard>().length,
        greaterThanOrEqualTo(3),
      );
      expect(
        recordedPage.cards.map((card) => card.cardKey).toSet(),
        hasLength(recordedPage.cards.length),
      );
    },
  );

  test('VR14 R3 visually balances the real feed prefix without reordering', () {
    final columns = assignFeedMasonryColumns(recordedPage.cards);
    expect(columns, hasLength(2));
    expect(columns[0].first, isA<MatchFeedCard>());
    final firstContent = recordedPage.cards.whereType<ContentFeedCard>().first;
    expect(columns[1], contains(firstContent));
    final supportColumnIndexes = <int>{};
    for (var column = 0; column < columns.length; column++) {
      final positions = columns[column]
          .map((card) => card.attribution.position)
          .whereType<int>()
          .toList();
      expect(positions, orderedEquals([...positions]..sort()));
      if (columns[column].any(
        (card) =>
            card is RankingFeedCard ||
            card is PlayerRatingFeedCard ||
            card is DiscussionFeedCard ||
            card is HotCommentFeedCard,
      )) {
        supportColumnIndexes.add(column);
      }
    }
    expect(supportColumnIndexes, hasLength(2));
    expect(columns.expand((column) => column), hasLength(10));
  });

  test(
    'VR14 R3 masonry keeps the existing prefix fixed when a page appends',
    () {
      final firstPage = assignFeedMasonryColumns(recordedPage.cards);
      final appended = ContentFeedCard(
        cardId: 'CONTENT_NEXT_PAGE',
        cardKey: 'CONTENT:NEXT_PAGE',
        rawCardType: 'CONTENT',
        contentId: 16000000000000202,
        contentType: 'POST',
        title: '下一页内容',
        likeCount: 0,
        commentCount: 0,
      );
      final withNextPage = assignFeedMasonryColumns([
        ...recordedPage.cards,
        appended,
      ]);

      for (var column = 0; column < firstPage.length; column++) {
        expect(
          withNextPage[column].take(firstPage[column].length),
          orderedEquals(firstPage[column]),
        );
      }
      expect(withNextPage.expand((column) => column), contains(appended));
    },
  );

  test('VR14 R3 parses transfer brief only from explicit display data', () {
    final parsed = FeedCardDto.fromRaw({
      'cardId': 'CONTENT_16000000000002001',
      'cardKey': 'CONTENT:16000000000002001',
      'cardType': 'CONTENT',
      'contentId': 16000000000002001,
      'contentType': 'POST',
      'title': '演示转会快讯｜非真实交易数据',
      'likeCount': 0,
      'commentCount': 0,
      'displayType': 'TRANSFER_BRIEF',
      'displayData': {
        'transferBrief': {
          'playerId': 14000000000000067,
          'playerName': '黄云帆',
          'fromTeamId': 13000000000000012,
          'fromTeamName': '尤文图斯',
          'toTeamId': 13000000000000011,
          'toTeamName': 'AC米兰',
          'feeLabel': '演示数据',
          'durationLabel': '演示数据',
        },
      },
    }).toDomain();
    expect(parsed, isA<ContentFeedCard>());
    final transfer = parsed as ContentFeedCard;
    expect(transfer.displayType, 'TRANSFER_BRIEF');
    expect(transfer.transferBrief?.playerName, '黄云帆');

    final ordinary =
        FeedCardDto.fromRaw({
              'cardId': 'CONTENT_1',
              'cardType': 'CONTENT',
              'contentId': 1,
              'contentType': 'POST',
              'title': '正文标题中提到转会，但不是专用卡片',
              'displayData': {
                'transferBrief': {
                  'playerId': 14000000000000067,
                  'playerName': '黄云帆',
                  'fromTeamId': 13000000000000012,
                  'fromTeamName': '尤文图斯',
                  'toTeamId': 13000000000000011,
                  'toTeamName': 'AC米兰',
                },
              },
            }).toDomain()
            as ContentFeedCard;
    expect(ordinary.transferBrief, isNull);
  });

  testWidgets(
    'VR14 R3 transfer brief uses explicit data and opens its content',
    (tester) async {
      tester.view.physicalSize = const Size(176, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      const card = ContentFeedCard(
        cardId: 'CONTENT_TRANSFER_DEMO',
        cardKey: 'CONTENT:TRANSFER_DEMO',
        rawCardType: 'CONTENT',
        contentId: 16000000000002001,
        contentType: 'POST',
        displayType: 'TRANSFER_BRIEF',
        title: '演示转会动态',
        likeCount: 0,
        commentCount: 0,
        transferBrief: FeedTransferBrief(
          playerId: 14000000000000067,
          playerName: '演示球员',
          playerMeta: '演示资料',
          fromTeamId: 13000000000000012,
          fromTeamName: '尤文图斯',
          toTeamId: 13000000000000011,
          toTeamName: 'AC米兰',
          feeLabel: '演示数据',
          durationLabel: '演示数据',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransferBriefCard(
              card: card,
              brief: card.transferBrief!,
              resolveImage: (url) => url,
              onTap: () => opened = true,
            ),
          ),
        ),
      );
      expect(find.byType(TransferBriefCard), findsOneWidget);
      expect(
        tester.getSize(find.byType(TransferBriefCard)).width,
        closeTo(176, 1),
      );
      expect(find.text('转会快讯'), findsOneWidget);
      expect(find.text('演示球员'), findsOneWidget);
      expect(find.text('尤文图斯'), findsOneWidget);
      expect(find.text('AC米兰'), findsOneWidget);
      expect(find.text('演示数据'), findsNWidgets(2));
      await tester.tap(find.byType(TransferBriefCard));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('VR14 R3 match card shows kickoff time in one complete line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scheduled = MatchFeedCard(
      cardId: 'MATCH_CLOCK_TEST',
      rawCardType: 'MATCH',
      matchId: 15000000000000060,
      leagueName: '意甲',
      homeTeam: FeedTeam(teamId: 13000000000000012, teamName: '尤文图斯'),
      awayTeam: FeedTeam(teamId: 13000000000000011, teamName: 'AC米兰'),
      matchStatus: 'SCHEDULED',
      matchTime: DateTime(2026, 7, 18, 22),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchCard(card: scheduled, onTap: _noop),
        ),
      ),
    );
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('07-18'), findsOneWidget);
    final clock = tester.getRect(
      find.byKey(const ValueKey('match_score_or_clock')),
    );
    expect(clock.width, greaterThan(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'VR14 R2 renders the recorded API match at upper left with real card families',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 904));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _RecordedApiFeedRepository(recordedPage);
      final controller = FeedController(repository);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedControllerProvider.overrideWith((_) => controller),
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 904),
                devicePixelRatio: 2,
              ),
              child: child!,
            ),
            home: const HomeFeedPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_RecordedApiFeedRepository.lastPageSize, 10);
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.byType(RankingCard), findsOneWidget);
      expect(find.byType(PlayerRatingCard), findsOneWidget);
      expect(find.byType(DiscussionCard), findsOneWidget);
      expect(find.byType(ContentCard), findsAtLeastNWidgets(3));

      final match = tester.getRect(find.byType(MatchCard));
      final leadingContent = recordedPage.cards
          .whereType<ContentFeedCard>()
          .first;
      final firstContent = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ContentCard &&
              widget.card.contentId == leadingContent.contentId,
        ),
      );
      expect(match.left, lessThan(firstContent.left));
      expect(match.top, lessThan(firstContent.top + 1));
      expect(match.top, lessThan(330));
      expect(firstContent.width, closeTo(175.5, 0.5));
    },
  );

  for (final width in [411.0, 360.0]) {
    testWidgets('VR14 R3 keeps readable team names scrollable at ${width}dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: FeedFilterBar(
                selected: FeedFilter.recommend,
                onSelected: (_) {},
                onManageTeams: () {},
                teams: const [
                  FollowedTeam(
                    teamId: 13000000000000011,
                    teamName: 'Barcelona',
                  ),
                  FollowedTeam(
                    teamId: 13000000000000012,
                    teamName: 'Real Madrid',
                  ),
                  FollowedTeam(
                    teamId: 13000000000000013,
                    teamName: 'Bayern Munich',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('home_feed_navigation'));
      final firstTeam = find.byKey(
        const ValueKey('followed_team_13000000000000011'),
      );
      expect(
        find.byKey(const ValueKey('manage_followed_teams')),
        findsOneWidget,
      );
      expect(find.text('Barcelona'), findsOneWidget);
      expect(tester.getSize(firstTeam).width, greaterThan(70));
      expect(tester.getRect(row).height, 46);
      await tester.drag(row, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(find.text('Real Madrid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

void _noop() {}

Map<String, dynamic> _recordedFeedResponse() =>
    jsonDecode(
          File(
            'test/fixtures/vr14_r2_home_recommend_page1.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

final class _RecordedApiFeedRepository implements FeedRepositoryContract {
  _RecordedApiFeedRepository(this._page);

  final FeedPage _page;
  static int lastPageSize = 0;

  @override
  Future<List<FollowedTeam>> loadFollowedTeams() async => const [];

  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async {
    lastPageSize = pageSize;
    return FeedPage(
      cards: _page.cards,
      total: _page.total,
      pageNum: pageNum,
      pageSize: pageSize,
      pages: _page.pages,
      nextCursor: _page.nextCursor,
      attribution: _page.attribution,
    );
  }
}
