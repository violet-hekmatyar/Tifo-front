import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/search/data/search_repository.dart';
import 'package:tifo/features/search/domain/search_models.dart';
import 'package:tifo/features/search/presentation/controllers/global_search_controller.dart';

void main() {
  test('blank keyword makes no request and clears prior results', () async {
    final repository = _FakeSearchRepository();
    final controller = GlobalSearchController(repository);
    await controller.search('   ');
    expect(repository.requests, isEmpty);
    expect(controller.state.status, GlobalSearchStatus.idle);
  });

  test(
    'pagination deduplicates and category change resets old results',
    () async {
      final repository = _FakeSearchRepository(
        pages: {
          1: _page(1, [
            _entity(SearchEntityType.team, 1),
            _entity(SearchEntityType.player, 2),
          ], pages: 2),
          2: _page(2, [
            _entity(SearchEntityType.team, 1),
            _entity(SearchEntityType.content, 3),
          ], pages: 2),
        },
      );
      final controller = GlobalSearchController(repository);

      await controller.search('曼');
      await controller.loadMore();
      expect(controller.state.records.map((item) => item.entityId), [1, 2, 3]);

      repository.pages[1] = _page(1, [_entity(SearchEntityType.team, 4)]);
      await controller.selectType(SearchEntityType.team);
      expect(controller.state.entityType, SearchEntityType.team);
      expect(controller.state.records.map((item) => item.entityId), [4]);
      expect(repository.requests.last.entityType, SearchEntityType.team);
    },
  );

  test('new category request wins over stale in-flight response', () async {
    final old = Completer<SearchPageResult>();
    final repository = _FakeSearchRepository(deferred: old);
    final controller = GlobalSearchController(repository);
    final initial = controller.search('曼');

    repository
      ..deferred = null
      ..pages[1] = _page(1, [_entity(SearchEntityType.player, 7)]);
    await controller.selectType(SearchEntityType.player);
    old.complete(_page(1, [_entity(SearchEntityType.team, 1)]));
    await initial;

    expect(controller.state.entityType, SearchEntityType.player);
    expect(controller.state.records.single.entityId, 7);
  });

  test('failure exposes retry and retry can recover', () async {
    final repository = _FakeSearchRepository(
      error: const NetworkException('down'),
    );
    final controller = GlobalSearchController(repository);
    await controller.search('曼');
    expect(controller.state.status, GlobalSearchStatus.failure);
    expect(controller.state.message, contains('网络连接失败'));

    repository
      ..error = null
      ..pages[1] = _page(1, [_entity(SearchEntityType.team, 1)]);
    await controller.retry();
    expect(controller.state.status, GlobalSearchStatus.ready);
  });
}

typedef _Request = ({
  String keyword,
  SearchEntityType? entityType,
  int pageNum,
});

final class _FakeSearchRepository implements SearchRepositoryContract {
  _FakeSearchRepository({
    Map<int, SearchPageResult>? pages,
    this.deferred,
    this.error,
  }) : pages = pages ?? {};

  final Map<int, SearchPageResult> pages;
  final List<_Request> requests = [];
  Completer<SearchPageResult>? deferred;
  AppNetworkException? error;

  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) async {
    requests.add((keyword: keyword, entityType: entityType, pageNum: pageNum));
    if (error case final error?) throw error;
    if (deferred case final pending?) return pending.future;
    return pages[pageNum] ?? _page(pageNum, []);
  }
}

SearchPageResult _page(int page, List<SearchEntity> records, {int pages = 1}) =>
    SearchPageResult(
      records: records,
      total: records.length,
      pageNum: page,
      pageSize: 20,
      pages: pages,
    );

SearchEntity _entity(SearchEntityType type, int id) => SearchEntity(
  type: type,
  rawType: type.wireValue,
  entityId: id,
  name: '${type.wireValue} $id',
);
