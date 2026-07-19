import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/message/presentation/messages_unavailable_page.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';

void main() {
  test('my posts loads dedicated paged records and appends', () async {
    final repository = _FakeRepository();
    final controller = UserListController(
      repository,
      const UserListRequest(UserListKind.myContents),
    );
    await controller.loadInitial();
    expect(controller.state.items.single, isA<UserContentItem>());
    expect(controller.state.hasMore, isTrue);
    await controller.loadMore();
    expect(controller.state.items.length, 2);
    expect(controller.state.hasMore, isFalse);
    expect(repository.myContentPages, [1, 2]);
  });

  test(
    'public follow is optimistic, duplicate safe, and authoritative',
    () async {
      final repository = _FakeRepository()..followGate = Completer<void>();
      final controller = PublicProfileController(repository, 22);
      await controller.load();
      final first = controller.toggleFollow();
      expect(controller.state.profile!.followed, isTrue);
      expect(controller.state.followBusy, isTrue);
      final duplicate = controller.toggleFollow();
      expect(repository.followCalls, 1);
      repository.followGate!.complete();
      await Future.wait([first, duplicate]);
      expect(controller.state.profile!.followerCount, 4);
      expect(controller.state.followBusy, isFalse);
    },
  );

  test('current user never sends self-follow request', () async {
    final repository = _FakeRepository()..selfProfile = true;
    final controller = PublicProfileController(repository, 22);
    await controller.load();
    await controller.toggleFollow();
    expect(repository.followCalls, 0);
  });

  testWidgets('message center explains backend gap without fake messages', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MessagesUnavailablePage()));
    expect(find.text('消息能力暂不可用'), findsOneWidget);
    expect(find.textContaining('不会展示虚构消息'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}

final class _FakeRepository implements UserCenterRepositoryContract {
  final List<int> myContentPages = [];
  Completer<void>? followGate;
  int followCalls = 0;
  bool selfProfile = false;

  UserProfile get _profile => UserProfile(
    userId: 22,
    username: 'user_b',
    nickname: '用户 B',
    followingCount: 1,
    followerCount: 3,
    contentCount: 2,
    likeReceivedCount: 5,
    relationStatus: 'NONE',
    currentUser: selfProfile,
  );

  @override
  Future<UserProfile> profile(int userId) async => _profile;
  @override
  Future<void> updateProfile({
    required String nickname,
    required String bio,
  }) async {}
  @override
  Future<UserProfile> follow(int userId, bool follow) async {
    followCalls++;
    await followGate?.future;
    return _profile.copyWith(
      followerCount: follow ? 4 : 3,
      relationStatus: follow ? 'FOLLOWING' : 'NONE',
    );
  }

  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) async {
    myContentPages.add(page);
    return UserPage(
      records: [
        UserContentItem(
          contentId: page,
          contentType: 'POST',
          title: '真实发布 $page',
          likeCount: 0,
          commentCount: 0,
          favoriteCount: 0,
        ),
      ],
      pageNum: page,
      pages: 2,
      total: 2,
    );
  }

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
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
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
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) =>
      throw UnimplementedError();
  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) =>
      throw UnimplementedError();
}
