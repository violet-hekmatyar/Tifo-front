import 'football_models.dart';
import 'team_detail_models.dart';

typedef PlayerDetailContext = ({
  int playerId,
  int? leagueId,
  int? seasonId,
  int? stageId,
});

final class PlayerTeamLink {
  const PlayerTeamLink({
    required this.id,
    required this.name,
    this.logoUrl,
    this.rawType,
    this.shirtNumber,
  });
  final int id;
  final String name;
  final String? logoUrl;
  final String? rawType;
  final int? shirtNumber;
}

final class PlayerSeasonStats {
  const PlayerSeasonStats({
    this.leagueId,
    this.leagueName,
    this.seasonId,
    this.seasonName,
    this.teamId,
    this.teamName,
    this.appearances,
    this.starts,
    this.minutes,
    this.goals,
    this.assists,
    this.yellowCards,
    this.redCards,
    this.shots,
    this.shotsOnTarget,
    this.shotAccuracy,
    this.rating,
    this.saves,
    this.source,
    this.updatedAt,
  });
  final int? leagueId;
  final String? leagueName;
  final int? seasonId;
  final String? seasonName;
  final int? teamId;
  final String? teamName;
  final int? appearances;
  final int? starts;
  final int? minutes;
  final int? goals;
  final int? assists;
  final int? yellowCards;
  final int? redCards;
  final int? shots;
  final int? shotsOnTarget;
  final double? shotAccuracy;
  final double? rating;
  final int? saves;
  final String? source;
  final DateTime? updatedAt;
}

final class PlayerTeamHistory {
  const PlayerTeamHistory({
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.seasonId,
    this.seasonName,
    this.startDate,
    this.endDate,
    this.shirtNumber,
    this.position,
    this.appearances,
    this.goals,
    this.assists,
    this.current = false,
    this.loan = false,
  });
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final int? seasonId;
  final String? seasonName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? shirtNumber;
  final String? position;
  final int? appearances;
  final int? goals;
  final int? assists;
  final bool current;
  final bool loan;
}

final class PlayerCareerGroup {
  const PlayerCareerGroup({
    required this.id,
    required this.name,
    this.appearances,
    this.starts,
    this.minutes,
    this.goals,
    this.assists,
    this.averageRating,
  });
  final int id;
  final String name;
  final int? appearances;
  final int? starts;
  final int? minutes;
  final int? goals;
  final int? assists;
  final double? averageRating;
}

final class PlayerCareer {
  const PlayerCareer({
    this.totalAppearances,
    this.totalStarts,
    this.totalMinutes,
    this.totalGoals,
    this.totalAssists,
    this.totalYellowCards,
    this.totalRedCards,
    this.totalShots,
    this.totalShotsOnTarget,
    this.averageRating,
    this.totalSaves,
    this.teamCount,
    this.seasonCount,
    this.bySeason = const [],
    this.byTeam = const [],
  });
  final int? totalAppearances;
  final int? totalStarts;
  final int? totalMinutes;
  final int? totalGoals;
  final int? totalAssists;
  final int? totalYellowCards;
  final int? totalRedCards;
  final int? totalShots;
  final int? totalShotsOnTarget;
  final double? averageRating;
  final int? totalSaves;
  final int? teamCount;
  final int? seasonCount;
  final List<PlayerCareerGroup> bySeason;
  final List<PlayerCareerGroup> byTeam;

  bool get hasData =>
      totalAppearances != null ||
      totalGoals != null ||
      bySeason.isNotEmpty ||
      byTeam.isNotEmpty;
}

final class PlayerOverview {
  const PlayerOverview({
    required this.id,
    required this.name,
    required this.retired,
    this.nameEn,
    this.avatarUrl,
    this.position,
    this.nationality,
    this.birthDate,
    this.age,
    this.height,
    this.weight,
    this.preferredFoot,
    this.shirtNumber,
    this.captain = false,
    this.followed = false,
    this.rawStatus,
    this.club,
    this.nationalTeam,
    this.seasonStats = const [],
    this.recentMatches = const [],
    this.recentContents = const [],
  });
  final int id;
  final String name;
  final String? nameEn;
  final String? avatarUrl;
  final String? position;
  final String? nationality;
  final DateTime? birthDate;
  final int? age;
  final int? height;
  final int? weight;
  final String? preferredFoot;
  final int? shirtNumber;
  final bool captain;
  final bool followed;
  final bool retired;
  final String? rawStatus;
  final PlayerTeamLink? club;
  final PlayerTeamLink? nationalTeam;
  final List<PlayerSeasonStats> seasonStats;
  final List<FootballMatch> recentMatches;
  final List<TeamContentSummary> recentContents;
}
