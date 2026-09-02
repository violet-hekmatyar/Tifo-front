import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/controllers/publish_post_controller.dart';
import 'package:tifo/features/content/presentation/pages/content_detail_page.dart';
import 'package:tifo/features/content/presentation/pages/publish_post_page.dart';
import 'package:tifo/features/feed/presentation/controllers/feed_refresh_coordinator.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';

void main() {
  testWidgets(
    'publish replacement and detail back return to the same home state once',
    (tester) async {
      final fixture = _RouteFixture();
      addTearDown(fixture.dispose);
      await fixture.pump(tester);
      await tester.tap(find.byKey(const ValueKey('set_home_state')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open_publish')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '唯一标题');
      await tester.enterText(find.byType(TextField).at(1), '真实正文');
      await tester.tap(find.text('发布').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('content_detail_back')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('content_detail_back')));
      await tester.pumpAndSettle();

      expect(fixture.location, '/app/home');
      expect(find.text('tab:news team:7'), findsOneWidget);
      expect(find.text('refresh:7'), findsOneWidget);
      expect(find.text('发布帖子'), findsNothing);
    },
  );

  testWidgets('Android back follows the same published-detail return flow', (
    tester,
  ) async {
    final fixture = _RouteFixture();
    addTearDown(fixture.dispose);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const ValueKey('open_publish')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '唯一标题');
    await tester.enterText(find.byType(TextField).at(1), '真实正文');
    await tester.tap(find.text('发布').last);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fixture.location, '/app/home');
    expect(find.text('refresh:7'), findsOneWidget);
  });

  testWidgets('detail without history falls back to the formal home route', (
    tester,
  ) async {
    final fixture = _RouteFixture(initialLocation: '/contents/99');
    addTearDown(fixture.dispose);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const ValueKey('content_detail_back')));
    await tester.pumpAndSettle();
    expect(fixture.location, '/app/home');
    expect(find.text('refresh:none'), findsOneWidget);
  });
}

final class _RouteFixture {
  _RouteFixture({String initialLocation = '/app/home'})
    : contents = _Contents(),
      router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(path: '/app/home', builder: (_, _) => const _HomeMarker()),
          GoRoute(
            path: '/publish/post',
            builder: (_, _) => const PublishPostPage(),
          ),
          GoRoute(
            path: '/contents/:id',
            builder: (_, state) => ContentDetailPage(
              contentId: int.parse(state.pathParameters['id']!),
              refreshFeedOnExit: state.extra is PublishedContentNavigation,
            ),
          ),
        ],
      );

  final _Contents contents;
  final GoRouter router;

  String get location => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(contents),
        interactionRepositoryProvider.overrideWithValue(_Interactions()),
        fileUploadRepositoryProvider.overrideWithValue(_Files()),
        publishPostControllerProvider.overrideWith(
          (_) => PublishPostController(contents, _Files(), _Gallery()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  void dispose() => router.dispose();
}

class _HomeMarker extends ConsumerStatefulWidget {
  const _HomeMarker();

  @override
  ConsumerState<_HomeMarker> createState() => _HomeMarkerState();
}

class _HomeMarkerState extends ConsumerState<_HomeMarker> {
  String tab = 'recommend';
  int? teamId;

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(feedRefreshRequestProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('tab:$tab team:${teamId ?? 'none'}'),
          Text('refresh:${request?.contentId ?? 'none'}'),
          FilledButton(
            key: const ValueKey('set_home_state'),
            onPressed: () => setState(() {
              tab = 'news';
              teamId = 7;
            }),
            child: const Text('设置首页状态'),
          ),
          FilledButton(
            key: const ValueKey('open_publish'),
            onPressed: () => context.push('/publish/post'),
            child: const Text('进入发布'),
          ),
        ],
      ),
    );
  }
}

final class _Contents implements ContentRepositoryContract {
  @override
  Future<CreatedPost> createArticle(ArticleRequest request) async =>
      CreatedPost(contentId: 8, title: request.title);

  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  }) async => CreatedPost(contentId: 7, title: title);

  @override
  Future<ContentDetail> detail(int id) =>
      throw const BusinessException('not needed', code: 40401);

  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) =>
      throw const BusinessException('not needed', code: 40401);
}

final class _Interactions implements InteractionRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
