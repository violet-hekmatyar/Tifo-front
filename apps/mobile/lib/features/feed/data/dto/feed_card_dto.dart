import '../../domain/feed_card.dart';

final class FeedCardDto {
  const FeedCardDto(this.card);

  factory FeedCardDto.fromRaw(Object? raw) {
    if (raw is! Map) {
      return const FeedCardDto(
        UnknownFeedCard(cardId: 'UNKNOWN_MALFORMED', rawCardType: 'MALFORMED'),
      );
    }
    final type = _string(raw['cardType']) ?? 'UNKNOWN';
    final cardId =
        _string(raw['cardId']) ??
        '${type}_${_integer(raw['contentId']) ?? _integer(raw['matchId']) ?? 'UNKNOWN'}';
    try {
      if (type == 'CONTENT' || type == 'CONTENT_CARD') {
        final contentId = _integer(raw['contentId']);
        final title = _string(raw['title']);
        if (contentId == null || title == null) {
          return FeedCardDto(
            UnknownFeedCard(cardId: cardId, rawCardType: type),
          );
        }
        final authorRaw = raw['author'];
        final hotCommentRaw = raw['hotComment'];
        return FeedCardDto(
          ContentFeedCard(
            cardId: cardId,
            rawCardType: type,
            contentId: contentId,
            contentType: _string(raw['contentType']) ?? 'UNKNOWN',
            title: title,
            summary: _string(raw['summary']),
            coverUrl: _string(raw['coverUrl']),
            author: authorRaw is Map
                ? FeedAuthor(
                    userId: _integer(authorRaw['userId']),
                    nickname: _string(authorRaw['nickname']) ?? '南看台用户',
                    avatarUrl: _string(authorRaw['avatarUrl']),
                    verified: authorRaw['verified'] == true,
                  )
                : null,
            hotComment:
                hotCommentRaw is Map &&
                    _string(hotCommentRaw['content']) != null
                ? FeedHotComment(
                    content: _string(hotCommentRaw['content'])!,
                    nickname: _string(hotCommentRaw['nickname']),
                  )
                : null,
            publishTime: _date(raw['publishTime']),
            likeCount: _integer(raw['likeCount']) ?? 0,
            commentCount: _integer(raw['commentCount']) ?? 0,
          ),
        );
      }
      if (type == 'MATCH' || type == 'MATCH_CARD') {
        final matchId = _integer(raw['matchId']);
        final home = _team(raw['homeTeam']);
        final away = _team(raw['awayTeam']);
        if (matchId == null || home == null || away == null) {
          return FeedCardDto(
            UnknownFeedCard(cardId: cardId, rawCardType: type),
          );
        }
        return FeedCardDto(
          MatchFeedCard(
            cardId: cardId,
            rawCardType: type,
            matchId: matchId,
            leagueName: _string(raw['leagueName']) ?? '赛事',
            homeTeam: home,
            awayTeam: away,
            homeScore: _integer(raw['homeScore']),
            awayScore: _integer(raw['awayScore']),
            matchStatus: _string(raw['matchStatus']) ?? 'UNKNOWN',
            matchTime: _date(raw['matchTime']),
            eventSummary: _string(raw['eventSummary']),
          ),
        );
      }
    } catch (_) {
      return FeedCardDto(UnknownFeedCard(cardId: cardId, rawCardType: type));
    }
    return FeedCardDto(UnknownFeedCard(cardId: cardId, rawCardType: type));
  }

  final FeedCard card;

  FeedCard toDomain() => card;

  static FeedTeam? _team(Object? raw) {
    if (raw is! Map) return null;
    final name = _string(raw['teamName']);
    if (name == null) return null;
    return FeedTeam(
      teamId: _integer(raw['teamId']),
      teamName: name,
      logoUrl: _string(raw['logoUrl']),
    );
  }
}

String? _string(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

int? _integer(Object? value) => value is num ? value.toInt() : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
