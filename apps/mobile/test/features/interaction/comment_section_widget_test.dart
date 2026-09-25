import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/presentation/pages/content_detail_page.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/interaction/domain/comment.dart';
import 'package:tifo/features/interaction/presentation/controllers/comment_controller.dart';
import 'package:tifo/features/interaction/presentation/widgets/comment_section.dart';

void main() {
  testWidgets('CMT-01 content detail opens the full comments composer', (
    tester,
  ) async {
    final repo = _FakeComments()..roots = [_comment(1)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_DetailRepository()),
          interactionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ContentDetailPage(contentId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_detail_comment_action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('评论（9）'), findsOneWidget);
    final inputCapsule = find.byKey(
      const ValueKey('content_comments_input_capsule'),
    );
    final inputTap = find.descendant(
      of: inputCapsule,
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(inputTap).onTap!.call();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
    final commentInput = tester.widget<TextField>(
      find.byKey(const ValueKey('content_comment_input')),
    );
    expect(commentInput.focusNode?.hasFocus, isTrue);
  });

  testWidgets('CMT-01 bottom reply scrolls to input and requests focus', (
    tester,
  ) async {
    final repo = _FakeComments()..roots = [_comment(1)];
    final scroll = ScrollController();
    final focus = FocusNode();
    addTearDown(() {
      scroll.dispose();
      focus.dispose();
    });
    await _pumpSection(tester, repo, scroll: scroll, focus: focus);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reply_1')));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(focus.hasFocus, isTrue);
    expect(find.text('回复 @作者'), findsOneWidget);
  });

  testWidgets('CMT-02 displays the authoritative detail comment count', (
    tester,
  ) async {
    final repo = _FakeComments()..roots = [_comment(1)];
    await _pumpSection(tester, repo, commentCount: 42);
    expect(find.text('评论 42'), findsOneWidget);
    expect(find.text('评论 1'), findsNothing);
  });

  testWidgets('CMT-03 covers loading, empty, failure, retry and ready', (
    tester,
  ) async {
    final gate = Completer<CommentPage>();
    final repo = _FakeComments()..commentsBuilder = (_, _) => gate.future;
    await _pumpSection(tester, repo);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.completeError(const NetworkException('评论加载失败'));
    await tester.pump();
    await tester.pump();
    expect(find.text('评论加载失败'), findsOneWidget);
    repo.commentsBuilder = (_, _) async => _page(const []);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('还没有评论，来坐第一排吧'), findsOneWidget);

    repo.commentsBuilder = (_, _) async => _page([_comment(1)]);
    await tester.tap(find.text('最新'));
    await tester.pumpAndSettle();
    expect(find.text('评论1'), findsOneWidget);
  });

  test(
    'CMT-04 sort switch resets pages and stale requests cannot win',
    () async {
      final hot = Completer<CommentPage>();
      final latest = Completer<CommentPage>();
      final repo = _FakeComments()
        ..commentsBuilder = (sort, _) => switch (sort) {
          CommentSort.hot => hot.future,
          CommentSort.latest => latest.future,
        };
      final controller = _controller(repo);
      final oldRequest = controller.load(sort: CommentSort.hot);
      final newRequest = controller.load(sort: CommentSort.latest);
      latest.complete(_page([_comment(2)]));
      await newRequest;
      hot.complete(_page([_comment(1)]));
      await oldRequest;
      expect(controller.state.sort, CommentSort.latest);
      expect(controller.state.items.single.commentId, 2);
    },
  );

  test(
    'CMT-05 dedupes pages, prevents duplicate load and retries failure',
    () async {
      late final _FakeComments repo;
      repo = _FakeComments()
        ..commentsBuilder = (_, page) async {
          if (page == 1) return _page([_comment(1)], pages: 3);
          if (repo.moreFailures > 0) {
            repo.moreFailures--;
            throw const NetworkException('分页失败');
          }
          return _page([_comment(1), _comment(2)], pageNum: page, pages: 2);
        };
      final controller = _controller(repo);
      await controller.load();
      final first = controller.more();
      final second = controller.more();
      await Future.wait([first, second]);
      expect(repo.commentCalls.where((call) => call.page == 2), hasLength(1));
      expect(controller.state.items.map((item) => item.commentId), [1, 2]);
      expect(controller.state.hasMore, isFalse);

      final retryRepo = _FakeComments()
        ..moreFailures = 1
        ..commentsBuilder = (_, page) async => page == 1
            ? _page([_comment(1)], pages: 2)
            : _page([_comment(2)], pageNum: 2, pages: 2);
      final retryController = _controller(retryRepo);
      await retryController.load();
      await retryController.more();
      expect(retryController.state.items.single.commentId, 1);
      expect(retryController.state.moreFailure, isTrue);
      await retryController.more();
      expect(retryController.state.items.map((item) => item.commentId), [1, 2]);
    },
  );

  test(
    'CMT-06 comment likes are optimistic, busy-guarded and rollback on failure',
    () async {
      final repo = _FakeComments()..roots = [_comment(1)];
      final controller = _controller(repo);
      await controller.load();
      repo.commentLikeGate = Completer<ToggleState>();
      final first = controller.toggleLike(controller.state.items.single);
      final second = controller.toggleLike(controller.state.items.single);
      expect(controller.state.items.single.liked, isTrue);
      expect(controller.state.items.single.likeCount, 1);
      expect(repo.commentLikeCalls, 1);
      repo.commentLikeGate!.complete(const ToggleState(active: true, count: 1));
      await Future.wait([first, second]);
      expect(repo.commentLikeCalls, 1);

      repo.commentLikeError = const NetworkException('点赞失败');
      final failure = controller.toggleLike(controller.state.items.single);
      expect(controller.state.items.single.liked, isFalse);
      await failure;
      expect(controller.state.items.single.liked, isTrue);
      expect(controller.state.message, '点赞失败');
    },
  );

  testWidgets(
    'CMT-07 only own comments expose delete and cancel does not call repository',
    (tester) async {
      final repo = _FakeComments()
        ..roots = [
          _comment(1, authorId: 7),
          _comment(2, authorId: 8),
          _comment(3, authorId: 7),
        ];
      await _pumpSection(tester, repo, currentUserId: 7);
      expect(find.byKey(const ValueKey('delete_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('delete_2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('delete_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cancel_delete')));
      await tester.pump();
      expect(repo.deleteCalls, 0);
      await tester.tap(find.byKey(const ValueKey('delete_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm_delete')));
      await tester.pumpAndSettle();
      expect(repo.deleteCalls, 1);
      expect(find.byKey(const ValueKey('comment_1')), findsNothing);

      repo.deleteError = const NetworkException('删除失败');
      await tester.tap(find.byKey(const ValueKey('delete_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm_delete')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('delete_3')), findsOneWidget);
      expect(find.text('删除失败'), findsOneWidget);
    },
  );

  testWidgets('CMT-08 renders reply preview and exact view-all count', (
    tester,
  ) async {
    final root = _comment(
      1,
      replyCount: 3,
      replies: [_comment(2, parent: 1, authorId: 2)],
    );
    final repo = _FakeComments()..roots = [root];
    await _pumpSection(tester, repo);
    expect(find.text('作者2：评论2'), findsOneWidget);
    expect(find.text('查看全部 3 条回复'), findsOneWidget);
  });

  testWidgets(
    'CMT-09 reply sheet retries in place, paginates, dedupes and reaches end',
    (tester) async {
      final root = _comment(1, replyCount: 2);
      final repo = _FakeComments()
        ..roots = [root]
        ..replyFailures = 1
        ..repliesBuilder = (_, page) async => page == 1
            ? _page([_comment(2, parent: 1)], pages: 2)
            : _page(
                [_comment(2, parent: 1), _comment(3, parent: 1)],
                pageNum: 2,
                pages: 2,
              );
      await _pumpSection(tester, repo);
      await tester.tap(find.byKey(const ValueKey('view_replies_1')));
      await tester.pump();
      await tester.pump();
      expect(find.text('回复加载失败'), findsOneWidget);
      final retry = tester.widget<TextButton>(
        find.ancestor(of: find.text('重试'), matching: find.byType(TextButton)),
      );
      retry.onPressed!.call();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet_reply_2')), findsOneWidget);
      final list = find.byType(ListView).last;
      await tester.drag(list, const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet_reply_3')), findsOneWidget);
      expect(find.text('已经到底了'), findsAtLeastNWidgets(1));
      expect(repo.replyCalls.map((call) => call.page), [1, 1, 2]);
    },
  );

  testWidgets(
    'CMT-10 root and child reply targets focus and submit root parent',
    (tester) async {
      final child = _comment(2, parent: 1, authorId: 12, rootId: 1);
      final root = _comment(1, replyCount: 2, replies: [child]);
      final repo = _FakeComments()
        ..roots = [root]
        ..repliesBuilder = (_, _) async => _page([child]);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pumpSection(tester, repo, focus: focus);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '普通评论',
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(repo.created.first.parentId, 0);
      expect(repo.created.first.replyToUserId, isNull);
      await tester.tap(find.byKey(const ValueKey('reply_1')));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.text('回复 @作者'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '根回复',
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(repo.created[1].parentId, 1);
      expect(repo.created[1].replyToUserId, 1);
      await tester.tap(find.byKey(const ValueKey('view_replies_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sheet_reply_action_2')));
      await tester.pumpAndSettle();
      expect(find.text('回复 @作者12'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '子回复',
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(repo.created[2].parentId, 1);
      expect(repo.created[2].replyToUserId, 12);
    },
  );

  testWidgets(
    'CMT-11 validates, retains failures, clears success and reports COMMENT once',
    (tester) async {
      var behaviorCalls = 0;
      final repo = _FakeComments()..roots = [_comment(1)];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pumpSection(
        tester,
        repo,
        focus: focus,
        onCreated: () => behaviorCalls++,
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      expect(repo.created, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '   ',
      );
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      expect(repo.created, isEmpty);
      final validationController = _controller(repo);
      expect(await validationController.submit('x' * 1001), isFalse);
      expect(repo.created, isEmpty);
      await tester.tap(find.byKey(const ValueKey('reply_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reply_target')), findsOneWidget);
      expect(find.text('回复 @作者'), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      await tester.enterText(
        find.byKey(const ValueKey('comment_input')),
        '保留回复文本',
      );
      repo.createError = const NetworkException('发送失败');
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(find.text('保留回复文本'), findsOneWidget);
      expect(find.text('发送失败'), findsOneWidget);
      expect(find.byKey(const ValueKey('reply_target')), findsOneWidget);
      expect(find.text('回复 @作者'), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      expect(behaviorCalls, 0);
      repo.createError = null;
      await tester.tap(find.byKey(const ValueKey('comment_submit')));
      await tester.pumpAndSettle();
      expect(find.text('保留回复文本'), findsNothing);
      expect(find.byKey(const ValueKey('reply_target')), findsNothing);
      expect(behaviorCalls, 1);
      expect(repo.created, hasLength(1));
      expect(repo.created.single.parentId, 1);
      expect(repo.created.single.replyToUserId, 1);
    },
  );

  testWidgets('CMT-12 survives 412px, DPR 1 and 1.4x text without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _FakeComments()..roots = [_comment(1, replyCount: 1)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [interactionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: CommentSection(contentId: 1, currentUserId: 7),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('热门'), findsOneWidget);
    expect(find.text('最新'), findsOneWidget);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  _FakeComments repo, {
  int? commentCount,
  int? currentUserId,
  ScrollController? scroll,
  FocusNode? focus,
  VoidCallback? onCreated,
}) async {
  final section = CommentSection(
    contentId: 1,
    currentUserId: currentUserId,
    commentCount: commentCount,
    focusNode: focus,
    onCommentCreated: onCreated,
  );
  final body = scroll == null
      ? section
      : SingleChildScrollView(
          controller: scroll,
          child: Column(children: [const SizedBox(height: 800), section]),
        );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [interactionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pump();
}

CommentController _controller(_FakeComments repo) => CommentController(1, repo);

CommentPage _page(
  List<CommentItem> records, {
  int pageNum = 1,
  int pages = 1,
}) => CommentPage(
  records: records,
  pageNum: pageNum,
  pages: pages,
  total: records.length,
);

CommentItem _comment(
  int id, {
  int authorId = 1,
  int parent = 0,
  int? rootId,
  int replyCount = 0,
  List<CommentItem> replies = const [],
}) => CommentItem(
  commentId: id,
  parentId: parent,
  rootId: rootId ?? (parent == 0 ? id : 1),
  author: ContentAuthor(
    userId: authorId,
    nickname: authorId == 1 ? '作者' : '作者$authorId',
  ),
  content: '评论$id',
  likeCount: 0,
  replyCount: replyCount,
  liked: false,
  replies: replies,
  replyToUserId: parent == 0 ? null : authorId,
);

final class _Call {
  _Call({required this.sort, required this.page});
  final CommentSort sort;
  final int page;
}

final class _ReplyCall {
  _ReplyCall({required this.rootId, required this.page});
  final int rootId;
  final int page;
}

final class _CreatedCall {
  _CreatedCall({
    required this.content,
    required this.parentId,
    this.replyToUserId,
  });
  final String content;
  final int parentId;
  final int? replyToUserId;
}

final class _DetailRepository implements ContentRepositoryContract {
  @override
  Future<ContentDetail> detail(int id) async => _detailFixture;

  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
    List<ContentRelationInput> relations = const [],
  }) => throw UnimplementedError();

  @override
  Future<CreatedPost> createArticle(ArticleRequest request) =>
      throw UnimplementedError();

  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) =>
      throw UnimplementedError();
}

const _detailFixture = ContentDetail(
  contentId: 1,
  contentType: 'POST',
  contentFormat: 'POST_FORMAT',
  title: '详情标题',
  body: '正文内容',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  relations: [],
  likeCount: 0,
  commentCount: 9,
  favoriteCount: 0,
  viewCount: 1,
  liked: false,
  favorited: false,
);

final class _FakeComments implements InteractionRepositoryContract {
  List<CommentItem> roots = [_comment(1)];
  Future<CommentPage> Function(CommentSort sort, int page)? commentsBuilder;
  Future<CommentPage> Function(int rootId, int page)? repliesBuilder;
  final commentCalls = <_Call>[];
  final replyCalls = <_ReplyCall>[];
  final created = <_CreatedCall>[];
  int moreFailures = 0;
  int replyFailures = 0;
  int commentLikeCalls = 0;
  int deleteCalls = 0;
  bool likedAfterLike = false;
  AppNetworkException? error;
  AppNetworkException? commentLikeError;
  AppNetworkException? deleteError;
  AppNetworkException? createError;
  Completer<ToggleState>? commentLikeGate;

  @override
  Future<ToggleState> toggleLike(int id) async =>
      const ToggleState(active: true);

  @override
  Future<ToggleState> toggleFavorite(int id) async =>
      const ToggleState(active: true);

  @override
  Future<CommentPage> comments(int id, CommentSort sort, int page) async {
    final call = _Call(sort: sort, page: page);
    commentCalls.add(call);
    if (error case final exception?) throw exception;
    if (commentsBuilder case final builder?) {
      if (page > 1 && moreFailures > 0) {
        moreFailures--;
        throw const NetworkException('分页失败');
      }
      return builder(sort, page);
    }
    final values = [
      for (final item in roots)
        item.interactionCopy(
          liked: likedAfterLike,
          likeCount: likedAfterLike ? 1 : item.likeCount,
        ),
    ];
    return _page(values, pageNum: page, pages: 1);
  }

  @override
  Future<CommentPage> replies(int id, int page) async {
    replyCalls.add(_ReplyCall(rootId: id, page: page));
    if (replyFailures > 0) {
      replyFailures--;
      throw const NetworkException('回复加载失败');
    }
    if (repliesBuilder case final builder?) return builder(id, page);
    return _page(const []);
  }

  @override
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId = 0,
    int? replyToUserId,
  }) async {
    if (createError case final exception?) throw exception;
    created.add(
      _CreatedCall(
        content: content,
        parentId: parentId,
        replyToUserId: replyToUserId,
      ),
    );
    return 99;
  }

  @override
  Future<ToggleState> toggleCommentLike(int id) async {
    commentLikeCalls++;
    if (commentLikeError case final exception?) throw exception;
    if (commentLikeGate case final gate?) {
      return gate.future.then((result) {
        likedAfterLike = result.active;
        return result;
      });
    }
    likedAfterLike = !likedAfterLike;
    return ToggleState(active: likedAfterLike, count: likedAfterLike ? 1 : 0);
  }

  @override
  Future<void> deleteComment(int id) async {
    deleteCalls++;
    if (deleteError case final exception?) throw exception;
  }
}
