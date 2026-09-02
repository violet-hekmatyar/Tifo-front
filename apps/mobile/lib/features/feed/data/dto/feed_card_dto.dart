import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/json_value.dart';
import '../../domain/feed_card.dart';

final class FeedCardDto {
  const FeedCardDto(this.card);

  factory FeedCardDto.fromRaw(Object? raw) {
    final map = jsonMap(raw);
    if (map == null) {
      return const FeedCardDto(
        UnknownFeedCard(cardId: 'UNKNOWN_MALFORMED', rawCardType: 'MALFORMED'),
      );
    }

    final rawType = jsonString(map['cardType']) ?? 'UNKNOWN';
    final type = FeedCardType.fromWire(rawType);
    final payload = jsonMap(map['payload']);
    final cardId =
        jsonString(map['cardId']) ??
        jsonString(map['cardKey']) ??
        '${rawType}_${jsonInt(map['contentId']) ?? jsonInt(map['matchId']) ?? jsonInt(payload?['commentId']) ?? 'UNKNOWN'}';
    final cardKey = jsonString(map['cardKey']);
    final attribution = _attribution(map);

    try {
      final card = switch (type) {
        FeedCardType.content => _content(
          map,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.match => _match(
          map,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.hotComment => _hotCommentCard(
          payload,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.discussion => _discussion(
          payload,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.ranking => _ranking(
          payload,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.playerRating => _playerRating(
          payload,
          cardId,
          rawType,
          cardKey,
          attribution,
        ),
        FeedCardType.unknown => null,
      };
      return FeedCardDto(
        card ??
            UnknownFeedCard(
              cardId: cardId,
              rawCardType: rawType,
              cardKey: cardKey,
              attribution: attribution,
              payload: payload,
            ),
      );
    } catch (_) {
      return FeedCardDto(
        UnknownFeedCard(
          cardId: cardId,
          rawCardType: rawType,
          cardKey: cardKey,
          attribution: attribution,
          payload: payload,
        ),
      );
    }
  }

  final FeedCard card;

  FeedCard toDomain() => card;
}

ContentFeedCard? _content(
  Map<Object?, Object?> map,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  final contentId = jsonInt(map['contentId']);
  final title = jsonString(map['title']);
  if (contentId == null || title == null) return null;
  return ContentFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    contentId: contentId,
    contentType: jsonString(map['contentType']) ?? 'UNKNOWN',
    title: title,
    summary: jsonString(map['summary']),
    coverUrl: jsonString(map['coverUrl']),
    author: _author(map['author']),
    hotComment: _hotComment(map['hotComment']),
    publishTime: jsonIsoDateTime(map['publishTime']),
    likeCount: jsonInt(map['likeCount']) ?? 0,
    commentCount: jsonInt(map['commentCount']) ?? 0,
  );
}

MatchFeedCard? _match(
  Map<Object?, Object?> map,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  final matchId = jsonInt(map['matchId']);
  final home = _team(map['homeTeam']);
  final away = _team(map['awayTeam']);
  if (matchId == null || home == null || away == null) return null;
  return MatchFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    matchId: matchId,
    leagueName: jsonString(map['leagueName']) ?? '赛事',
    homeTeam: home,
    awayTeam: away,
    homeScore: jsonInt(map['homeScore']),
    awayScore: jsonInt(map['awayScore']),
    matchStatus: jsonString(map['matchStatus']) ?? 'UNKNOWN',
    matchTime: jsonIsoDateTime(map['matchTime']),
    eventSummary: jsonString(map['eventSummary']),
  );
}

HotCommentFeedCard? _hotCommentCard(
  Map<Object?, Object?>? payload,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  if (payload == null) return null;
  final commentId = jsonInt(payload['commentId']);
  final contentId = jsonInt(payload['contentId']);
  final commentText = jsonString(payload['commentText']);
  if (commentId == null || contentId == null || commentText == null) {
    return null;
  }
  return HotCommentFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    payload: payload,
    commentId: commentId,
    contentId: contentId,
    commentText: commentText,
    commentAuthor: _author(payload['commentAuthor']),
    likeCount: jsonInt(payload['likeCount']) ?? 0,
    replyCount: jsonInt(payload['replyCount']) ?? 0,
    hotScore: jsonDouble(payload['hotScore']),
    contentTitle: jsonString(payload['contentTitle']),
    contentType: jsonString(payload['contentType']),
  );
}

DiscussionFeedCard? _discussion(
  Map<Object?, Object?>? payload,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  if (payload == null) return null;
  final contentId = jsonInt(payload['contentId']);
  final title = jsonString(payload['title']);
  if (contentId == null || title == null) return null;
  return DiscussionFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    payload: payload,
    contentId: contentId,
    title: title,
    summary: jsonString(payload['summary']),
    author: _author(payload['author']),
    publishTime: jsonIsoDateTime(payload['publishTime']),
    commentCount: jsonInt(payload['commentCount']) ?? 0,
    likeCount: jsonInt(payload['likeCount']) ?? 0,
    favoriteCount: jsonInt(payload['favoriteCount']) ?? 0,
    hotComment: _hotComment(payload['hotComment']),
    relationTags: jsonList(payload['relationTags'], _relationTag),
  );
}

RankingFeedCard? _ranking(
  Map<Object?, Object?>? payload,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  if (payload == null) return null;
  final rankingType = jsonString(payload['rankingType']);
  final rankType = jsonString(payload['rankType']);
  final title = jsonString(payload['title']);
  if (rankingType == null || rankType == null || title == null) return null;
  return RankingFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    payload: payload,
    rankingType: rankingType,
    rankType: rankType,
    leagueId: jsonInt(payload['leagueId']),
    leagueName: jsonString(payload['leagueName']),
    seasonId: jsonInt(payload['seasonId']),
    seasonName: jsonString(payload['seasonName']),
    title: title,
    items: jsonList(payload['items'], _rankingItem),
  );
}

