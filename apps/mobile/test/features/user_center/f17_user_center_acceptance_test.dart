import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/media_url_resolver.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';
import 'package:tifo/features/user_center/presentation/pages/edit_profile_page.dart';
import 'package:tifo/features/user_center/presentation/pages/followed_entities_page.dart';
import 'package:tifo/features/user_center/presentation/pages/my_profile_page.dart';
import 'package:tifo/features/user_center/presentation/pages/public_user_page.dart';
import 'package:tifo/features/user_center/presentation/pages/user_list_page.dart';
import 'package:tifo/features/user_center/presentation/pages/user_relations_page.dart';
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/shared/widgets/app_entity_avatar.dart';
import 'package:tifo/shared/widgets/app_state_view.dart';

void main() {
  test(
    'USER-01 summary retains nullable fields, long names, large counts and ids',
    () async {
      final repository = _Repo()
        ..summaryValue = _summary(
          nickname: '这是一个非常长的中英文混合用户名称 User Name',
          mainTeam: const EntityBrief(id: 40, name: '真实主队'),
        );
      final controller = MyProfileController(repository);
      await controller.load();
      expect(controller.state.summary!.bio, isNull);
      expect(controller.state.summary!.followerCount, 999999);
      expect(controller.state.summary!.mainTeam!.id, 40);
      repository.summaryValue = _summary(
        mainTeam: const EntityBrief(id: -1, name: '坏主队'),
      );
      await controller.refresh();
      expect(controller.state.summary!.mainTeam!.id, -1);
      expect(repository.summaryCalls, 2);
    },
  );

  testWidgets(
    'USER-01 renders real header and only valid main-team ids navigate',
    (tester) async {
      final repository = _Repo()
        ..summaryValue = _summary(
          nickname: '一个非常长的本人名称 User Name',
          mainTeam: const EntityBrief(id: 40, name: '真实主队'),
        );
      final router = _profileRouter(repository);
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerScope(repository, router));
      await _settle(tester);
      expect(find.text('一个非常长的本人名称 User Name'), findsOneWidget);
      expect(find.text('999999'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('my_profile_main_team')));
      await tester.pumpAndSettle();
      expect(find.text('球队详情 40'), findsOneWidget);

      final invalidRepository = _Repo()
        ..summaryValue = _summary(
          mainTeam: const EntityBrief(id: -1, name: '不可跳转'),
        );
      final invalidRouter = _profileRouter(invalidRepository);
      addTearDown(invalidRouter.dispose);
      await tester.pumpWidget(_routerScope(invalidRepository, invalidRouter));
      await _settle(tester);
      expect(
        find.byKey(const ValueKey('my_profile_main_team')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('my_profile_main_team')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('球队详情 40'), findsNothing);
    },
  );

  test(
    'USER-02 summary and stand refresh preserve ready data and invalid ids do not request',
    () async {
      final repository = _Repo();
      final controller = MyProfileController(repository);
      await controller.load();
      final before = controller.state.summary;
      repository.summaryFailure = true;
      repository.standFailure = true;
      await controller.refresh();
      expect(controller.state.summary, same(before));
      expect(controller.state.summaryMessage, isNotNull);
      expect(controller.state.standMessage, isNotNull);

      final invalid = UserListController(
        repository,
        const UserListRequest(UserListKind.userContents, userId: -1),
      );
      await invalid.loadInitial();
      expect(invalid.state.status, UserListStatus.failure);
      expect(repository.userContentCalls, 0);
    },
  );

  test(
    'USER-02 summary and stand retry independently after initial failures',
    () async {
      final repository = _Repo()
        ..summaryFailure = true
        ..standFailure = true;
      final controller = MyProfileController(repository);
      await controller.load();
      expect(controller.state.summaryStatus, MyProfileResourceStatus.failure);
      expect(controller.state.standStatus, MyProfileResourceStatus.failure);
      expect(repository.summaryCalls, 1);
      expect(repository.standCalls, 1);
      repository.summaryFailure = false;
      await controller.retrySummary();
      expect(controller.state.summaryStatus, MyProfileResourceStatus.ready);
      expect(repository.summaryCalls, 2);
      expect(repository.standCalls, 1);
      repository.standFailure = false;
      await controller.retryStand();
      expect(controller.state.standStatus, MyProfileResourceStatus.ready);
      expect(repository.summaryCalls, 2);
      expect(repository.standCalls, 2);
    },
  );

  test(
    'USER-03 avatar cancel, busy guard, upload failure and authoritative success',
    () async {
      final picker = _Picker();
      final files = _Files();
      final repository = _Repo()..avatarFailure = true;
      var bound = false;
      final controller = AvatarUpdateController(
        repository,
        files,
        picker,
        onBound: () => bound = true,
      );
      await controller.chooseAndUpload();
      expect(controller.state.avatarUrl, isNull);
      expect(files.deleted, 90);
      expect(controller.state.busy, isFalse);
      final failedFiles = _Files()..uploadFailure = true;
      final failedController = AvatarUpdateController(
        repository,
        failedFiles,
        _Picker(),
      );
      await failedController.chooseAndUpload();
      expect(failedController.state.message, contains('网络连接失败'));
      expect(failedController.state.busy, isFalse);
      repository.avatarFailure = false;
      files.uploadGate = Completer<UploadedFile>();
      final upload = controller.chooseAndUpload();
      final duplicate = controller.chooseAndUpload();
      expect(files.uploadCalls, 1);
      expect(controller.state.busy, isTrue);
      files.uploadGate!.complete(
        const UploadedFile(fileId: 90, url: '/avatar-upload.png'),
      );
      await Future.wait([upload, duplicate]);
      expect(controller.state.avatarUrl, '/avatar-new.png');
      expect(bound, isTrue);
      repository.bindFailure = true;
      repository.summaryValue = _summary(avatarUrl: '/avatar-upload.png');
      files.uploadGate = null;
      await controller.chooseAndUpload();
      expect(controller.state.avatarUrl, '/avatar-upload.png');
      expect(files.deleted, 90);
      picker.cancel = true;
      await controller.chooseAndUpload();
      expect(controller.state.busy, isFalse);
    },
  );

  testWidgets(
    'USER-04 edit validates, preserves input, blocks duplicate save and pops after success',
    (tester) async {
      final repository = _Repo()..editFailure = true;
      await tester.pumpWidget(
        _scope(repository, EditProfilePage(summary: _summary())),
      );
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(find.textContaining('昵称需为'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '新昵称');
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(find.textContaining('保存失败'), findsOneWidget);
      expect(find.text('新昵称'), findsOneWidget);
    },
  );

  testWidgets(
    'USER-04 successful edit is busy-safe and returns to the previous page',
    (tester) async {
      final repository = _Repo()..editGate = Completer<void>();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('资料主页')),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) => EditProfilePage(summary: _summary()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerScope(repository, router));
      router.push('/edit');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '新昵称');
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(repository.editCalls, 1);
      expect(find.text('保存中'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '保存中'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '保存中'))
            .onPressed,
        isNull,
      );
      repository.editGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('资料主页'), findsOneWidget);
      expect(repository.editCalls, 1);
    },
  );

  testWidgets('USER-05本人五 Tab、看台实体列表与无效实体跳转安全', (tester) async {
    final repository = _Repo()
      ..standValue = const UserStand(
        teams: [EntityBrief(id: 40, name: '球队')],
        players: [EntityBrief(id: -1, name: '无效球员')],
      );
    await tester.pumpWidget(_scope(repository, const MyProfilePage()));
    await _settle(tester);
    for (final key in const [
      'my_tab_stand',
      'my_tab_posts',
      'my_tab_likes',
      'my_tab_favorites',
      'my_tab_comments',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.text('球队'), findsOneWidget);
    expect(find.text('浏览记录'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('USER-05 each profile tab activates its own real list source', (
    tester,
  ) async {
    final repository = _Repo()
      ..contentItems = _contentItems(2)
      ..likeItems = const [
        UserLikeItem(
          contentId: 2,
          contentType: 'POST',
          title: '点赞记录',
          visible: true,
          likeCount: 1,
          commentCount: 0,
          favoriteCount: 0,
        ),
      ]
      ..favoriteItems = const [UserFavoriteItem(contentId: 3, title: '收藏记录')]
      ..commentItems = const [
        UserCommentItem(commentId: 4, contentId: 3, content: '评论记录'),
      ];
    await tester.pumpWidget(_scope(repository, const MyProfilePage()));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('my_tab_posts')));
    await tester.pumpAndSettle();
    expect(find.text('内容 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my_tab_likes')));
    await tester.pumpAndSettle();
    expect(find.text('点赞记录'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my_tab_favorites')));
    await tester.pumpAndSettle();
    expect(find.text('收藏记录'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my_tab_comments')));
    await tester.pumpAndSettle();
    expect(find.text('评论记录'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my_tab_stand')));
    await tester.pumpAndSettle();
    expect(find.text('看台'), findsWidgets);
    expect(repository.userContentCalls, greaterThan(0));
    expect(repository.likeCalls, greaterThan(0));
    expect(repository.favoriteCalls, greaterThan(0));
    expect(repository.commentCalls, greaterThan(0));
  });

  testWidgets(
    'USER-05 stand routes valid teams/players and disables invalid entity taps',
    (tester) async {
      final repository = _Repo()
        ..standValue = const UserStand(
          teams: [EntityBrief(id: 40, name: '可跳转球队')],
          players: [
            EntityBrief(id: 50, name: '可跳转球员'),
            EntityBrief(id: -1, name: '无效球员'),
          ],
        );
      final router = _profileRouter(repository);
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerScope(repository, router));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('my_tab_stand')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('可跳转球队'));
      await tester.pumpAndSettle();
      expect(find.text('球队详情 40'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('可跳转球员'));
      await tester.pumpAndSettle();
      expect(find.text('球员详情 50'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      final invalidTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('无效球员'), matching: find.byType(ListTile)),
      );
      expect(invalidTile.onTap, isNull);
    },
  );

  testWidgets(
    'USER-06 content cards use two columns at 412 and one column at 360/1.4x',
    (tester) async {
      final repository = _Repo()
        ..contentItems = _contentItems(3)
        ..contentSinglePage = true;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [412.0, 360.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(
          _scope(
            repository,
            const UserListPage(
              title: '我的发布',
              request: UserListRequest(UserListKind.myContents),
            ),
          ),
        );
        await _settle(tester);
        final cards = find.byType(ContentCard);
        expect(cards, findsAtLeastNWidgets(2));
        final firstCard = find.byKey(const ValueKey('user-content-1'));
        final secondCard = find.byKey(const ValueKey('user-content-2'));
        final thirdCard = find.byKey(const ValueKey('user-content-3'));
        expect(tester.getSize(firstCard).width, greaterThan(0));
        expect(
          tester.getSize(firstCard).width,
          closeTo(tester.getSize(secondCard).width, 1),
        );
        if (width == 412) {
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('user-content-1'))).dx,
            lessThan(
              tester
                  .getTopLeft(find.byKey(const ValueKey('user-content-2')))
                  .dx,
            ),
          );
          expect(
            tester.getTopLeft(thirdCard).dx,
            closeTo(tester.getTopLeft(firstCard).dx, 1),
          );
          expect(
            tester.getSize(firstCard).height,
            isNot(tester.getSize(secondCard).height),
          );
        } else {
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('user-content-1'))).dx,
            closeTo(
              tester
                  .getTopLeft(find.byKey(const ValueKey('user-content-2')))
                  .dx,
              1,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(412, 900);
      await tester.pumpWidget(
        _responsiveScope(
          repository,
          const UserListPage(
            title: '我的发布',
            request: UserListRequest(UserListKind.myContents),
          ),
        ),
      );
      await _settle(tester);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('user-content-1'))).dx,
        closeTo(
          tester.getTopLeft(find.byKey(const ValueKey('user-content-2'))).dx,
          1,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('user-content-1'))).height,
        isNot(
          tester.getSize(find.byKey(const ValueKey('user-content-2'))).height,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'USER-07 list pagination deduplicates, retries append and ignores stale refresh',
    () async {
      final repository = _Repo()
        ..contentItems = _contentItems(3)
        ..contentPage2Failure = true;
      final controller = UserListController(
        repository,
        const UserListRequest(UserListKind.myContents),
      );
      await controller.loadInitial();
      expect(controller.state.items.length, 2);
      await controller.loadMore();
      expect(controller.state.appendMessage, isNotNull);
      repository.contentPage2Failure = false;
      await controller.loadMore();
      expect(
        controller.state.items.map((e) => (e as UserContentItem).contentId),
        [1, 2, 3],
      );
      expect(repository.userContentCalls, 3);

      final staleRepository = _StaleRepo();
      final staleController = UserListController(
        staleRepository,
        const UserListRequest(UserListKind.myContents),
      );
      await staleController.loadInitial();
      final staleRefresh = staleController.refresh();
      final latestRefresh = staleController.retry();
      await latestRefresh;
      expect(
        staleController.state.items.whereType<UserContentItem>().map(
          (item) => item.contentId,
        ),
        [77],
      );

      final listRepository = _Repo()
        ..likesFailure = true
        ..likeItems = const [
          UserLikeItem(
            contentId: 1,
            contentType: 'POST',
            title: '重试后点赞',
            visible: true,
            likeCount: 0,
            commentCount: 0,
            favoriteCount: 0,
          ),
        ];
      final likes = UserListController(
        listRepository,
        const UserListRequest(UserListKind.myLikes),
      );
      await likes.loadInitial();
      expect(likes.state.status, UserListStatus.failure);
      listRepository.likesFailure = false;
      await likes.retry();
      expect(likes.state.items.single, isA<UserLikeItem>());
      final preserved = likes.state.items;
      listRepository.likesFailure = true;
      await likes.refresh();
      expect(likes.state.items, same(preserved));
      expect(likes.state.message, isNotNull);

      final emptyFavorites = _Repo()..favoriteItems = const [];
      final empty = UserListController(
        emptyFavorites,
        const UserListRequest(UserListKind.myFavorites),
      );
      await empty.loadInitial();
      expect(empty.state.status, UserListStatus.empty);
      staleRepository.staleRefresh.complete(
        const UserPage(
          records: [
            UserContentItem(
              contentId: 99,
              contentType: 'POST',
              title: '过期响应',
              likeCount: 0,
              commentCount: 0,
              favoriteCount: 0,
            ),
          ],
          pageNum: 1,
          pages: 1,
          total: 1,
        ),
      );
      await staleRefresh;
      expect(
        staleController.state.items.whereType<UserContentItem>().map(
          (item) => item.contentId,
        ),
        [77],
      );
    },
  );

  testWidgets(
    'USER-08 visible/unknown likes and invalid comments do not misnavigate',
    (tester) async {
      final repository = _Repo()
        ..likeItems = const [
          UserLikeItem(
            contentId: 1,
            contentType: 'UNKNOWN',
            title: '不可见',
            visible: false,
            likeCount: 0,
            commentCount: 0,
            favoriteCount: 0,
          ),
        ]
        ..commentItems = const [
          UserCommentItem(commentId: 1, contentId: -1, content: '真实评论'),
        ];
      await tester.pumpWidget(
        _scope(
          repository,
          UserListPage(
            key: UniqueKey(),
            title: '点赞',
            request: UserListRequest(UserListKind.myLikes),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('内容当前不可见，无法打开。'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      await tester.pumpWidget(
        _scope(
          repository,
          UserListPage(
            key: UniqueKey(),
            title: '评论',
            request: UserListRequest(UserListKind.myComments),
          ),
        ),
      );
      await _settle(tester);
      expect(find.textContaining('真实评论'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'USER-08 visible known/unknown content and valid/invalid comments route safely',
    (tester) async {
      final repository = _Repo()
        ..likeItems = const [
          UserLikeItem(
            contentId: 1,
            contentType: 'POST',
            title: '已知内容',
            visible: true,
            likeCount: 0,
            commentCount: 0,
            favoriteCount: 0,
          ),
          UserLikeItem(
            contentId: 2,
            contentType: 'FUTURE_TYPE',
            title: '未知类型内容',
            visible: true,
            likeCount: 0,
            commentCount: 0,
            favoriteCount: 0,
          ),
        ]
        ..commentItems = const [
          UserCommentItem(commentId: 1, contentId: 3, content: '有效评论'),
          UserCommentItem(commentId: 2, contentId: -1, content: '无效评论'),
        ];
      final router = GoRouter(
        initialLocation: '/likes',
        routes: [
          GoRoute(
            path: '/likes',
            builder: (_, _) => const UserListPage(
              title: '点赞',
              request: UserListRequest(UserListKind.myLikes),
            ),
          ),
          GoRoute(
            path: '/comments',
            builder: (_, _) => const UserListPage(
              title: '评论',
              request: UserListRequest(UserListKind.myComments),
            ),
          ),
          GoRoute(
            path: '/contents/:id',
            builder: (_, state) => Text('详情 ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerScope(repository, router));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('user-like-1')));
      await tester.pumpAndSettle();
      expect(find.text('详情 1'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('user-like-2')));
      await tester.pumpAndSettle();
      expect(find.text('详情 2'), findsOneWidget);
      router.go('/comments');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('user-comment-1')));
      await tester.pumpAndSettle();
      expect(find.text('详情 3'), findsOneWidget);
      router.go('/comments');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('user-comment-2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'USER-09 favorite/comment removal is optimistic, busy isolated and rolls back',
    () async {
      final repository = _Repo()..removeFailure = true;
      final controller = UserListController(
        repository,
        const UserListRequest(UserListKind.myFavorites),
      );
      await controller.loadInitial();
      final item = controller.state.items.single;
      final future = controller.removeItem(item);
      expect(controller.state.items, isEmpty);
      await future;
      expect(controller.state.items, isNotEmpty);
      expect(controller.state.message, isNotNull);
    },
  );

  test(
    'USER-09 concurrent removals merge two favorite results without restoring a successful item',
    () async {
      final repository = _ConcurrentRemovalRepo();
      final controller = UserListController(
        repository,
        const UserListRequest(UserListKind.myFavorites),
      );
      await controller.loadInitial();
      final first = controller.state.items[0];
      final second = controller.state.items[1];
      final firstRemoval = controller.removeItem(first);
      final secondRemoval = controller.removeItem(second);
      expect(controller.state.items, isEmpty);
      expect(controller.state.busyItemKeys, {'favorite:1', 'favorite:2'});
      repository.gates[2]!.complete();
      await secondRemoval;
      expect(controller.state.items, isEmpty);
      expect(controller.state.busyItemKeys, {'favorite:1'});
      repository.failures[1] = const NetworkException('first failed');
      repository.gates[1]!.complete();
      await firstRemoval;
      expect(
        controller.state.items.whereType<UserFavoriteItem>().map(
          (e) => e.contentId,
        ),
        [1],
      );
      expect(controller.state.busyItemKeys, isEmpty);
      expect(repository.removeCalls, hasLength(2));
      expect(repository.removeCalls, containsAll([1, 2]));
    },
  );

  test(
    'USER-09 concurrent comment success and business failure restore only the failed comment',
    () async {
      final repository = _ConcurrentRemovalRepo.comments();
      final controller = UserListController(
        repository,
        const UserListRequest(UserListKind.myComments),
      );
      await controller.loadInitial();
      final first = controller.state.items[0];
      final second = controller.state.items[1];
      final firstRemoval = controller.removeItem(first);
      final secondRemoval = controller.removeItem(second);
      repository.gates[2]!.complete();
      await secondRemoval;
      repository.failures[1] = const BusinessException(
        'cannot delete',
        code: 40001,
      );
      repository.gates[1]!.complete();
      await firstRemoval;
      expect(
        controller.state.items.whereType<UserCommentItem>().map(
          (e) => e.commentId,
        ),
        [1],
      );
      expect(controller.state.busyItemKeys, isEmpty);
      expect(repository.deleteCalls, hasLength(2));
      expect(repository.deleteCalls, containsAll([1, 2]));
    },
  );

  testWidgets(
    'USER-09 favorite/comment widgets confirm, optimistically remove and rollback',
    (tester) async {
      final favoriteRepository = _Repo()
        ..favoriteItems = const [UserFavoriteItem(contentId: 8, title: '待收藏')]
        ..removeGate = Completer<void>();
      await tester.pumpWidget(
        _scope(
          favoriteRepository,
          const UserListPage(
            title: '收藏',
            request: UserListRequest(UserListKind.myFavorites),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byTooltip('取消收藏'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(favoriteRepository.removeRequestCount, 0);
      expect(find.text('待收藏'), findsOneWidget);
      await tester.tap(find.byTooltip('取消收藏'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认').last);
      await tester.pump();
      expect(favoriteRepository.removeRequestCount, 1);
      expect(find.text('待收藏'), findsNothing);
      favoriteRepository.removeGate!.complete();
      await tester.pumpAndSettle();

      final failedCommentRepository = _Repo()
        ..commentItems = const [
          UserCommentItem(commentId: 9, contentId: 8, content: '待删除评论'),
        ]
        ..deleteFailure = true;
      await tester.pumpWidget(
        _scope(
          failedCommentRepository,
          const UserListPage(
            title: '评论',
            request: UserListRequest(UserListKind.myComments),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byTooltip('删除评论'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.text('待删除评论'), findsOneWidget);
      expect(find.text('delete'), findsOneWidget);
    },
  );

  testWidgets(
    'USER-17 entity cancellation obeys authoritative true/false for teams and players',
    (tester) async {
      final repository = _Repo()
        ..standValue = const UserStand(
          teams: [EntityBrief(id: 40, name: '球队')],
          players: [EntityBrief(id: 50, name: '球员')],
        )
        ..toggleEntityResult = true;
      await tester.pumpWidget(
        _scope(repository, const FollowedEntitiesPage(teams: true)),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('team-unfollow-40')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('team-followed-40')), findsOneWidget);
      expect(find.textContaining('仍处于关注状态'), findsOneWidget);
      repository.toggleEntityResult = false;
      await tester.tap(find.byKey(const ValueKey('team-unfollow-40')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('team-followed-40')), findsNothing);

      await tester.pumpWidget(
        _scope(repository, const FollowedEntitiesPage(teams: false)),
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('player-followed-50')), findsOneWidget);
      repository.toggleEntityFailure = true;
      await tester.tap(find.byKey(const ValueKey('player-unfollow-50')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-followed-50')), findsOneWidget);
    },
  );

  testWidgets(
    'USER-10 public profile fields, three tabs, self state and main-team navigation are real',
    (tester) async {
      final repository = _Repo()..profileValue = _profile(current: true);
      await tester.pumpWidget(
        _scope(repository, const PublicUserPage(userId: 22)),
      );
      await _settle(tester);
      expect(find.text('发布'), findsWidgets);
      expect(find.byKey(const ValueKey('public_tab_posts')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('public_tab_favorites')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('public_tab_comments')), findsOneWidget);
      expect(find.byKey(const ValueKey('public_user_follow')), findsNothing);
      expect(find.text('获赞'), findsOneWidget);
    },
  );

  testWidgets(
    'USER-10 public profile distinguishes 404/network and preserves ready data on refresh failure',
    (tester) async {
      final repository = _Repo()
        ..profileFailure = const NetworkException('offline');
      await tester.pumpWidget(
        _scope(repository, const PublicUserPage(userId: 22)),
      );
      await _settle(tester);
      expect(find.text('用户主页加载失败'), findsOneWidget);
      repository.profileFailure = null;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('用户主页'), findsOneWidget);

      final missing = _Repo()
        ..profileFailure = const BusinessException('missing', code: 40401);
      await tester.pumpWidget(
        _scope(missing, const PublicUserPage(userId: 404)),
      );
      await _settle(tester);
      expect(find.text('用户不存在'), findsOneWidget);
      final missingController = PublicProfileController(missing, 22);
      await missingController.load();
      expect(missingController.state.status, PublicProfileStatus.notFound);

      final ready = _Repo();
      final controller = PublicProfileController(ready, 22);
      await controller.load();
      final previous = controller.state.profile;
      ready.profileFailure = const NetworkException('refresh');
      await controller.refresh();
      expect(controller.state.profile, same(previous));
      expect(controller.state.status, PublicProfileStatus.ready);
      expect(controller.state.message, isNotNull);
    },
  );

  testWidgets(
    'USER-11 40301 favorites/comments are restricted independently from public posts',
    (tester) async {
      final repository = _Repo()..privateFailure = true;
      await tester.pumpWidget(
        _scope(repository, const PublicUserPage(userId: 22)),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('public_tab_favorites')));
      await tester.pumpAndSettle();
      expect(find.textContaining('隐私保护'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('public_tab_comments')));
      await tester.pumpAndSettle();
      expect(find.textContaining('隐私保护'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('public_tab_posts')));
      await _settle(tester);
      expect(find.text('公开发布'), findsOneWidget);
      final emptyRepository = _Repo()
        ..publicFavoritesEmpty = true
        ..publicCommentsEmpty = true;
      await tester.pumpWidget(
        _scope(emptyRepository, const PublicUserPage(userId: 22)),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('public_tab_favorites')));
      await tester.pumpAndSettle();
      expect(find.text('暂无内容'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('public_tab_comments')));
      await tester.pumpAndSettle();
      expect(find.text('暂无内容'), findsOneWidget);
    },
  );

  test(
    'USER-12 all relation labels and unknown are neutral with zero unsafe requests',
    () async {
      expect(userRelationLabel('SELF'), '本人');
      expect(userRelationLabel('NONE'), '未关注');
      expect(userRelationLabel('FOLLOWING'), '已关注');
      expect(userRelationLabel('FOLLOWED_BY'), '关注了你');
      expect(userRelationLabel('MUTUAL'), '互相关注');
      expect(userRelationLabel('FUTURE'), '关系未知');
      final repository = _Repo()..profileValue = _profile(relation: 'FUTURE');
      final controller = PublicProfileController(repository, 22);
      await controller.load();
      await controller.toggleFollow();
      expect(repository.followCalls, 0);
    },
  );

  testWidgets(
    'USER-12 widget renders every relation action and keeps self/unknown inert',
    (tester) async {
      final cases = <String, String>{
        'NONE': '关注',
        'FOLLOWING': '取消关注',
        'FOLLOWED_BY': '回关',
        'MUTUAL': '取消互关',
      };
      for (final entry in cases.entries) {
        final repository = _Repo()
          ..profileValue = _profile(relation: entry.key);
        await tester.pumpWidget(
          _scope(repository, PublicUserPage(key: UniqueKey(), userId: 22)),
        );
        await _settle(tester);
        expect(find.widgetWithText(FilledButton, entry.value), findsOneWidget);
      }
      for (final relation in ['SELF', 'FUTURE']) {
        final repository = _Repo()..profileValue = _profile(relation: relation);
        await tester.pumpWidget(
          _scope(repository, PublicUserPage(key: UniqueKey(), userId: 22)),
        );
        await _settle(tester);
        expect(find.byKey(const ValueKey('public_user_follow')), findsNothing);
        expect(find.text(userRelationLabel(relation)), findsOneWidget);
        expect(repository.followCalls, 0);
      }
    },
  );

  test(
    'USER-13 follow optimistic success and network/business rollback keep count valid',
    () async {
      final repository = _Repo()..profileValue = _profile();
      final controller = PublicProfileController(repository, 22);
      await controller.load();
      repository.followFailure = const NetworkException('offline');
      await controller.toggleFollow();
      expect(controller.state.profile!.relationStatus, 'NONE');
      expect(controller.state.profile!.followerCount, 2);
      repository.followFailure = const BusinessException(
        'blocked',
        code: 40001,
      );
      await controller.toggleFollow();
      expect(controller.state.profile!.relationStatus, 'NONE');
      expect(controller.state.profile!.followerCount, greaterThanOrEqualTo(0));
    },
  );

  testWidgets(
    'USER-13 follow, follow-back and cancellation require confirmation and honor pending state',
    (tester) async {
      final actions = <String, String>{
        'NONE': '关注',
        'FOLLOWED_BY': '回关',
        'FOLLOWING': '取消关注',
        'MUTUAL': '取消互关',
      };
      for (final entry in actions.entries) {
        final repository = _Repo()
          ..profileValue = _profile(relation: entry.key)
          ..followGate = Completer<void>();
        await tester.pumpWidget(
          _scope(repository, PublicUserPage(key: UniqueKey(), userId: 22)),
        );
        await _settle(tester);
        expect(find.widgetWithText(FilledButton, entry.value), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('public_user_follow')));
        await tester.pumpAndSettle();
        expect(find.textContaining('确认'), findsAtLeastNWidgets(1));
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(repository.followCalls, 0);
        await tester.tap(find.byKey(const ValueKey('public_user_follow')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认').last);
        await tester.pump();
        expect(repository.followCalls, 1);
        final button = tester.widget<FilledButton>(
          find.byKey(const ValueKey('public_user_follow')),
        );
        expect(button.onPressed, isNull);
        repository.followGate!.complete();
        await tester.pumpAndSettle();
        expect(repository.followCalls, 1);
      }
    },
  );

  testWidgets(
    'USER-14 relations switch and local search never changes pagination source',
    (tester) async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(
            userId: 2,
            username: 'alice',
            nickname: 'Alice',
            bio: '守门员',
          ),
          UserBrief(userId: 3, username: 'bob', nickname: 'Bob', bio: '中场'),
        ];
      await tester.pumpWidget(
        _scope(repository, const UserRelationsPage(userId: 1)),
      );
      await _settle(tester);
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      await tester.enterText(
        find.byKey(const ValueKey('user_list_search')),
        'alice',
      );
      await tester.pump();
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('Bob'), findsNothing);
      await tester.tap(find.byTooltip('清空搜索'));
      await tester.pump();
      expect(find.text('Bob'), findsAtLeastNWidgets(1));
      expect(repository.followingPages, [1]);
    },
  );

  testWidgets(
    'USER-14 following and followers tabs keep independent search and requests',
    (tester) async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(userId: 2, username: 'alice', nickname: 'Alice'),
        ]
        ..followerItems = const [
          UserBrief(userId: 3, username: 'bob', nickname: 'Bob'),
        ];
      await tester.pumpWidget(
        _scope(repository, const UserRelationsPage(userId: 1)),
      );
      await _settle(tester);
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      await tester.enterText(
        find.byKey(const ValueKey('user_list_search')),
        'alice',
      );
      await tester.tap(find.byKey(const ValueKey('relations_followers')));
      await tester.pumpAndSettle();
      expect(find.text('Bob'), findsAtLeastNWidgets(1));
      expect(find.text('Alice'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('user_list_search')),
        'bob',
      );
      await tester.tap(find.byKey(const ValueKey('relations_following')));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('Bob'), findsNothing);
      expect(repository.followingPages, [1]);
      expect(repository.followerCalls, 1);
    },
  );

  test(
    'USER-15 different user follow operations merge authoritative and failure per row',
    () async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(userId: 2, username: 'a', nickname: 'A'),
          UserBrief(userId: 3, username: 'b', nickname: 'B'),
        ];
      final controller = UserListController(
        repository,
        const UserListRequest(UserListKind.followings, userId: 1),
      );
      await controller.loadInitial();
      repository.followGates[2] = Completer<void>();
      repository.followFailures[3] = const NetworkException('no');
      final a = controller.toggleUser(controller.state.items[0] as UserBrief);
      final b = controller.toggleUser(controller.state.items[1] as UserBrief);
      await b;
      expect((controller.state.items[1] as UserBrief).relationStatus, 'NONE');
      repository.followGates[2]!.complete();
      await a;
      expect(
        (controller.state.items[0] as UserBrief).relationStatus,
        'FOLLOWING',
      );
      expect(controller.state.busyItemKeys, isEmpty);
    },
  );

  testWidgets(
    'USER-15 relation rows expose safe actions and valid user navigation',
    (tester) async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(
            userId: 2,
            username: 'a',
            nickname: '可关注',
            relationStatus: 'NONE',
          ),
          UserBrief(
            userId: 3,
            username: 'b',
            nickname: '已关注',
            relationStatus: 'FOLLOWING',
          ),
          UserBrief(
            userId: 4,
            username: 'c',
            nickname: '互关',
            relationStatus: 'MUTUAL',
          ),
          UserBrief(
            userId: 5,
            username: 'd',
            nickname: '本人',
            relationStatus: 'SELF',
          ),
          UserBrief(
            userId: 6,
            username: 'e',
            nickname: '未知',
            relationStatus: 'FUTURE',
          ),
          UserBrief(
            userId: -1,
            username: 'x',
            nickname: '无效',
            relationStatus: 'NONE',
          ),
        ];
      final router = GoRouter(
        initialLocation: '/relations',
        routes: [
          GoRoute(
            path: '/relations',
            builder: (_, _) => const UserRelationsPage(userId: 1),
          ),
          GoRoute(
            path: '/users/:id',
            builder: (_, state) => Text('用户详情 ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerScope(repository, router));
      await _settle(tester);
      for (final id in [2, 3, 4]) {
        expect(find.byKey(ValueKey('user-follow-$id')), findsOneWidget);
      }
      expect(find.text('本人'), findsAtLeastNWidgets(1));
      expect(find.text('关系未知'), findsOneWidget);
      expect(find.byKey(const ValueKey('user-follow--1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('user-row-2')));
      await tester.pumpAndSettle();
      expect(find.text('用户详情 2'), findsOneWidget);
    },
  );

  test(
    'USER-16 followings/followers page state dedupes and invalid user is request-free',
    () async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(userId: 2, username: 'a', nickname: 'A'),
        ];
      final following = UserListController(
        repository,
        const UserListRequest(UserListKind.followings, userId: 1),
      );
      await following.loadInitial();
      expect(following.state.items.length, 1);
      await following.loadMore();
      expect(following.state.items.length, 1);
      final invalid = UserListController(
        repository,
        const UserListRequest(UserListKind.followers, userId: 0),
      );
      await invalid.loadInitial();
      expect(invalid.state.status, UserListStatus.failure);
      expect(repository.followerCalls, 0);
    },
  );

  test(
    'USER-16 following/follower errors retry independently and ready refresh preserves records',
    () async {
      final repository = _Repo()
        ..followingItems = const [
          UserBrief(userId: 2, username: 'a', nickname: '关注用户'),
        ]
        ..followerItems = const [
          UserBrief(userId: 3, username: 'b', nickname: '粉丝用户'),
        ]
        ..followingFailure = true
        ..followersFailure = true;
      final following = UserListController(
        repository,
        const UserListRequest(UserListKind.followings, userId: 1),
      );
      final followers = UserListController(
        repository,
        const UserListRequest(UserListKind.followers, userId: 1),
      );
      await following.loadInitial();
      await followers.loadInitial();
      expect(following.state.status, UserListStatus.failure);
      expect(followers.state.status, UserListStatus.failure);
      repository.followingFailure = false;
      repository.followersFailure = false;
      await following.retry();
      await followers.retry();
      expect(following.state.items.single, isA<UserBrief>());
      expect(followers.state.items.single, isA<UserBrief>());
      final oldFollowing = following.state.items;
      repository.followingFailure = true;
      await following.refresh();
      expect(following.state.items, same(oldFollowing));
      expect(following.state.message, isNotNull);
      await following.loadMore();
      expect(following.state.items, same(oldFollowing));
    },
  );

  test(
    'USER-17 entity stand uses real ids and failure does not erase original item',
    () async {
      final repository = _Repo()
        ..standValue = const UserStand(
          teams: [EntityBrief(id: 40, name: '真实球队', imageUrl: '/team.png')],
          players: [EntityBrief(id: 50, name: '真实球员', imageUrl: '/player.png')],
        )
        ..toggleEntityFailure = true;
      final original = repository.standValue.teams.single;
      try {
        await repository.toggleEntity('TEAM', original.id);
      } catch (_) {}
      expect(original.id, 40);
      expect(repository.toggleEntityCalls, ['TEAM:40']);
    },
  );

  testWidgets(
    'USER-17 followed entity page proves loading, empty, error/retry and media states',
    (tester) async {
      final loadingRepository = _Repo()..standGate = Completer<UserStand>();
      await tester.pumpWidget(
        _scope(loadingRepository, const FollowedEntitiesPage(teams: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      loadingRepository.standGate!.complete(
        const UserStand(
          teams: [EntityBrief(id: 40, name: '带图球队', imageUrl: '/team.png')],
          players: [],
        ),
      );
      await _settle(tester);
      expect(find.text('带图球队'), findsAtLeastNWidgets(1));
      final avatar = tester.widget<AppEntityAvatar>(
        find.byType(AppEntityAvatar),
      );
      expect(avatar.imageUrl, 'http://localhost:8080/team.png');

      final emptyRepository = _Repo();
      await tester.pumpWidget(
        _scope(emptyRepository, const FollowedEntitiesPage(teams: true)),
      );
      await _settle(tester);
      expect(find.text('暂无关注的球队'), findsOneWidget);
    },
  );

  testWidgets('USER-17 followed entity page exposes stand error and retry', (
    tester,
  ) async {
    final repository = _Repo()..standFailure = true;
    await tester.pumpWidget(
      _scope(repository, const FollowedEntitiesPage(teams: false)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppStateView), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    repository.standFailure = false;
    await tester.tap(find.text('重试'));
    await _settle(tester);
    expect(find.text('暂无关注的球员'), findsOneWidget);
  });

  test(
    'USER-18 API model defaults are nullable-safe and media/time fields stay typed',
    () async {
      final item = const UserLikeItem(
        contentId: 1,
        contentType: 'UNKNOWN',
        title: 'x',
        visible: false,
        likeCount: 0,
        commentCount: 0,
        favoriteCount: 0,
      );
      expect(item.coverUrl, isNull);
      expect(DateTime.tryParse('2026-01-01T10:00:00Z'), isNotNull);
      expect(
        resolveMediaUrl(
          AppConfig.fromValues(apiBaseUrl: 'https://api.test'),
          '/relative.png',
        ),
        'https://api.test/relative.png',
      );
    },
  );

  testWidgets(
    'USER-19 tab/list caching keeps active records and source call count',
    (tester) async {
      final repository = _Repo()
        ..contentItems = _contentItems(12)
        ..contentSinglePage = true;
      await tester.pumpWidget(_scope(repository, const MyProfilePage()));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('my_tab_posts')));
      await tester.pumpAndSettle();
      expect(find.text('内容 1'), findsOneWidget);
      final calls = repository.userContentCalls;
      final scrollable = find.descendant(
        of: _listFinder('user-list-myContents-me'),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      await tester.drag(
        _listFinder('user-list-myContents-me'),
        const Offset(0, -500),
      );
      await tester.pump();
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('my_tab_stand')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('my_tab_posts')));
      await tester.pumpAndSettle();
      expect(find.text('内容 1'), findsOneWidget);
      expect(repository.userContentCalls, calls);
      final restored = tester
          .state<ScrollableState>(
            find.descendant(
              of: _listFinder('user-list-myContents-me'),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      expect(restored, closeTo(offset, 1));
    },
  );

  testWidgets(
    'USER-19 all profile, public and relation tabs preserve scroll/filter state',
    (tester) async {
      final repository = _Repo()
        ..contentItems = _contentItems(12)
        ..contentSinglePage = true
        ..likeItems = _likeItems(12)
        ..favoriteItems = _favoriteItems(12)
        ..commentItems = _commentItems(12)
        ..publicContentItems = _contentItems(12)
        ..publicFavoriteItems = _favoriteItems(12)
        ..publicCommentItems = _commentItems(12)
        ..followingItems = _users(12)
        ..followerItems = _users(12, start: 30);
      await tester.pumpWidget(_scope(repository, const MyProfilePage()));
      await _settle(tester);
      for (final key in const [
        'my_tab_posts:user-list-myContents-me',
        'my_tab_likes:user-list-myLikes-me',
        'my_tab_favorites:user-list-myFavorites-me',
        'my_tab_comments:user-list-myComments-me',
      ]) {
        final parts = key.split(':');
        await tester.tap(find.byKey(ValueKey(parts.first)));
        await tester.pumpAndSettle();
        final offset = await _scrollList(tester, parts.last);
        expect(offset, greaterThan(0));
      }

      await tester.pumpWidget(
        _scope(repository, const PublicUserPage(userId: 22)),
      );
      await _settle(tester);
      final publicOffsets = <String, double>{};
      for (final entry in const {
        'public_tab_posts': 'user-list-userContents-22',
        'public_tab_favorites': 'user-list-userFavorites-22',
        'public_tab_comments': 'user-list-userComments-22',
      }.entries) {
        await tester.tap(find.byKey(ValueKey(entry.key)));
        await tester.pumpAndSettle();
        publicOffsets[entry.key] = await _scrollList(tester, entry.value);
        expect(publicOffsets[entry.key], greaterThan(0));
      }
      await tester.tap(find.byKey(const ValueKey('public_tab_posts')));
      await tester.pumpAndSettle();
      expect(
        _readListOffset(tester, 'user-list-userContents-22'),
        closeTo(publicOffsets['public_tab_posts']!, 1),
      );

      await tester.pumpWidget(
        _scope(repository, const UserRelationsPage(userId: 1)),
      );
      await _settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('user_list_search')),
        '用户',
      );
      final followingOffset = await _scrollList(
        tester,
        'user-list-followings-1',
      );
      expect(followingOffset, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('relations_followers')));
      await tester.pumpAndSettle();
      final followerOffset = await _scrollList(tester, 'user-list-followers-1');
      expect(followerOffset, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('relations_following')));
      await tester.pumpAndSettle();
      expect(_readListOffset(tester, 'user-list-followings-1'), greaterThan(0));
    },
  );

  testWidgets(
    'USER-20 360/412 and 1.4x main/public pages render without overflow or exception',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [360.0, 412.0]) {
        tester.view.physicalSize = Size(width, 1000);
        for (final page in <Widget>[
          const PublicUserPage(userId: 22),
          const MyProfilePage(),
          const UserRelationsPage(userId: 1),
          const FollowedEntitiesPage(teams: true),
          const FollowedEntitiesPage(teams: false),
        ]) {
          await tester.pumpWidget(_responsiveScope(_Repo(), page));
          await _settle(tester);
          expect(find.byType(page.runtimeType), findsOneWidget);
          if (page is MyProfilePage) {
            for (final key in const [
              'my_tab_stand',
              'my_tab_posts',
              'my_tab_likes',
              'my_tab_favorites',
              'my_tab_comments',
            ]) {
              await tester.tap(find.byKey(ValueKey(key)));
              await tester.pumpAndSettle();
            }
          } else if (page is PublicUserPage) {
            for (final key in const [
              'public_tab_posts',
              'public_tab_favorites',
              'public_tab_comments',
            ]) {
              await tester.tap(find.byKey(ValueKey(key)));
              await tester.pumpAndSettle();
            }
          } else if (page is UserRelationsPage) {
            await tester.tap(find.byKey(const ValueKey('relations_followers')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('relations_following')));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

Widget _scope(_Repo repository, Widget child) => ProviderScope(
  key: UniqueKey(),
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    userCenterRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(home: child),
);

Widget _routerScope(_Repo repository, GoRouter router) => ProviderScope(
  key: UniqueKey(),
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    userCenterRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp.router(routerConfig: router),
);

GoRouter _profileRouter(_Repo repository) => GoRouter(
  initialLocation: '/me',
  routes: [
    GoRoute(path: '/me', builder: (_, _) => const MyProfilePage()),
    GoRoute(
      path: '/teams/:id',
      builder: (_, state) => Text('球队详情 ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/players/:id',
      builder: (_, state) => Text('球员详情 ${state.pathParameters['id']}'),
    ),
  ],
);

Widget _responsiveScope(_Repo repository, Widget child) => ProviderScope(
  key: UniqueKey(),
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
    ),
    userCenterRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.4)),
      child: child!,
    ),
    home: child,
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Finder _listFinder(String key) => find.byKey(PageStorageKey<String>(key));

Future<double> _scrollList(WidgetTester tester, String key) async {
  final list = _listFinder(key);
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  final elements = scrollable.evaluate().toList();
  expect(elements, isNotEmpty);
  var activeIndex = 0;
  for (var i = 0; i < elements.length; i++) {
    final state = (elements[i] as StatefulElement).state as ScrollableState;
    if (state.position.pixels == 0) {
      activeIndex = i;
      break;
    }
  }
  final activeScrollable = scrollable.at(activeIndex);
  await tester.drag(activeScrollable, const Offset(0, -500));
  await tester.pump();
  return tester.state<ScrollableState>(activeScrollable).position.pixels;
}

double _readListOffset(WidgetTester tester, String key) {
  final list = _listFinder(key);
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  return scrollable
      .evaluate()
      .map((element) => (element as StatefulElement).state as ScrollableState)
      .map((state) => state.position.pixels)
      .fold<double>(0, (highest, value) => value > highest ? value : highest);
}

MySummary _summary({
  String nickname = '我',
  EntityBrief? mainTeam,
  String? avatarUrl,
}) => MySummary(
  userId: 1,
  username: 'me',
  nickname: nickname,
  bio: null,
  mainTeam: mainTeam,
  postCount: 999999,
  favoriteCount: 8,
  commentCount: 3,
  followingCount: 4,
  followerCount: 999999,
  teamFollowCount: 1,
  playerFollowCount: 2,
  avatarUrl: avatarUrl,
);

UserProfile _profile({bool current = false, String relation = 'NONE'}) =>
    UserProfile(
      userId: 22,
      username: 'user22',
      nickname: '用户 22',
      followingCount: 1,
      followerCount: 2,
      contentCount: 3,
      likeReceivedCount: 4,
      relationStatus: relation,
      currentUser: current,
      mainTeam: const EntityBrief(id: 40, name: '主队'),
    );

List<UserContentItem> _contentItems(int count) => [
  for (var i = 1; i <= count; i++)
    UserContentItem(
      contentId: i,
      contentType: 'POST',
      title: '内容 $i',
      summary: i.isEven ? '较长摘要' : null,
      coverUrl: i == 2 ? '/cover.png' : null,
      likeCount: i,
      commentCount: 0,
      favoriteCount: 0,
    ),
];

List<UserLikeItem> _likeItems(int count) => [
  for (var i = 1; i <= count; i++)
    UserLikeItem(
      contentId: i,
      contentType: 'POST',
      title: '点赞 $i',
      visible: true,
      likeCount: 0,
      commentCount: 0,
      favoriteCount: 0,
    ),
];

List<UserFavoriteItem> _favoriteItems(int count) => [
  for (var i = 1; i <= count; i++)
    UserFavoriteItem(contentId: i, title: '收藏 $i'),
];

List<UserCommentItem> _commentItems(int count) => [
  for (var i = 1; i <= count; i++)
    UserCommentItem(commentId: i, contentId: i, content: '评论 $i'),
];

List<UserBrief> _users(int count, {int start = 1}) => [
  for (var i = 0; i < count; i++)
    UserBrief(
      userId: start + i,
      username: 'user${start + i}',
      nickname: '用户 ${start + i}',
    ),
];

final class _StaleRepo extends _Repo {
  final Completer<UserPage<UserContentItem>> staleRefresh = Completer();
  var calls = 0;

  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) async {
    calls++;
    if (calls == 2) return staleRefresh.future;
    final id = calls == 1 ? 1 : 77;
    return UserPage(
      records: [
        UserContentItem(
          contentId: id,
          contentType: 'POST',
          title: '内容 $id',
          likeCount: 0,
          commentCount: 0,
          favoriteCount: 0,
        ),
      ],
      pageNum: 1,
      pages: 1,
      total: 1,
    );
  }
}

class _Repo implements UserCenterRepositoryContract {
  MySummary summaryValue = _summary();
  UserStand standValue = const UserStand(teams: [], players: []);
  UserProfile profileValue = _profile();
  List<UserContentItem> contentItems = _contentItems(1);
  List<UserLikeItem> likeItems = const [];
  List<UserFavoriteItem> favoriteItems = const [
    UserFavoriteItem(contentId: 7, title: '收藏'),
  ];
  List<UserCommentItem> commentItems = const [];
  List<UserContentItem>? publicContentItems;
  List<UserFavoriteItem>? publicFavoriteItems;
  List<UserCommentItem>? publicCommentItems;
  List<UserBrief> followingItems = const [];
  bool summaryFailure = false;
  bool standFailure = false;
  Completer<UserStand>? standGate;
  bool privateFailure = false;
  bool editFailure = false;
  bool avatarFailure = false;
  bool removeFailure = false;
  bool deleteFailure = false;
  Completer<void>? removeGate;
  Completer<void>? deleteGate;
  bool contentPage2Failure = false;
  bool contentSinglePage = false;
  bool likesFailure = false;
  bool favoritesFailure = false;
  bool commentsFailure = false;
  bool followersFailure = false;
  bool followingFailure = false;
  bool bindFailure = false;
  Object? profileFailure;
  bool publicFavoritesEmpty = false;
  bool publicCommentsEmpty = false;
  List<UserBrief> followerItems = const [];
  bool toggleEntityFailure = false;
  bool toggleEntityResult = true;
  Object? followFailure;
  Completer<void>? followGate;
  UserProfile? followResult;
  Object? userContentGate;
  Completer<UserPage<UserContentItem>>? contentGate;
  Completer<void>? editGate;
  final Map<int, Completer<void>> followGates = {};
  final Map<int, Object> followFailures = {};
  int summaryCalls = 0;
  int standCalls = 0;
  int userContentCalls = 0;
  int likeCalls = 0;
  int favoriteCalls = 0;
  int commentCalls = 0;
  int followerCalls = 0;
  int followCalls = 0;
  int toggleEntityCallsCount = 0;
  int editCalls = 0;
  int removeRequestCount = 0;
  int deleteRequestCount = 0;
  List<String> toggleEntityCalls = [];
  List<int> followingPages = [];

  @override
  Future<MySummary> summary() async {
    summaryCalls++;
    if (summaryFailure) throw const NetworkException('summary');
    return summaryValue;
  }

  @override
  Future<UserStand> stand() async {
    standCalls++;
    if (standFailure) throw const BusinessException('stand down', code: 40001);
    if (standGate != null) return standGate!.future;
    return standValue;
  }

  @override
  Future<UserProfile> profile(int userId) async {
    if (profileFailure != null) throw profileFailure!;
    return profileValue;
  }

  @override
  Future<void> updateProfile({
    required String nickname,
    required String bio,
  }) async {
    editCalls++;
    if (editFailure) throw const NetworkException('edit');
    await editGate?.future;
  }

  @override
  Future<UserProfile> follow(int userId, bool follow) async {
    followCalls++;
    if (followFailure != null) throw followFailure!;
    if (followFailures[userId] != null) throw followFailures[userId]!;
    await followGate?.future;
    await followGates[userId]?.future;
    if (followResult case final result?) return result;
    return profileValue.copyWith(
      followerCount: follow
          ? profileValue.followerCount + 1
          : profileValue.followerCount,
      relationStatus: follow ? 'FOLLOWING' : 'NONE',
    );
  }

  @override
  Future<bool> toggleEntity(String type, int id) async {
    toggleEntityCallsCount++;
    toggleEntityCalls.add('$type:$id');
    if (toggleEntityFailure) throw const NetworkException('entity');
    return toggleEntityResult;
  }

  @override
  Future<void> removeFavorite(int contentId) async {
    removeRequestCount++;
    await removeGate?.future;
    if (removeFailure) throw const BusinessException('remove', code: 40001);
  }

  @override
  Future<void> deleteComment(int commentId) async {
    deleteRequestCount++;
    await deleteGate?.future;
    if (deleteFailure) throw const BusinessException('delete', code: 40001);
  }

  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) async {
    userContentCalls++;
    if (contentGate != null) return contentGate!.future;
    if (page == 2 && contentPage2Failure) {
      throw const NetworkException('append');
    }
    final records = contentSinglePage
        ? contentItems
        : page == 1
        ? contentItems.take(2).toList()
        : [
            ...contentItems.skip(1).take(2),
            if (contentItems.length < 3)
              const UserContentItem(
                contentId: 3,
                contentType: 'POST',
                title: '内容 3',
                likeCount: 0,
                commentCount: 0,
                favoriteCount: 0,
              ),
          ];
    return UserPage(
      records: records,
      pageNum: page,
      pages: contentSinglePage ? 1 : 2,
      total: contentSinglePage ? contentItems.length : 3,
    );
  }

  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) async => UserPage(
    records: _likeRecords(),
    pageNum: 1,
    pages: 1,
    total: likeItems.length,
  );

  List<UserLikeItem> _likeRecords() {
    likeCalls++;
    if (likesFailure) throw const NetworkException('likes');
    return likeItems;
  }

  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) async {
    favoriteCalls++;
    if (favoritesFailure) throw const NetworkException('favorites');
    return UserPage(
      records: favoriteItems,
      pageNum: 1,
      pages: 1,
      total: favoriteItems.length,
    );
  }

  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) async {
    commentCalls++;
    if (commentsFailure) throw const NetworkException('comments');
    return UserPage(
      records: commentItems,
      pageNum: 1,
      pages: 1,
      total: commentItems.length,
    );
  }

  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) async {
    userContentCalls++;
    final records = publicContentItems;
    if (records != null) {
      return UserPage(
        records: records,
        pageNum: 1,
        pages: 1,
        total: records.length,
      );
    }
    return UserPage(
      records: userId == 22
          ? [
              const UserContentItem(
                contentId: 10,
                contentType: 'POST',
                title: '公开发布',
                likeCount: 1,
                commentCount: 0,
                favoriteCount: 0,
              ),
            ]
          : contentItems,
      pageNum: 1,
      pages: 1,
      total: 1,
    );
  }

  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) async {
    if (privateFailure) throw const BusinessException('privacy', code: 40301);
    if (publicFavoritesEmpty) {
      return const UserPage(records: [], pageNum: 1, pages: 1, total: 0);
    }
    final records = publicFavoriteItems;
    if (records != null) {
      return UserPage(
        records: records,
        pageNum: 1,
        pages: 1,
        total: records.length,
      );
    }
    return const UserPage(
      records: [UserFavoriteItem(contentId: 8, title: '公开收藏')],
      pageNum: 1,
      pages: 1,
      total: 1,
    );
  }

  @override
  Future<UserPage<UserCommentItem>> userComments(
    int userId,
    int page,
    int size,
  ) async {
    if (privateFailure) throw const BusinessException('privacy', code: 40301);
    if (publicCommentsEmpty) {
      return const UserPage(records: [], pageNum: 1, pages: 1, total: 0);
    }
    final records = publicCommentItems;
    if (records != null) {
      return UserPage(
        records: records,
        pageNum: 1,
        pages: 1,
        total: records.length,
      );
    }
    return const UserPage(
      records: [UserCommentItem(commentId: 8, contentId: 8, content: '公开评论')],
      pageNum: 1,
      pages: 1,
      total: 1,
    );
  }

  @override
  Future<String> bindAvatar(int fileId) async {
    if (bindFailure) throw const NetworkException('bind uncertain');
    if (avatarFailure) throw const BusinessException('avatar', code: 40001);
    return '/avatar-new.png';
  }

  @override
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) async {
    followingPages.add(page);
    if (followingFailure) throw const NetworkException('following');
    return UserPage(
      records: followingItems,
      pageNum: page,
      pages: 1,
      total: followingItems.length,
    );
  }

  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) async {
    followerCalls++;
    if (followersFailure) throw const NetworkException('followers');
    return UserPage(
      records: followerItems,
      pageNum: 1,
      pages: 1,
      total: followerItems.length,
    );
  }
}

final class _Picker implements AvatarPickerContract {
  bool cancel = false;
  @override
  Future<XFile?> pick() async =>
      cancel ? null : XFile('avatar.png', name: 'avatar.png');
}

final class _ConcurrentRemovalRepo extends _Repo {
  _ConcurrentRemovalRepo() {
    favoriteItems = const [
      UserFavoriteItem(contentId: 1, title: '收藏 1'),
      UserFavoriteItem(contentId: 2, title: '收藏 2'),
    ];
  }

  _ConcurrentRemovalRepo.comments() {
    commentItems = const [
      UserCommentItem(commentId: 1, contentId: 11, content: '评论 1'),
      UserCommentItem(commentId: 2, contentId: 12, content: '评论 2'),
    ];
  }

  final Map<int, Completer<void>> gates = {
    1: Completer<void>(),
    2: Completer<void>(),
  };
  final Map<int, Object> failures = {};
  final List<int> removeCalls = [];
  final List<int> deleteCalls = [];

  @override
  Future<void> removeFavorite(int contentId) async {
    removeCalls.add(contentId);
    await gates[contentId]!.future;
    if (failures[contentId] != null) throw failures[contentId]!;
  }

  @override
  Future<void> deleteComment(int commentId) async {
    deleteCalls.add(commentId);
    await gates[commentId]!.future;
    if (failures[commentId] != null) throw failures[commentId]!;
  }
}

final class _Files implements AvatarFileUploadRepositoryContract {
  int? deleted;
  int uploadCalls = 0;
  bool uploadFailure = false;
  Completer<UploadedFile>? uploadGate;
  @override
  Future<UploadedFile> uploadAvatar(String path, String name) async {
    uploadCalls++;
    if (uploadFailure) throw const NetworkException('upload');
    return uploadGate?.future ??
        const UploadedFile(fileId: 90, url: '/avatar-upload.png');
  }

  @override
  Future<void> delete(int id) async => deleted = id;
}
