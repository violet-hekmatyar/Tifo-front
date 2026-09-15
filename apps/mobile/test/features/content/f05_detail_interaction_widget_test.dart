import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/pages/content_detail_page.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/interaction/domain/comment.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/recommendation/presentation/recommendation_behavior_dispatcher.dart';

void main() {
  testWidgets(
    'comment create and delete refresh the detail count while keeping share usable',
    (tester) async {
      final contents = _Contents(commentCounts: [1, 2, 1]);
      final interactions = _DetailInteractions();
      final auth = AuthController(_AuthRepository());
      await auth.login(username: 'tester', password: 'password');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(contents),
            interactionRepositoryProvider.overrideWithValue(interactions),
            authControllerProvider.overrideWith((ref) => auth),
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
            ),
          ],
          child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('content_detail_comment_action')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('content_detail_share')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(
        find.byKey(const ValueKey('content_detail_comment_action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('评论 1'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '新增评论',
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(find.text('评论 2'), findsOneWidget);
      expect(find.text('评论 1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('content_detail_comment_action')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('content_detail_share')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const ValueKey('delete_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm_delete')));
      await tester.pumpAndSettle();
      expect(find.text('评论 1'), findsOneWidget);
      expect(find.text('评论 2'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('content_detail_comment_action')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('content_detail_share')),
            )
            .onPressed,
        isNotNull,
      );
      expect(contents.detailCalls, 3);
    },
  );

  testWidgets('detail actions, comment anchor, and share sheet work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final behaviors = _Behaviors();
    final dispatcher = RecommendationBehaviorDispatcher(
      behaviors,
      batchDelay: const Duration(days: 1),
    );
    addTearDown(dispatcher.dispose);
    String? clipboard;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = call.arguments['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(_Interactions()),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
          recommendationBehaviorDispatcherProvider.overrideWithValue(
            dispatcher,
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: const ContentDetailPage(
              contentId: 42,
              recommendationSource: _source,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'content_detail_comment_action',
      'content_detail_like_action',
      'content_detail_favorite_action',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('content_detail_share')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(clipboard, isNull);
    expect(find.text('复制链接'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('content_detail_share')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制链接'));
    await tester.pumpAndSettle();
    expect(clipboard, '/contents/42');
    expect(find.text('链接已复制'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('content_detail_like_action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_detail_favorite_action')),
    );
    await tester.pumpAndSettle();
    await dispatcher.flush();
    expect(
      behaviors.events.map((e) => e.behaviorType),
      containsAll([
        RecommendationBehaviorType.like,
        RecommendationBehaviorType.favorite,
      ]),
    );
    await tester.tap(
      find.byKey(const ValueKey('content_detail_comment_action')),
    );
    await tester.pumpAndSettle();
    final commentInput = tester.widget<TextField>(
      find.byKey(const ValueKey('comment_input')),
    );
    expect(commentInput.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

const _source = RecommendationSourceContext(
  targetType: RecommendationTargetType.content,
  targetId: 42,
  attribution: RecommendationAttribution(impressionId: 'i'),
);

final class _Contents implements ContentRepositoryContract {
  _Contents({this.commentCounts});

  final List<int>? commentCounts;
  int detailCalls = 0;

  @override
  Future<ContentDetail> detail(int id) async {
    final counts = commentCounts;
    final count = counts == null
        ? 1
        : counts[detailCalls < counts.length ? detailCalls : counts.length - 1];
    detailCalls++;
    return ContentDetail(
      contentId: id,
      contentType: 'POST',
      contentFormat: 'POST',
      title: '长标题' * 10,
      body: '长正文内容 ' * 200,
      author: const ContentAuthor(userId: 1, nickname: '作者'),
      media: const [],
      relations: const [],
      likeCount: 0,
      commentCount: count,
      favoriteCount: 0,
      viewCount: 1,
      liked: false,
      favorited: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final class _Interactions implements InteractionRepositoryContract {
  @override
  Future<ToggleState> toggleLike(int id) async =>
      const ToggleState(active: true);
  @override
  Future<ToggleState> toggleFavorite(int id) async =>
      const ToggleState(active: true);
  @override
  Future<CommentPage> comments(int id, CommentSort sort, int p) async =>
      const CommentPage(records: [], pageNum: 1, pages: 1, total: 0);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final class _DetailInteractions implements InteractionRepositoryContract {
  final root = const CommentItem(
    commentId: 1,
    parentId: 0,
    rootId: 1,
    author: ContentAuthor(userId: 1, nickname: '作者'),
    content: '原评论',
    likeCount: 0,
    replyCount: 0,
    liked: false,
    replies: [],
  );

  @override
  Future<ToggleState> toggleLike(int id) async =>
      const ToggleState(active: true);

  @override
  Future<ToggleState> toggleFavorite(int id) async =>
      const ToggleState(active: true);

  @override
  Future<CommentPage> comments(int id, CommentSort sort, int p) async =>
      CommentPage(records: [root], pageNum: 1, pages: 1, total: 1);

  @override
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId = 0,
    int? replyToUserId,
  }) async => 99;

  @override
  Future<void> deleteComment(int id) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final class _AuthRepository implements AuthRepositoryContract {
  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => const AuthUser(
    id: 1,
    username: 'tester',
    roleType: 'USER',
    status: 'ACTIVE',
    onboardingCompleted: true,
  );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final class _Behaviors implements RecommendationBehaviorRepositoryContract {
  final events = <RecommendationBehaviorEvent>[];
  @override
  Future<RecommendationBehaviorBatchResult> sendBatch(
    List<RecommendationBehaviorEvent> e,
  ) async {
    events.addAll(e);
    return RecommendationBehaviorBatchResult(
      received: e.length,
      saved: e.length,
      duplicated: 0,
      rejected: 0,
    );
  }
}
