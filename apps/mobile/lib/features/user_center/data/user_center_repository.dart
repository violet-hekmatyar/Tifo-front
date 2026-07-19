import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/user_center_models.dart';
import 'user_center_api.dart';

abstract interface class UserCenterRepositoryContract {
  Future<MySummary> summary();
  Future<UserStand> stand();
  Future<UserProfile> profile(int userId);
  Future<void> updateProfile({required String nickname, required String bio});
  Future<UserProfile> follow(int userId, bool follow);
  Future<bool> toggleEntity(String type, int id);
  Future<void> removeFavorite(int contentId);
  Future<void> deleteComment(int commentId);
  Future<UserPage<UserContentItem>> myContents(int page, int size);
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size);
  Future<UserPage<UserCommentItem>> myComments(int page, int size);
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  );
  Future<UserPage<UserBrief>> followings(int userId, int page, int size);
  Future<UserPage<UserBrief>> followers(int userId, int page, int size);
}

final userCenterRepositoryProvider = Provider<UserCenterRepositoryContract>(
  (ref) => UserCenterRepository(UserCenterApi(ref.watch(apiClientProvider))),
);

final class UserCenterRepository implements UserCenterRepositoryContract {
  const UserCenterRepository(this._api);
  final UserCenterApi _api;
  @override
  Future<MySummary> summary() => _api.summary();
  @override
  Future<UserStand> stand() => _api.stand();
  @override
  Future<UserProfile> profile(int userId) => _api.profile(userId);
  @override
  Future<void> updateProfile({required String nickname, required String bio}) =>
      _api.updateProfile(nickname: nickname, bio: bio);
  @override
  Future<UserProfile> follow(int userId, bool follow) =>
      _api.follow(userId, follow);
  @override
  Future<bool> toggleEntity(String type, int id) => _api.toggleEntity(type, id);
  @override
  Future<void> removeFavorite(int contentId) => _api.removeFavorite(contentId);
  @override
  Future<void> deleteComment(int commentId) => _api.deleteComment(commentId);
  @override
  Future<UserPage<UserContentItem>> myContents(int page, int size) =>
      _api.myContents(page, size);
  @override
  Future<UserPage<UserFavoriteItem>> myFavorites(int page, int size) =>
      _api.myFavorites(page, size);
  @override
  Future<UserPage<UserCommentItem>> myComments(int page, int size) =>
      _api.myComments(page, size);
  @override
  Future<UserPage<UserContentItem>> userContents(
    int userId,
    int page,
    int size,
  ) => _api.userContents(userId, page, size);
  @override
  Future<UserPage<UserBrief>> followings(int userId, int page, int size) =>
      _api.followings(userId, page, size);
  @override
  Future<UserPage<UserBrief>> followers(int userId, int page, int size) =>
      _api.followers(userId, page, size);
}
