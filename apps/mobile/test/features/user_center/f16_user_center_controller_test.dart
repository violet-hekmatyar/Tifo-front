import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/user_center/data/user_center_repository.dart';
import 'package:tifo/features/user_center/domain/user_center_models.dart';
import 'package:tifo/features/user_center/presentation/controllers/user_center_controllers.dart';

void main() {
  test(
    'likes pagination deduplicates and privacy is not an empty list',
    () async {
      final repository = _Users();
      final likes = UserListController(
        repository,
        const UserListRequest(UserListKind.myLikes),
      );
      await likes.loadInitial();
      await likes.loadMore();
      expect(
        likes.state.items.whereType<UserLikeItem>().map((e) => e.contentId),
        [1, 2],
      );

      final private = UserListController(
        repository,
        const UserListRequest(UserListKind.userFavorites, userId: 22),
      );
      await private.loadInitial();
      expect(private.state.status, UserListStatus.restricted);
      expect(private.state.message, contains('隐私保护'));

      repository.restrictFavorites = false;
      final refreshed = UserListController(
        repository,
        const UserListRequest(UserListKind.userFavorites, userId: 22),
      );
      await refreshed.loadInitial();
      repository.restrictFavorites = true;
      await refreshed.refresh();
      expect(refreshed.state.status, UserListStatus.restricted);
    },
  );

  test('all five relationship states preserve mutual direction', () async {
    expect(userRelationLabel('SELF'), '本人');
    expect(userRelationLabel('NONE'), '未关注');
    expect(userRelationLabel('FOLLOWING'), '已关注');
    expect(userRelationLabel('FOLLOWED_BY'), '关注了你');
    expect(userRelationLabel('MUTUAL'), '互相关注');
    expect(relationAfterLocalAction('FOLLOWED_BY', follow: true), 'MUTUAL');
    expect(relationAfterLocalAction('MUTUAL', follow: false), 'FOLLOWED_BY');
  });

  test(
    'avatar bind failure keeps old avatar and deletes orphan upload',
    () async {
      final users = _Users()..avatarFails = true;
      final files = _AvatarFiles();
      final controller = AvatarUpdateController(users, files, _Picker());
      await controller.chooseAndUpload();
      expect(controller.state.avatarUrl, isNull);
      expect(controller.state.message, isNotNull);
      expect(files.deleted, 90);

      users.avatarFails = false;
      await controller.chooseAndUpload();
      expect(controller.state.avatarUrl, '/uploads/avatar.png');
    },
  );

  test('picker failure always restores an enabled avatar action', () async {
    final controller = AvatarUpdateController(
      _Users(),
      _AvatarFiles(),
      _Picker(fail: true),
    );
    await controller.chooseAndUpload();
    expect(controller.state.busy, isFalse);
    expect(controller.state.message, contains('无法读取'));
  });

  test('ambiguous bind failure reconciles before deleting upload', () async {
    final users = _Users()
      ..avatarNetworkFails = true
      ..summaryAvatar = '/uploads/avatar.png';
    final files = _AvatarFiles();
    final controller = AvatarUpdateController(users, files, _Picker());
    await controller.chooseAndUpload();
    expect(controller.state.avatarUrl, '/uploads/avatar.png');
    expect(files.deleted, isNull);
  });
}

final class _Users implements UserCenterRepositoryContract {
  bool avatarFails = false;
  bool avatarNetworkFails = false;
  String? summaryAvatar;
  bool restrictFavorites = true;
  @override
  Future<UserPage<UserLikeItem>> myLikes(int page, int size) async => UserPage(
    records: [
      UserLikeItem(
        contentId: page == 1 ? 1 : 1,
        contentType: 'POST',
        title: '点赞',
        visible: true,
        likeCount: 1,
        commentCount: 0,
        favoriteCount: 0,
      ),
      if (page == 2)
        const UserLikeItem(
          contentId: 2,
          contentType: 'POST',
          title: '点赞2',
          visible: true,
          likeCount: 1,
          commentCount: 0,
          favoriteCount: 0,
        ),
    ],
    pageNum: page,
    pages: 2,
    total: 2,
  );
  @override
  Future<UserPage<UserFavoriteItem>> userFavorites(
    int userId,
    int page,
    int size,
  ) async {
    if (restrictFavorites) {
      throw const BusinessException('无权限', code: 40301);
    }
    return const UserPage(
      records: [UserFavoriteItem(contentId: 80, title: '收藏')],
      pageNum: 1,
      pages: 1,
      total: 1,
    );
  }

  @override
  Future<String> bindAvatar(int fileId) async {
    if (avatarFails) {
      throw const BusinessException('不允许绑定', code: 40001);
    }
    if (avatarNetworkFails) throw const NetworkException('timeout');
    return '/uploads/avatar.png';
  }

  @override
  Future<MySummary> summary() async => MySummary(
    userId: 1,
    username: 'me',
    nickname: '我',
    avatarUrl: summaryAvatar,
    postCount: 0,
    favoriteCount: 0,
    commentCount: 0,
    followingCount: 0,
    followerCount: 0,
    teamFollowCount: 0,
    playerFollowCount: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _AvatarFiles implements AvatarFileUploadRepositoryContract {
  int? deleted;
  @override
  Future<UploadedFile> uploadAvatar(String path, String name) async =>
      const UploadedFile(fileId: 90, url: '/uploads/avatar.png');
  @override
  Future<void> delete(int id) async => deleted = id;
}

final class _Picker implements AvatarPickerContract {
  _Picker({this.fail = false});
  final bool fail;
  @override
  Future<XFile?> pick() async {
    if (fail) throw StateError('picker unavailable');
    return XFile('avatar.png', name: 'avatar.png');
  }
}
