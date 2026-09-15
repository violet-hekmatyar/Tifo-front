import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/search/data/search_repository.dart';
import 'package:tifo/features/search/domain/search_models.dart';
import 'package:tifo/features/search/presentation/pages/global_search_page.dart';

void main() {
  testWidgets('SEA-03 idle/loading/empty/failure/retry states are observable', (
    tester,
  ) async {
    final repository = _StateRepository();
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.byKey(const ValueKey('search_idle')), findsOneWidget);

    repository.deferred = Completer<SearchPageResult>();
    await tester.enterText(
      find.byKey(const ValueKey('global_search_input')),
      '慢',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.byKey(const ValueKey('search_loading')), findsOneWidget);
    repository.deferred!.complete(
      const SearchPageResult(
        records: [],
        total: 0,
        pageNum: 1,
        pageSize: 20,
        pages: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search_empty')), findsOneWidget);

    repository.error = const NetworkException('offline');
    await tester.enterText(
      find.byKey(const ValueKey('global_search_input')),
      '错',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search_error')), findsOneWidget);
    repository.error = null;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search_empty')), findsOneWidget);
  });

  testWidgets(
    'SEA-02/SEA-06 five filters reset state and detail return preserves it',
    (tester) async {
      final repository = _PageRepository();
      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),
          GoRoute(
            path: '/teams/:id',
            builder: (_, state) =>
                Scaffold(body: Text('team ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/players/:id',
            builder: (_, state) =>
                Scaffold(body: Text('player ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/matches/:id',
            builder: (_, state) =>
                Scaffold(body: Text('match ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/contents/:id',
            builder: (_, state) =>
                Scaffold(body: Text('content ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [searchRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('global_search_input')),
        '曼',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('球队 1'), findsOneWidget);
      expect(find.text('球员 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('search_filter_PLAYER')));
      await tester.pumpAndSettle();
      expect(repository.lastType, SearchEntityType.player);
      expect(find.text('球队 1'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('search_filter_MATCH')));
      await tester.pumpAndSettle();
      expect(repository.lastType, SearchEntityType.match);
      await tester.tap(find.byKey(const ValueKey('search_filter_CONTENT')));
      await tester.pumpAndSettle();
      expect(repository.lastType, SearchEntityType.content);
      await tester.tap(find.byKey(const ValueKey('search_filter_all')));
      await tester.pumpAndSettle();
      expect(repository.lastType, isNull);

      await tester.tap(find.byKey(const ValueKey('search_filter_TEAM')));
      await tester.pumpAndSettle();
      expect(repository.lastType, SearchEntityType.team);
      expect(find.text('球员 2'), findsNothing);

      await tester.tap(find.text('球队 1'));
      await tester.pumpAndSettle();
      expect(find.text('team 1'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('球队 1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '曼'), findsOneWidget);
      expect(repository.calls, 6);
    },
  );

  test('SEA-05 known types navigate and unknown or missing ids do not', () {
    expect(searchEntityLocation(_entity(SearchEntityType.team, 1)), '/teams/1');
    expect(
      searchEntityLocation(_entity(SearchEntityType.player, 2)),
      '/players/2',
    );
    expect(
      searchEntityLocation(_entity(SearchEntityType.match, 3)),
      '/matches/3',
    );
    expect(
      searchEntityLocation(_entity(SearchEntityType.content, 4)),
      '/contents/4',
    );
    expect(
      searchEntityLocation(
        const SearchEntity(
          type: SearchEntityType.unknown,
          rawType: 'COACH',
          name: '未知',
        ),
      ),
      isNull,
    );
    expect(searchEntityLocation(_entity(SearchEntityType.team, 0)), isNull);
  });
}

final class _PageRepository implements SearchRepositoryContract {
  int calls = 0;
  SearchEntityType? lastType;

  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) async {
    calls++;
    lastType = entityType;
    final all = [
      _entity(SearchEntityType.team, 1),
      _entity(SearchEntityType.player, 2),
      _entity(SearchEntityType.match, 3),
      _entity(SearchEntityType.content, 4),
    ];
    final records = entityType == null
        ? all
        : all.where((item) => item.type == entityType).toList();
    return SearchPageResult(
      records: records,
      total: records.length,
      pageNum: 1,
      pageSize: pageSize,
      pages: 1,
    );
  }
}

final class _StateRepository implements SearchRepositoryContract {
  Completer<SearchPageResult>? deferred;
  AppNetworkException? error;

  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) async {
    if (error != null) throw error!;
    if (deferred != null) return deferred!.future;
    return const SearchPageResult(
      records: [],
      total: 0,
      pageNum: 1,
      pageSize: 20,
      pages: 1,
    );
  }
}

SearchEntity _entity(SearchEntityType type, int id) => SearchEntity(
  type: type,
  rawType: type.wireValue,
  entityId: id,
  name: switch (type) {
    SearchEntityType.team => '球队 $id',
    SearchEntityType.player => '球员 $id',
    SearchEntityType.match => '比赛 $id',
    SearchEntityType.content => '内容 $id',
    SearchEntityType.unknown => '未知',
  },
);
