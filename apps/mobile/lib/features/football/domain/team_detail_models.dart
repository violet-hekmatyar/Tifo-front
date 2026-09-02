import 'football_models.dart';

typedef TeamDetailContext = ({int teamId, int? seasonId, int? stageId});

final class TeamRosterPlayer {
  const TeamRosterPlayer({
    required this.id,
    required this.name,
    this.nameEn,
    this.avatarUrl,
    this.position,
    this.shirtNumber,
    this.captain = false,
    this.loan = false,
    this.loanFromTeamName,
    this.squadRole,
    this.appearances,
    this.starts,
    this.minutes,
    this.goals,
    this.assists,
    this.rating,
    this.followed = false,
  });
  final int id;
  final String name;
  final String? nameEn;
  final String? avatarUrl;
  final String? position;
  final int? shirtNumber;
  final bool captain;
  final bool loan;
  final String? loanFromTeamName;
  final String? squadRole;
  final int? appearances;
  final int? starts;
  final int? minutes;
  final int? goals;
  final int? assists;
  final double? rating;
  final bool followed;
}

final class TeamStats {
  const TeamStats({
    this.played,
    this.goalsFor,
    this.goalsAgainst,
    this.goalDifference,
    this.assists,
    this.shots,
    this.shotsOnTarget,
    this.shotAccuracy,
    this.corners,
    this.fouls,
    this.yellowCards,
    this.redCards,
    this.cleanSheets,
    this.averageRating,
    this.standingRank,
    this.points,
    this.source,
    this.updatedAt,
  });
  final int? played;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? goalDifference;
  final int? assists;
  final int? shots;
  final int? shotsOnTarget;
  final double? shotAccuracy;
  final int? corners;
  final int? fouls;
  final int? yellowCards;
  final int? redCards;
  final int? cleanSheets;
  final double? averageRating;
  final int? standingRank;
  final int? points;
  final String? source;
  final DateTime? updatedAt;

  bool get hasData =>
      played != null ||
      goalsFor != null ||
      goalsAgainst != null ||
      assists != null ||
      shots != null ||
      standingRank != null ||
      points != null;
}

final class TeamStandingSummary {
  const TeamStandingSummary({
    this.rank,
    this.played,
    this.won,
    this.drawn,
    this.lost,
    this.goalsFor,
    this.goalsAgainst,
    this.goalDifference,
    this.points,
  });
  final int? rank;
  final int? played;
  final int? won;
  final int? drawn;
  final int? lost;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? goalDifference;
  final int? points;
}

final class TeamHonor {
  const TeamHonor({
    required this.id,
    required this.name,
    this.rawType,
    this.titleCount,
    this.winningYears = const [],
    this.latestYear,
  });
  final int id;
  final String name;
  final String? rawType;
  final int? titleCount;
  final List<int> winningYears;
  final int? latestYear;
}

final class TeamContentSummary {
  const TeamContentSummary({
    required this.id,
    required this.title,
    required this.rawType,
    this.summary,
    this.coverUrl,
    this.publishTime,
    this.likeCount = 0,
    this.commentCount = 0,
    this.favoriteCount = 0,
  });
  final int id;
  final String title;
  final String rawType;
  final String? summary;
  final String? coverUrl;
  final DateTime? publishTime;
  final int likeCount;
  final int commentCount;
  final int favoriteCount;
}

final class TeamOverview {
  const TeamOverview({
    required this.teamId,
    required this.teamName,
    this.leagueId,
    this.leagueName,
    this.seasonId,
    this.seasonName,
    this.city,
    this.stadium,
    this.foundedYear,
    this.description,
    this.followed = false,
    this.standing,
    this.seasonStats,
    this.topScorers = const [],
    this.topAssists = const [],
    this.recentMatches = const [],
    this.nextMatch,
    this.recentContents = const [],
  });
  final int teamId;
  final String teamName;
  final int? leagueId;
  final String? leagueName;
  final int? seasonId;
  final String? seasonName;
  final String? city;
  final String? stadium;
  final int? foundedYear;
  final String? description;
  final bool followed;
  final TeamStandingSummary? standing;
  final TeamStats? seasonStats;
  final List<TeamRosterPlayer> topScorers;
  final List<TeamRosterPlayer> topAssists;
  final List<FootballMatch> recentMatches;
  final FootballMatch? nextMatch;
  final List<TeamContentSummary> recentContents;
}