PlayerRatingFeedCard? _playerRating(
  Map<Object?, Object?>? payload,
  String cardId,
  String rawType,
  String? cardKey,
  RecommendationAttribution attribution,
) {
  if (payload == null) return null;
  final matchId = jsonInt(payload['matchId']);
  final home = _team(payload['homeTeam']);
  final away = _team(payload['awayTeam']);
  if (matchId == null || home == null || away == null) return null;
  return PlayerRatingFeedCard(
    cardId: cardId,
    cardKey: cardKey,
    rawCardType: rawType,
    attribution: attribution,
    payload: payload,
    matchId: matchId,
    leagueId: jsonInt(payload['leagueId']),
    leagueName: jsonString(payload['leagueName']),
    matchTime: jsonIsoDateTime(payload['matchTime']),
    homeTeam: home,
    awayTeam: away,
    homeScore: jsonInt(payload['homeScore']),
    awayScore: jsonInt(payload['awayScore']),
    topPlayers: jsonList(payload['topPlayers'], _ratingPlayer),
    ratingUserCount: jsonInt(payload['ratingUserCount']) ?? 0,
  );
}

RecommendationAttribution _attribution(Map<Object?, Object?> map) =>
    RecommendationAttribution(
      algorithmVersion: jsonString(map['algorithmVersion']),
      impressionId: jsonString(map['impressionId']),
      position: jsonInt(map['position']),
      reasonCode: jsonString(map['reasonCode']),
      reason: jsonString(map['reason']),
    );

FeedAuthor? _author(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final nickname = jsonString(map['nickname']);
  if (nickname == null) return null;
  return FeedAuthor(
    userId: jsonInt(map['userId']),
    nickname: nickname,
    avatarUrl: jsonString(map['avatarUrl']),
    verified: map['verified'] == true,
  );
}

FeedHotComment? _hotComment(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final content = jsonString(map['content']);
  if (content == null) return null;
  return FeedHotComment(
    content: content,
    nickname: jsonString(map['nickname']),
  );
}

FeedTeam? _team(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final name = jsonString(map['teamName']);
  if (name == null) return null;
  return FeedTeam(
    teamId: jsonInt(map['teamId']),
    teamName: name,
    logoUrl: jsonString(map['logoUrl']),
  );
}

FeedRelationTag? _relationTag(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final type = jsonString(map['relationType']);
  final id = jsonInt(map['relationId']);
  final name = jsonString(map['relationName']);
  if (type == null || id == null) return null;
  return FeedRelationTag(type: type, id: id, name: name);
}

FeedRankingItem? _rankingItem(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final rank = jsonInt(map['rank']);
  final name = jsonString(map['name']);
  final value = jsonString(map['value']);
  if (rank == null || name == null || value == null) return null;
  return FeedRankingItem(
    rank: rank,
    entityId: jsonInt(map['entityId']),
    name: name,
    imageUrl: jsonString(map['imageUrl']),
    teamId: jsonInt(map['teamId']),
    teamName: jsonString(map['teamName']),
    value: value,
  );
}

FeedRatingPlayer? _ratingPlayer(Object? raw) {
  final map = jsonMap(raw);
  if (map == null) return null;
  final playerId = jsonInt(map['playerId']);
  final playerName = jsonString(map['playerName']);
  if (playerId == null || playerName == null) return null;
  return FeedRatingPlayer(
    playerId: playerId,
    playerName: playerName,
    avatarUrl: jsonString(map['avatarUrl']),
    teamId: jsonInt(map['teamId']),
    officialRating: jsonDouble(map['officialRating']),
    userRatingAverage: jsonDouble(map['userRatingAverage']),
    userRatingCount: jsonInt(map['userRatingCount']) ?? 0,
  );
}
