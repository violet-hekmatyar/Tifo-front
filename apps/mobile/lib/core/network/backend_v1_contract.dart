enum FeedTab {
  recommend('recommend'),
  news('news'),
  following('following'),
  team('team'),
  unknown('unknown');

  const FeedTab(this.wireValue);

  final String wireValue;

  static FeedTab fromWire(Object? value) => switch (value) {
    'recommend' => recommend,
    'news' => news,
    'following' => following,
    'team' => team,
    _ => unknown,
  };
}

enum FeedCardType {
  content('CONTENT'),
  match('MATCH'),
  hotComment('HOT_COMMENT'),
  discussion('DISCUSSION'),
  ranking('RANKING'),
  playerRating('PLAYER_RATING'),
  unknown('UNKNOWN');

  const FeedCardType(this.wireValue);

  final String wireValue;

  static FeedCardType fromWire(Object? value) => switch (value) {
    'CONTENT' => content,
    'MATCH' => match,
    'HOT_COMMENT' => hotComment,
    'DISCUSSION' => discussion,
    'RANKING' => ranking,
    'PLAYER_RATING' => playerRating,
    _ => unknown,
  };
}

enum SearchEntityType {
  team('TEAM'),
  player('PLAYER'),
  match('MATCH'),
  content('CONTENT'),
  unknown('UNKNOWN');

  const SearchEntityType(this.wireValue);

  final String wireValue;

  static SearchEntityType fromWire(Object? value) => switch (value) {
    'TEAM' => team,
    'PLAYER' => player,
    'MATCH' => match,
    'CONTENT' => content,
    _ => unknown,
  };
}

enum RecommendationBehaviorType {
  expose('EXPOSE'),
  click('CLICK'),
  detail('DETAIL'),
  like('LIKE'),
  favorite('FAVORITE'),
  comment('COMMENT'),
  unknown('UNKNOWN');

  const RecommendationBehaviorType(this.wireValue);

  final String wireValue;

  static RecommendationBehaviorType fromWire(Object? value) => switch (value) {
    'EXPOSE' => expose,
    'CLICK' => click,
    'DETAIL' => detail,
    'LIKE' => like,
    'FAVORITE' => favorite,
    'COMMENT' => comment,
    _ => unknown,
  };
}

enum RecommendationTargetType {
  content('CONTENT'),
  match('MATCH'),
  comment('COMMENT'),
  ranking('RANKING'),
  playerRating('PLAYER_RATING'),
  unknown('UNKNOWN');

  const RecommendationTargetType(this.wireValue);

  final String wireValue;

  static RecommendationTargetType fromWire(Object? value) => switch (value) {
    'CONTENT' => content,
    'MATCH' => match,
    'COMMENT' => comment,
    'RANKING' => ranking,
    'PLAYER_RATING' => playerRating,
    _ => unknown,
  };
}

enum RankingSnapshotType {
  currentStanding('CURRENT_STANDING'),
  unavailable('UNAVAILABLE'),
  unknown('UNKNOWN');

  const RankingSnapshotType(this.wireValue);

  final String wireValue;

  String get displayLabel => switch (this) {
    currentStanding => '当前排名',
    unavailable => '排名暂不可用',
    unknown => '排名',
  };

  static RankingSnapshotType fromWire(Object? value) => switch (value) {
    'CURRENT_STANDING' => currentStanding,
    'UNAVAILABLE' => unavailable,
    _ => unknown,
  };
}

final class RecommendationAttribution {
  const RecommendationAttribution({
    this.algorithmVersion,
    this.modelVersion,
    this.experimentId,
    this.experimentBucket,
    this.requestId,
    this.impressionId,
    this.position,
    this.reasonCode,
    this.reason,
  });

  final String? algorithmVersion;
  final String? modelVersion;
  final String? experimentId;
  final String? experimentBucket;
  final String? requestId;
  final String? impressionId;
  final int? position;
  final String? reasonCode;
  final String? reason;
}
