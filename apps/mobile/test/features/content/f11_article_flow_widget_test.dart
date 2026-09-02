import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/presentation/pages/article_editor_page.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/search/data/search_repository.dart';
import 'package:tifo/features/search/domain/search_models.dart';
import 'package:tifo/features/search/presentation/pages/global_search_page.dart';

void main() {
  testWidgets('dirty ARTICLE asks before exit and keeps editing on cancel', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(path: '/host', builder: (_, _) => const _ArticleHost()),
        GoRoute(path: '/article', builder: (_, _) => const ArticleEditorPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_UnusedContents()),
          fileUploadRepositoryProvider.overrideWithValue(_UnusedFiles()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_article')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('article_title')),
      '未完成文章',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('放弃文章草稿？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('article_title')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open_article')), findsOneWidget);
  });

  testWidgets(
    'relation picker reuses Search and only returns supported entities',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(path: '/host', builder: (_, _) => const _RelationHost()),
          GoRoute(
            path: '/relations',
            builder: (_, _) => const GlobalSearchPage(selectionMode: true),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [searchRepositoryProvider.overrideWithValue(_Search())],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open_relations')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('global_search_input')),
        '曼',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('曼城'), findsOneWidget);
      expect(find.text('曼城新闻'), findsNothing);
      await tester.tap(find.text('曼城'));
      await tester.tap(find.byKey(const ValueKey('relation_selection_done')));
      await tester.pumpAndSettle();
      expect(find.text('已选择 曼城'), findsOneWidget);
    },
  );
}

class _ArticleHost extends StatelessWidget {
  const _ArticleHost();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      key: const ValueKey('open_article'),
      onPressed: () => context.push('/article'),
      child: const Text('打开文章'),
    ),
  );
}

class _RelationHost extends StatefulWidget {
  const _RelationHost();
  @override
  State<_RelationHost> createState() => _RelationHostState();
}

class _RelationHostState extends State<_RelationHost> {
  String? selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          key: const ValueKey('open_relations'),
          onPressed: () async {
            final result = await context.push<List<SearchEntity>>('/relations');
            if (mounted && result?.isNotEmpty == true) {
              setState(() => selected = result!.first.name);
            }
          },
          child: const Text('选择关联'),
        ),
        if (selected != null) Text('已选择 $selected'),
      ],
    ),
  );
}

final class _UnusedContents implements ContentRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedFiles implements FileUploadRepositoryContract {
  @override
  Future<UploadedFile> copyRemoteImage(String url) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int id) async {}
  @override
  Future<UploadedFile> upload(String path, String name) =>
      throw UnimplementedError();
}

final class _Search implements SearchRepositoryContract {
  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) async => const SearchPageResult(
    records: [
      SearchEntity(
        type: SearchEntityType.team,
        rawType: 'TEAM',
        entityId: 1,
        name: '曼城',
      ),
      SearchEntity(
        type: SearchEntityType.content,
        rawType: 'CONTENT',
        entityId: 2,
        name: '曼城新闻',
      ),
    ],
    total: 2,
    pageNum: 1,
    pageSize: 20,
    pages: 1,
  );
}
