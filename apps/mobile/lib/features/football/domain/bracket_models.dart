import 'football_models.dart';

final class BracketLeg {
  const BracketLeg({
    required this.matchId,
    this.homeScore,
    this.awayScore,
    this.matchTime,
    this.matchStatus,
  });

  final int matchId;
  final int? homeScore;
  final int? awayScore;
  final DateTime? matchTime;
  final String? matchStatus;
}

final class BracketTie {
  const BracketTie({
    required this.tieKey,
    required this.homeTeam,
    required this.awayTeam,
    required this.legs,
    this.homeAggregate,
    this.awayAggregate,
    this.winnerTeamId,
    this.parentTieKey,
  });

  final String tieKey;
  final FootballTeam homeTeam;
  final FootballTeam awayTeam;
  final int? homeAggregate;
  final int? awayAggregate;
  final int? winnerTeamId;
  final String? parentTieKey;
  final List<BracketLeg> legs;
}

final class BracketStage {
  const BracketStage({
    required this.stageId,
    required this.stageName,
    required this.sortOrder,
    required this.ties,
    this.stageType,
  });

  final int stageId;
  final String stageName;
  final String? stageType;
  final int sortOrder;
  final List<BracketTie> ties;

  bool get isKnockout {
    final type = stageType;
    if (type == null) return true;
    return type != 'LEAGUE_STAGE' && type != 'REGULAR_SEASON';
  }
}
