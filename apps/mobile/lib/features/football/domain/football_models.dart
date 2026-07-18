final class FootballPage<T> {
  const FootballPage({
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

final class League {
  const League({
    required this.id,
    required this.name,
    this.logoUrl,
    this.country,
    this.season,
  });
  final int id;
  final String name;
  final String? logoUrl;
  final String? country;
  final String? season;
}

final class FootballTeam {
  const FootballTeam({
    required this.id,
    required this.name,
    this.logoUrl,
    this.score,
  });
  final int id;
  final String name;
  final String? logoUrl;
  final int? score;
}

final class FootballMatch {
  const FootballMatch({
    required this.id,
    required this.leagueId,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.matchTime,
    this.eventSummary,
    this.hasReport = false,
    this.reportContentId,
  });
  final int id;
  final int leagueId;
  final String leagueName;
  final FootballTeam homeTeam;
  final FootballTeam awayTeam;
  final String status;
  final DateTime? matchTime;
  final String? eventSummary;
  final bool hasReport;
  final int? reportContentId;
}

final class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.type,
    required this.minute,
    this.extraMinute,
    this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.assistPlayerId,
    this.assistPlayerName,
    this.scoreAfter,
    this.description,
    this.hasDebate = false,
  });
  final int id;
  final String type;
  final int minute;
  final int? extraMinute;
  final int? teamId;
  final String? teamName;
  final int? playerId;
  final String? playerName;
  final int? assistPlayerId;
  final String? assistPlayerName;
  final String? scoreAfter;
  final String? description;
  final bool hasDebate;
}

final class MatchReport {
  const MatchReport({required this.contentId, required this.title, this.type});
  final int contentId;
  final String title;
  final String? type;
}

final class MatchDetail {
  const MatchDetail({
    required this.match,
    required this.events,
    this.season,
    this.roundName,
    this.venue,
    this.report,
  });
  final FootballMatch match;
  final String? season;
  final String? roundName;
  final String? venue;
  final List<MatchEvent> events;
  final MatchReport? report;
}

final class TeamDetail {
  const TeamDetail({
    required this.id,
    required this.name,
    required this.followed,
    required this.followerCount,
    required this.recentMatches,
    required this.upcomingMatches,
    this.nameEn,
    this.shortName,
    this.logoUrl,
    this.country,
    this.city,
    this.stadiumName,
    this.foundedYear,
    this.coachName,
    this.marketValue,
  });
  final int id;
  final String name;
  final String? nameEn;
  final String? shortName;
  final String? logoUrl;
  final String? country;
  final String? city;
  final String? stadiumName;
  final int? foundedYear;
  final String? coachName;
  final String? marketValue;
  final int followerCount;
  final bool followed;
  final List<FootballMatch> recentMatches;
  final List<FootballMatch> upcomingMatches;
}

final class PlayerTeam {
  const PlayerTeam({
    required this.id,
    required this.name,
    this.logoUrl,
    this.shirtNumber,
    this.position,
  });
  final int id;
  final String name;
  final String? logoUrl;
  final int? shirtNumber;
  final String? position;
}

final class PlayerDetail {
  const PlayerDetail({
    required this.id,
    required this.name,
    required this.retired,
    required this.followed,
    required this.followerCount,
    this.nameEn,
    this.avatarUrl,
    this.position,
    this.nationality,
    this.age,
    this.shirtNumber,
    this.team,
  });
  final int id;
  final String name;
  final String? nameEn;
  final String? avatarUrl;
  final String? position;
  final String? nationality;
  final int? age;
  final int? shirtNumber;
  final bool retired;
  final int followerCount;
  final bool followed;
  final PlayerTeam? team;
}
