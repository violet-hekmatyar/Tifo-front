import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/feed/domain/feed_page.dart';
import 'package:tifo/features/feed/presentation/controllers/feed_controller.dart';
import 'package:tifo/features/feed/presentation/pages/home_feed_page.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';

void main() {
  testWidgets('comment slot is equal height and summary is exactly two lines', (
    tester,
  ) async {
    final commented = _content(1, comment: '很长的评论摘要' * 20);
    final plain = _content(2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ContentCard(card: commented, onTap: () {}),
                ),
                Expanded(
                  child: ContentCard(card: plain, onTap: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('content_comment_summary')),
    );
    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
    final cards = find.byType(ContentCard);
    expect(
      tester.getSize(cards.at(0)).height,
      tester.getSize(cards.at(1)).height,
    );
  });

  testWidgets('back-to-top fades in on downward gesture and hides upward', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FeedController(_LongFeedRepository());
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        GoRoute(path: '/app/home', builder: (_, _) => const HomeFeedPage()),
        GoRoute(path: '/search', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/publish', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedControllerProvider.overrideWith((_) => controller),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byType(CustomScrollView);
    await tester.drag(list, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 0);
    await tester.drag(list, const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    await tester.drag(list, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 0);
  });
}

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.byKey(const ValueKey('feed_back_to_top_visibility')),
    )
    .opacity;

final class _LongFeedRepository implements FeedRepositoryContract {
  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async => FeedPage(
    cards: [for (var id = 1; id <= 24; id++) _content(id)],
    total: 24,
    pageNum: 1,
    pageSize: 24,
    pages: 1,
  );
  @override
  Future<List<FollowedTeam>> loadFollowedTeams() async => const [];
}

ContentFeedCard _content(int id, {String? comment}) => ContentFeedCard(
  cardId: 'content-$id',
  rawCardType: 'CONTENT',
  contentId: id,
  contentType: 'POST',
  title: '内容 $id',
  hotComment: comment == null ? null : FeedHotComment(content: comment),
  likeCount: id,
  commentCount: id,
);
