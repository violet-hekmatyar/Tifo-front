import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/data/publish_subject_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/domain/publish_subject.dart';
import 'package:tifo/features/content/presentation/pages/publish_auxiliary_page.dart';
import 'package:tifo/features/content/presentation/pages/publish_post_page.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/content/presentation/controllers/publish_post_controller.dart';
import 'package:tifo/features/content/presentation/controllers/article_editor_controller.dart';
import 'package:tifo/features/content/presentation/pages/article_editor_page.dart';

void main() {
  testWidgets(
    'PUB-01 / PUB-02 direct publish route opens post and dirty mode switch confirms',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (context, _) => TextButton(
              key: const ValueKey('open_publish'),
              onPressed: () => context.push('/publish'),
              child: const Text('发布'),
            ),
          ),
          GoRoute(path: '/publish', builder: (_, _) => const PublishPostPage()),
          GoRoute(
            path: '/publish/article',
            builder: (_, _) => const SizedBox(key: ValueKey('article_mode')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(_Contents()),
            fileUploadRepositoryProvider.overrideWithValue(_Files()),
            publishPostControllerProvider.overrideWith(
              (_) => PublishPostController(_Contents(), _Files(), _Gallery()),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open_publish')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('publish_title')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('publish_title')), '草稿');
      await tester.tap(find.byKey(const ValueKey('publish_mode_article')));
      await tester.pumpAndSettle();
      expect(find.text('放弃未发布内容？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      expect(find.text('草稿'), findsOneWidget);
    },
  );

  testWidgets(
    'PUB-06 local topic selector filters, shows empty state and returns selection',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (context, _) => TextButton(
              key: const ValueKey('open_topic'),
              onPressed: () => context.push('/topic'),
              child: const Text('话题'),
            ),
          ),
          GoRoute(
            path: '/topic',
            builder: (_, _) =>
                const PublishAuxiliaryPage(kind: PublishAuxiliaryKind.topic),
          ),
          GoRoute(path: '/host', builder: (_, _) => const Text('host')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publishSubjectRepositoryProvider.overrideWithValue(_Subjects()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open_topic')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('publish_topic_search')),
        '不存在',
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('没有找到匹配内容'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('publish_topic_search')),
        '英超',
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('#英超焦点#'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('topic_1')));
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/host');
    },
  );

  testWidgets('PUB-06 topic search keeps search icon and green hash prefix', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publishSubjectRepositoryProvider.overrideWithValue(_Subjects()),
        ],
        child: const MaterialApp(
          home: PublishAuxiliaryPage(kind: PublishAuxiliaryKind.topic),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('publish_topic_search_icon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('publish_topic_search_hash')),
      findsOneWidget,
    );
  });

  testWidgets(
    'PUB-12 publish composer fits 412px at 1.4x text and keeps safe area',
    (tester) async {
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: ProviderScope(
            overrides: [
              contentRepositoryProvider.overrideWithValue(_Contents()),
              fileUploadRepositoryProvider.overrideWithValue(_Files()),
              publishPostControllerProvider.overrideWith(
                (_) => PublishPostController(_Contents(), _Files(), _Gallery()),
              ),
            ],
            child: const MaterialApp(home: PublishPostPage()),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PUB-13 hotspot selector renders the real event row', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publishSubjectRepositoryProvider.overrideWithValue(_Subjects()),
        ],
        child: const MaterialApp(
          home: PublishAuxiliaryPage(kind: PublishAuxiliaryKind.hotspot),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('热点事件'), findsOneWidget);
    expect(find.text('英超焦点'), findsOneWidget);
    expect(find.byKey(const ValueKey('publish_hotspot_search')), findsNothing);
  });

  testWidgets(
    'PUB-14 editor shells keep prototype spacing and image affordance',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/publish',
        routes: [
          GoRoute(path: '/publish', builder: (_, _) => const PublishPostPage()),
          GoRoute(
            path: '/publish/article',
            builder: (_, _) => const ArticleEditorPage(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(_Contents()),
            fileUploadRepositoryProvider.overrideWithValue(_Files()),
            publishPostControllerProvider.overrideWith(
              (_) => PublishPostController(_Contents(), _Files(), _Gallery()),
            ),
            articleEditorControllerProvider.overrideWith(
              (ref, contentId) => ArticleEditorController(
                contentId: contentId,
                contents: _Contents(),
                files: _Files(),
                picker: _Gallery(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      final addTile = tester.getRect(
        find.byKey(const ValueKey('publish_images')),
      );
      final body = tester.getRect(find.byKey(const ValueKey('publish_body')));
      expect(addTile.width, inInclusiveRange(76, 84));
      expect(addTile.height, inInclusiveRange(76, 84));
      expect(addTile.top - body.bottom, lessThanOrEqualTo(32));
      expect(
        find.byKey(const ValueKey('publish_add_image_tool')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('publish_topic')), findsNothing);
      expect(find.byKey(const ValueKey('publish_hotspot')), findsNothing);
      expect(
        find.byKey(const ValueKey('publish_mode_switcher')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('publish_mode_article')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('article_title')), findsOneWidget);
      expect(find.byKey(const ValueKey('article_text_1')), findsOneWidget);
    },
  );
}

final class _Contents implements ContentRepositoryContract {
  @override
  Future<ContentDetail> detail(int id) => throw UnimplementedError();
  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
    List<ContentRelationInput> relations = const [],
  }) async => const CreatedPost(contentId: 1, title: '');
  @override
  Future<CreatedPost> createArticle(ArticleRequest request) =>
      throw UnimplementedError();
  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) =>
      throw UnimplementedError();
}

final class _Files implements FileUploadRepositoryContract {
  @override
  Future<UploadedFile> copyRemoteImage(String url) =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
  @override
  Future<UploadedFile> upload(String path, String name) =>
      throw UnimplementedError();
}

final class _Gallery implements GalleryPicker {
  @override
  Future<List<XFile>> pickImages() async => const [];
}

final class _Subjects implements PublishSubjectRepositoryContract {
  @override
  Future<PublishSubjectPage> list({
    required PublishAuxiliaryKind kind,
    required String keyword,
    required int pageNum,
    required int pageSize,
  }) async {
    if (keyword == '不存在') {
      return PublishSubjectPage(
        records: const [],
        total: 0,
        pageNum: 1,
        pageSize: pageSize,
        pages: 0,
      );
    }
    return PublishSubjectPage(
      records: [
        PublishAuxiliaryItem(id: 1, name: '英超焦点', count: 12800, kind: kind),
      ],
      total: 1,
      pageNum: 1,
      pageSize: pageSize,
      pages: 1,
    );
  }
}
