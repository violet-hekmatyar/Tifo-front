import 'football_models.dart';

final class MatchLineupPlayer {
  const MatchLineupPlayer({
    required this.playerId,
    required this.playerName,
    this.avatarUrl,
    this.position,
    this.shirtNumber,
    this.captain = false,
    this.started = false,
    this.appeared = false,
    this.substitutedInMinute,
    this.substitutedOutMinute,
  });
  final int playerId;
  final String playerName;
  final String? avatarUrl;
  final String? position;
  final int? shirtNumber;
  final bool captain;
  final bool started;
  final bool appeared;
  final int? substitutedInMinute;
  final int? substitutedOutMinute;
}

final class MatchTeamLineup {
  const MatchTeamLineup({
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.formation,
    this.coachName,
    this.starters = const [],
    this.substitutes = const [],
    this.bench = const [],
  });
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final String? formation;
  final String? coachName;
  final List<MatchLineupPlayer> starters;
  final List<MatchLineupPlayer> substitutes;
  final List<MatchLineupPlayer> bench;
  bool get hasPlayers =>
      starters.isNotEmpty || substitutes.isNotEmpty || bench.isNotEmpty;
}

final class MatchLineups {
  const MatchLineups({this.home, this.away});
  final MatchTeamLineup? home;
  final MatchTeamLineup? away;
  bool get hasData => home?.hasPlayers == true || away?.hasPlayers == true;
}

final class MatchTeamStatItem {
  const MatchTeamStatItem({
    required this.rawType,
    required this.displayName,
    this.homeValue,
    this.awayValue,
    this.unit,
  });
  final String rawType;
  final String displayName;
  final Object? homeValue;
  final Object? awayValue;
  final String? unit;
}

final class MatchPlayerStat {
  const MatchPlayerStat({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    this.teamName,
    this.avatarUrl,
    this.position,
    this.shirtNumber,
    this.starter = false,
    this.captain = false,
    this.minutes,
    this.goals,
    this.assists,
    this.shots,
    this.shotsOnTarget,
    this.passes,
    this.successfulPasses,
    this.passAccuracy,
    this.keyPasses,
    this.tackles,
    this.interceptions,
    this.saves,
    this.yellowCards,
    this.redCards,
    this.officialRating,
    this.userRatingAverage,
    this.userRatingCount = 0,
    this.currentUserRating,
  });
  final int playerId;
  final String playerName;
  final int teamId;
  final String? teamName;
  final String? avatarUrl;
  final String? position;
  final int? shirtNumber;
  final bool starter;
  final bool captain;
  final int? minutes;
  final int? goals;
  final int? assists;
  final int? shots;
  final int? shotsOnTarget;
  final int? passes;
  final int? successfulPasses;
  final double? passAccuracy;
  final int? keyPasses;
  final int? tackles;
  final int? interceptions;
  final int? saves;
  final int? yellowCards;
  final int? redCards;
  final double? officialRating;
  final double? userRatingAverage;
  final int userRatingCount;
  final double? currentUserRating;
}

final class MatchRatingSummary {
  const MatchRatingSummary({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    this.officialRating,
    this.averageRating,
    this.ratingCount = 0,
    this.currentUserRating,
    this.distribution = const {},
  });
  final int playerId;
  final String playerName;
  final int teamId;
  final double? officialRating;
  final double? averageRating;
  final int ratingCount;
  final double? currentUserRating;
  final Map<String, int> distribution;

  MatchRatingSummary copyWith({
    double? myRating,
    double? average,
    int? count,
    bool clearMine = false,
    bool clearAverage = false,
  }) => MatchRatingSummary(
    playerId: playerId,
    playerName: playerName,
    teamId: teamId,
    officialRating: officialRating,
    averageRating: clearAverage ? null : average ?? averageRating,
    ratingCount: count ?? ratingCount,
    currentUserRating: clearMine ? null : myRating ?? currentUserRating,
    distribution: distribution,
  );
}

final class MatchRatingResult {
  const MatchRatingResult({
    required this.matchId,
    required this.playerId,
    this.myRating,
    this.averageRating,
    this.ratingCount = 0,
    this.updatedAt,
  });
  final int matchId;
  final int playerId;
  final double? myRating;
  final double? averageRating;
  final int ratingCount;
  final DateTime? updatedAt;
}

final class MatchStandingSnapshot {
  const MatchStandingSnapshot({
    required this.teamId,
    required this.teamName,
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
  final int teamId;
  final String teamName;
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

final class MatchRanking {
  const MatchRanking({
    required this.snapshotType,
    this.leagueName,
    this.seasonName,
    this.stageName,
    this.home,
    this.away,
  });
  final String snapshotType;
  final String? leagueName;
  final String? seasonName;
  final String? stageName;
  final MatchStandingSnapshot? home;
  final MatchStandingSnapshot? away;
  bool get available =>
      snapshotType == 'CURRENT_STANDING' && (home != null || away != null);
}

final class MatchOverviewV1 {
  const MatchOverviewV1({
    required this.matchId,
    required this.lineups,
    required this.teamStats,
    required this.playerStats,
    required this.ratings,
    this.ranking,
  });
  final int matchId;
  final MatchLineups lineups;
  final List<MatchTeamStatItem> teamStats;
  final FootballPage<MatchPlayerStat> playerStats;
  final List<MatchRatingSummary> ratings;
  final MatchRanking? ranking;
}
