import 'dart:async';

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
import 'package:tifo/features/content/presentation/widgets/content_media_gallery.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/interaction/domain/comment.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_repository.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/recommendation/presentation/recommendation_behavior_dispatcher.dart';
import 'package:tifo/shared/design_system/app_design_tokens.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';

void main() {
  testWidgets('VR6-01 detail keeps a 3/4 media hero and input bar visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            _Contents(
              media: [
                const ContentMedia(
                  mediaId: 1,
                  mediaType: 'IMAGE',
                  mediaUrl: '/demo/p1-media/cover-stadium.png',
                ),
                const ContentMedia(
                  mediaId: 2,
                  mediaType: 'IMAGE',
                  mediaUrl: '/demo/p1-media/cover-stadium.png',
                ),
                const ContentMedia(
                  mediaId: 3,
                  mediaType: 'IMAGE',
                  mediaUrl: '/demo/p1-media/cover-stadium.png',
                ),
              ],
            ),
          ),
          interactionRepositoryProvider.overrideWithValue(_Interactions()),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
      ),
    );
    await tester.pumpAndSettle();
    final gallery = find.byType(ContentMediaGallery);
    expect(gallery, findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);
    expect(appBar.backgroundColor, AppColors.surface);
    expect(appBar.foregroundColor, AppColors.ink);
    expect(appBar.systemOverlayStyle, SystemUiOverlayStyle.dark);
    final hero = find.byKey(const ValueKey('content_media_hero'));
    final heroSize = tester.getSize(hero);
    expect(heroSize.width, greaterThan(400));
    expect(heroSize.width / heroSize.height, closeTo(3 / 4, .01));
    expect(
      find.byKey(const ValueKey('content_detail_comment_input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('content_detail_share')), findsOneWidget);
  });

  testWidgets('VR6-04 share sheet exposes only working actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(_Interactions()),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_detail_share')));
    await tester.pumpAndSettle();
    expect(find.text('分享至'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('复制标题'), findsOneWidget);
    expect(find.text('更多'), findsOneWidget);
    expect(find.byKey(const ValueKey('content_share_close')), findsOneWidget);
  });

  testWidgets('VR6-05 comments and replies preserve real hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(
            _DetailInteractions(),
          ),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_detail_comment_action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('评论（1）'), findsOneWidget);
    expect(find.text('南看台'), findsNothing);
    final commentsScaffold = find.byType(Scaffold).last;
    final commentsRect = tester.getRect(commentsScaffold);
    final logicalViewport =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(commentsRect.left, closeTo(0, 1));
    expect(commentsRect.top, lessThanOrEqualTo(1));
    expect(commentsRect.right, closeTo(logicalViewport.width, 1));
    expect(commentsRect.bottom, closeTo(logicalViewport.height, 1));
    expect(
      find.byKey(const ValueKey('content_reply_preview_1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('content_view_replies_1')));
    await tester.pumpAndSettle();
    expect(find.text('回复（3）'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('content_reply_action_2')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('content_reply_action_2')));
    await tester.pumpAndSettle();
    expect(find.text('回复 @回复者'), findsWidgets);
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
  });

  testWidgets('VR6-10 interaction layers survive 360dp and 140% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(
            _DetailInteractions(),
          ),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(1.4),
          ),
          child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_detail_share')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content_share_close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('content_share_close')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_detail_comment_input')),
    );
    await tester.pumpAndSettle();
    expect(find.text('评论（1）'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('content_comments_input_capsule')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_content_composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_view_replies_1')));
    await tester.pumpAndSettle();
    expect(find.text('回复（3）'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('content_replies_input_capsule')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('content_replies_input_capsule')),
    );
    await tester.pumpAndSettle();
    expect(find.text('回复 @作者'), findsWidgets);
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_content_composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('close_content_replies')));
    await tester.pumpAndSettle();
    expect(find.text('评论（1）'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('content_comments_back')));
    await tester.pumpAndSettle();
    expect(find.text('南看台'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR6-11 140% text opens the reply composer layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(
            _DetailInteractions(),
          ),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(420, 900),
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(1.4),
          ),
          child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_detail_share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_share_close')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_detail_comment_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('content_comments_input_capsule')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_content_composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('content_view_replies_1')));
    await tester.pumpAndSettle();
    expect(find.text('回复（3）'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('content_replies_input_capsule')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content_comment_input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content author follow uses solid and weak states', (
    tester,
  ) async {
    final repository = _FollowRepository();
    await _pumpFollowDetail(tester, repository);
    final button = find.byKey(const ValueKey('content_author_follow'));
    expect(tester.widget<FilledButton>(button), isA<FilledButton>());
    expect(
      tester.widget<FilledButton>(button).style!.backgroundColor!.resolve({}),
      AppColors.brand,
    );
    expect(find.text('关注'), findsOneWidget);

    repository.profileRelation = 'FOLLOWING';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(_Contents()),
          interactionRepositoryProvider.overrideWithValue(_Interactions()),
          userCenterRepositoryProvider.overrideWithValue(repository),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(button), isA<OutlinedButton>());
    expect(find.text('已关注'), findsOneWidget);
  });

  testWidgets('content author follow hides for the current user', (
    tester,
  ) async {
    final repository = _FollowRepository()..self = true;
    await _pumpFollowDetail(tester, repository);
    expect(find.byKey(const ValueKey('content_author_follow')), findsNothing);
  });

  testWidgets('content author follow is busy-safe and authoritative', (
    tester,
  ) async {
    final repository = _FollowRepository()..followGate = Completer<void>();
    await _pumpFollowDetail(tester, repository);
    final button = find.byKey(const ValueKey('content_author_follow'));
    await tester.tap(button);
    await tester.pump();
    expect(repository.followCalls, 1);
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    repository.followGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('已关注'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('content author follow rolls back and shows failure', (
    tester,
  ) async {
    final repository = _FollowRepository()..failFollow = true;
    await _pumpFollowDetail(tester, repository);
    await tester.tap(find.byKey(const ValueKey('content_author_follow')));
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    expect(find.text('操作失败，请稍后重试。'), findsOneWidget);
  });

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
      expect(find.text('评论（1）'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('content_comments_input_capsule')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('content_comment_input')),
        '新增评论',
      );
      await tester.tap(find.byKey(const ValueKey('content_comment_submit')));
      await tester.pumpAndSettle();
      expect(find.text('评论（2）'), findsOneWidget);
      expect(find.text('评论（1）'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('content_comment_delete_1')));
      await tester.pumpAndSettle();
      expect(find.text('评论（1）'), findsOneWidget);
      expect(find.text('评论（2）'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('content_comments_back')));
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
    expect(find.text('评论（1）'), findsOneWidget);
    expect(find.text('南看台'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

const _source = RecommendationSourceContext(
  targetType: RecommendationTargetType.content,
  targetId: 42,
  attribution: RecommendationAttribution(impressionId: 'i'),
);

final class _Contents implements ContentRepositoryContract {
  _Contents({this.commentCounts, this.media = const []});

  final List<int>? commentCounts;
  final List<ContentMedia> media;
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
      media: media,
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
    replyCount: 3,
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
  Future<CommentPage> replies(int id, int p) async => CommentPage(
    records: [
      const CommentItem(
        commentId: 2,
        parentId: 1,
        rootId: 1,
        author: ContentAuthor(userId: 2, nickname: '回复者'),
        content: '这是对根评论的真实回复',
        likeCount: 1,
        replyCount: 0,
        liked: false,
        replies: [],
      ),
      const CommentItem(
        commentId: 3,
        parentId: 1,
        rootId: 1,
        author: ContentAuthor(userId: 3, nickname: '第二位回复者'),
        content: '比赛节奏确实很快',
        likeCount: 0,
        replyCount: 0,
        liked: false,
        replies: [],
      ),
      const CommentItem(
        commentId: 4,
        parentId: 1,
        rootId: 1,
        author: ContentAuthor(userId: 4, nickname: '第三位回复者'),
        content: '期待下一场表现',
        likeCount: 0,
        replyCount: 0,
        liked: false,
        replies: [],
      ),
    ],
    pageNum: 1,
    pages: 1,
    total: 3,
  );

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

Future<void> _pumpFollowDetail(
  WidgetTester tester,
  _FollowRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(_Contents()),
        interactionRepositoryProvider.overrideWithValue(_Interactions()),
        userCenterRepositoryProvider.overrideWithValue(repository),
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(apiBaseUrl: 'http://localhost'),
        ),
      ],
      child: const MaterialApp(home: ContentDetailPage(contentId: 42)),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FollowRepository implements UserCenterRepositoryContract {
  String profileRelation = 'NONE';
  bool self = false;
  bool failFollow = false;
  Completer<void>? followGate;
  int followCalls = 0;

  UserProfile get _profile => UserProfile(
    userId: 1,
    username: 'author',
    nickname: '作者',
    followingCount: 1,
    followerCount: 3,
    contentCount: 2,
    likeReceivedCount: 5,
    relationStatus: self ? 'SELF' : profileRelation,
    currentUser: self,
  );

  @override
  Future<UserProfile> profile(int userId) async => _profile;

  @override
  Future<UserProfile> follow(int userId, bool follow) async {
    followCalls++;
    await followGate?.future;
    if (failFollow) throw StateError('follow failed');
    profileRelation = follow ? 'FOLLOWING' : 'NONE';
    return _profile;
  }

  @override
  Future<void> updateProfile({
    required String nickname,
    required String bio,
  }) async {}

  @override
  Future<void> setMainTeam(int teamId) async {}

  @override
  Future<MySummary> summary() => throw UnimplementedError();

  @override
  Future<UserStand> stand() => throw UnimplementedError();

  @override
  Future<bool> toggleEntity(String type, int id) => throw UnimplementedError();

  @override
  Future<void> removeFavorite(int contentId) async {}

  @override
  Future<void> deleteComment(int commentId) async {}

  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<UserPage<UserCommentItem>> userComments(
    int userId,
    int page,
    int size,
  ) => throw UnimplementedError();

  @override
  Future<String> bindAvatar(int fileId) => throw UnimplementedError();

  @override
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) =>
      throw UnimplementedError();

  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) =>
      throw UnimplementedError();
}
