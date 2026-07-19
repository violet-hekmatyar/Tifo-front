final class UserBrief {
  const UserBrief({
    required this.userId,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.relationStatus = 'NONE',
  });

  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String relationStatus;

  bool get followed =>
      relationStatus == 'FOLLOWING' || relationStatus == 'MUTUAL';
}

final class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
    required this.nickname,
    required this.followingCount,
    required this.followerCount,
    required this.contentCount,
    required this.likeReceivedCount,
    required this.relationStatus,
    required this.currentUser,
    this.avatarUrl,
    this.bio,
    this.mainTeam,
  });

  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final EntityBrief? mainTeam;
  final int followingCount;
  final int followerCount;
  final int contentCount;
  final int likeReceivedCount;
  final String relationStatus;
  final bool currentUser;

  bool get followed =>
      relationStatus == 'FOLLOWING' || relationStatus == 'MUTUAL';

  UserProfile copyWith({
    int? followingCount,
    int? followerCount,
    String? relationStatus,
  }) => UserProfile(
    userId: userId,
    username: username,
    nickname: nickname,
    avatarUrl: avatarUrl,
    bio: bio,
    mainTeam: mainTeam,
    followingCount: followingCount ?? this.followingCount,
    followerCount: followerCount ?? this.followerCount,
    contentCount: contentCount,
    likeReceivedCount: likeReceivedCount,
    relationStatus: relationStatus ?? this.relationStatus,
    currentUser: currentUser,
  );
}

final class MySummary {
  const MySummary({
    required this.userId,
    required this.username,
    required this.nickname,
    required this.postCount,
    required this.favoriteCount,
    required this.commentCount,
    required this.followingCount,
    required this.followerCount,
    required this.teamFollowCount,
    required this.playerFollowCount,
    this.avatarUrl,
    this.bio,
    this.mainTeam,
  });

  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final EntityBrief? mainTeam;
  final int postCount;
  final int favoriteCount;
  final int commentCount;
  final int followingCount;
  final int followerCount;
  final int teamFollowCount;
  final int playerFollowCount;
}

final class EntityBrief {
  const EntityBrief({
    required this.id,
    required this.name,
    this.imageUrl,
    this.subtitle,
  });
  final int id;
  final String name;
  final String? imageUrl;
  final String? subtitle;
}

final class UserContentItem {
  const UserContentItem({
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.likeCount,
    required this.commentCount,
    required this.favoriteCount,
    this.summary,
    this.coverUrl,
    this.publishTime,
  });
  final int contentId;
  final String contentType;
  final String title;
  final String? summary;
  final String? coverUrl;
  final int likeCount;
  final int commentCount;
  final int favoriteCount;
  final DateTime? publishTime;
}

final class UserFavoriteItem {
  const UserFavoriteItem({
    required this.contentId,
    required this.title,
    this.summary,
    this.coverUrl,
    this.favoriteTime,
  });
  final int contentId;
  final String title;
  final String? summary;
  final String? coverUrl;
  final DateTime? favoriteTime;
}

final class UserCommentItem {
  const UserCommentItem({
    required this.commentId,
    required this.contentId,
    required this.content,
    this.contentTitle,
    this.createTime,
  });
  final int commentId;
  final int contentId;
  final String content;
  final String? contentTitle;
  final DateTime? createTime;
}

final class UserPage<T> {
  const UserPage({
    required this.records,
    required this.pageNum,
    required this.pages,
    required this.total,
  });
  final List<T> records;
  final int pageNum;
  final int pages;
  final int total;
  bool get hasMore => pageNum < pages;
}

final class UserStand {
  const UserStand({required this.teams, required this.players});
  final List<EntityBrief> teams;
  final List<EntityBrief> players;
}
