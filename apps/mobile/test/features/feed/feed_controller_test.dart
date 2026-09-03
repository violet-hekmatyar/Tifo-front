import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/feed/domain/feed_page.dart';
import 'package:tifo/features/feed/presentation/controllers/feed_controller.dart';

void main() {
  test(
    'initial load exposes ready and empty states with followed teams',
    () async {
      final repository = _FakeFeedRepository(
        pages: {
          1: _page(1, [_content('a')]),
        },
      );
      final controller = FeedController(repository);
      await controller.loadInitial();
      expect(controller.state.status, FeedLoadStatus.ready);
      expect(controller.state.followedTeams.single.teamName, '主队');

      repository.pages[1] = _page(1, []);
      await controller.loadInitial();
      expect(controller.state.status, FeedLoadStatus.empty);
    },
  );

  test('initial failure has friendly retryable state', () async {
    final repository = _FakeFeedRepository(
      error: const NetworkException('down'),
    );
    final controller = FeedController(repository);
    await controller.loadInitial();
    expect(controller.state.status, FeedLoadStatus.failure);
    expect(controller.state.message, contains('网络连接失败'));

    repository
      ..error = null
      ..pages[1] = _page(1, [_content('recovered')]);
    await controller.loadInitial();
    expect(controller.state.status, FeedLoadStatus.ready);
  });

  test(
    'pagination deduplicates cards and ignores concurrent requests',
    () async {
      final secondPage = Completer<FeedPage>();
      final repository = _FakeFeedRepository(
        pages: {
          1: _page(1, [_content('a')], pages: 2),
        },
        deferred: {2: secondPage},
      );
      final controller = FeedController(repository);
      await controller.loadInitial();
      final first = controller.loadMore();
      final ignored = controller.loadMore();
      expect(repository.requests.where((page) => page == 2).length, 1);
      secondPage.complete(_page(2, [_content('a'), _content('b')], pages: 2));
      await Future.wait([first, ignored]);
      expect(controller.state.cards.map((card) => card.cardId), ['a', 'b']);
      expect(controller.state.hasMore, isFalse);
    },
  );

  test('append failure retains existing cards and can retry', () async {
    final repository = _FakeFeedRepository(
      pages: {
        1: _page(1, [_content('a')], pages: 2),
      },
    );
    final controller = FeedController(repository);
    await controller.loadInitial();
    repository.error = const TimeoutException('slow');
    await controller.loadMore();
    expect(controller.state.cards.single.cardId, 'a');
    expect(controller.state.appendMessage, contains('请求超时'));
    repository
      ..error = null
      ..pages[2] = _page(2, [_content('b')], pages: 2);
    await controller.loadMore();
    expect(controller.state.cards.length, 2);
  });

  test('filter change discards stale responses', () async {
    final old = Completer<FeedPage>();
    final repository = _FakeFeedRepository(deferred: {1: old});
    final controller = FeedController(repository);
    final initial = controller.loadInitial();
    repository
      ..deferred.clear()
      ..pages[1] = _page(1, [_content('news')]);
    await controller.selectFilter(FeedFilter.news);
    old.complete(_page(1, [_content('stale')]));
    await initial;
    expect(controller.state.filter, FeedFilter.news);
    expect(controller.state.cards.single.cardId, 'news');
  });

  test('refresh replaces first page while preserving selection', () async {
    final repository = _FakeFeedRepository(
      pages: {
        1: _page(1, [_content('a')]),
      },
    );
    final controller = FeedController(repository);
    await controller.loadInitial();
    await controller.selectTeam(7);
    repository.pages[1] = _page(1, [_content('fresh')]);
    await controller.refresh();
    expect(controller.state.teamId, 7);
    expect(controller.state.cards.map((card) => card.cardId), ['fresh', 'a']);
  });

  test(
    'refresh failure keeps old cards and duplicate refresh is ignored',
    () async {
      final refresh = Completer<FeedPage>();
      final repository = _FakeFeedRepository(
        pages: {
          1: _page(1, [_content('old')]),
        },
      );
      final controller = FeedController(repository);
      await controller.loadInitial();
      repository.deferred[1] = refresh;
      final first = controller.refresh();
      final duplicate = controller.refresh();
      expect(repository.requests.where((page) => page == 1).length, 2);
      refresh.completeError(const NetworkException('down'));
      await Future.wait([first, duplicate]);
      expect(controller.state.cards.single.cardId, 'old');
      expect(controller.state.message, contains('网络连接失败'));
    },
  );

  test('pagination deduplicates by content identity across card ids', () async {
    final repository = _FakeFeedRepository(
      pages: {
        1: _page(1, [_contentWithIdentity('card-a', 9)], pages: 2),
        2: _page(2, [_contentWithIdentity('card-b', 9)], pages: 2),
      },
    );
    final controller = FeedController(repository);
    await controller.loadInitial();
    await controller.loadMore();
    expect(controller.state.cards, hasLength(1));
    expect(controller.state.cards.single.cardId, 'card-a');
  });

  test(
    'pagination only appends and refresh keeps loaded unique cards',
    () async {
      final repository = _FakeFeedRepository(
        pages: {
          1: _page(1, [_content('a'), _content('b')], pages: 2),
          2: _page(2, [_content('c')], pages: 2),
        },
      );
      final controller = FeedController(repository);
      await controller.loadInitial();
      await controller.loadMore();
      expect(controller.state.cards.map((card) => card.cardId), [
        'a',
        'b',
        'c',
      ]);

      repository.pages[1] = _page(1, [
        _content('fresh'),
        _content('a'),
      ], pages: 2);
      await controller.refresh();
      expect(controller.state.cards.map((card) => card.cardId), [
        'fresh',
        'a',
        'b',
        'c',
      ]);
      expect(controller.state.pageNum, 2);
      expect(controller.state.hasMore, isFalse);
    },
  );
}

final class _FakeFeedRepository implements FeedRepositoryContract {
  _FakeFeedRepository({
    Map<int, FeedPage>? pages,
    Map<int, Completer<FeedPage>>? deferred,
    this.error,
  }) : pages = pages ?? {},
       deferred = deferred ?? {};

  final Map<int, FeedPage> pages;
  final Map<int, Completer<FeedPage>> deferred;
  final List<int> requests = [];
  AppNetworkException? error;

  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async {
    requests.add(pageNum);
    if (error case final error?) throw error;
    if (deferred[pageNum] case final completer?) return completer.future;
    return pages[pageNum] ?? _page(pageNum, []);
  }

  @override
  Future<List<FollowedTeam>> loadFollowedTeams() async => const [
    FollowedTeam(teamId: 7, teamName: '主队'),
  ];
}

FeedPage _page(int page, List<FeedCard> cards, {int pages = 1}) => FeedPage(
  cards: cards,
  total: cards.length,
  pageNum: page,
  pageSize: 10,
  pages: pages,
);

ContentFeedCard _content(String id) => ContentFeedCard(
  cardId: id,
  rawCardType: 'CONTENT',
  contentId: id.hashCode,
  contentType: 'POST',
  title: id,
  likeCount: 0,
  commentCount: 0,
);

ContentFeedCard _contentWithIdentity(String cardId, int contentId) =>
    ContentFeedCard(
      cardId: cardId,
      rawCardType: 'CONTENT',
      contentId: contentId,
      contentType: 'POST',
      title: cardId,
      likeCount: 0,
      commentCount: 0,
    );
