import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/search/data/search_repository.dart';
import 'package:tifo/features/search/domain/search_models.dart';
import 'package:tifo/features/search/presentation/pages/global_search_page.dart';

void main() {
  testWidgets(
    'searches, filters, navigates and preserves loaded state after return',
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
      expect(repository.calls, 2);
    },
  );

  test('all known entity types map to existing detail routes', () {
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
