enum FootballRankingView { standings, players, teams }

enum PlayerRankType {
  goals('GOALS', '进球'),
  assists('ASSISTS', '助攻'),
  yellowCards('YELLOW_CARDS', '黄牌'),
  redCards('RED_CARDS', '红牌'),
  shots('SHOTS', '射门'),
  shotsOnTarget('SHOTS_ON_TARGET', '射正'),
  rating('RATING', '评分'),
  saves('SAVES', '扑救'),
  appearances('APPEARANCES', '出场'),
  minutes('MINUTES', '分钟');

  const PlayerRankType(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

enum TeamRankType {
  goalsFor('GOALS_FOR', '进球'),
  goalsAgainst('GOALS_AGAINST', '失球'),
  assists('ASSISTS', '助攻'),
  yellowCards('YELLOW_CARDS', '黄牌'),
  redCards('RED_CARDS', '红牌'),
  shots('SHOTS', '射门'),
  shotsOnTarget('SHOTS_ON_TARGET', '射正'),
  corners('CORNERS', '角球'),
  fouls('FOULS', '犯规'),
  cleanSheets('CLEAN_SHEETS', '零封'),
  averageRating('AVG_RATING', '平均评分');

  const TeamRankType(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

final class FootballSeason {
  const FootballSeason({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.current,
    this.code,
    this.startDate,
    this.endDate,
    this.status,
  });

  final int id;
  final int leagueId;
  final String name;
  final String? code;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool current;
  final String? status;
}

final class FootballStage {
  const FootballStage({
    required this.id,
    required this.name,
    this.rawType,
    this.groupCode,
    this.sortOrder,
  });

  final int id;
  final String name;
  final String? rawType;
  final String? groupCode;
  final int? sortOrder;
}

final class StandingTable {
  const StandingTable({
    required this.leagueId,
    required this.seasonId,
    required this.records,
    this.leagueName,
    this.seasonName,
    this.stageId,
    this.stageName,
    this.groupCode,
    this.source,
    this.updatedAt,
  });

  final int? leagueId;
  final String? leagueName;
  final int? seasonId;
  final String? seasonName;
  final int? stageId;
  final String? stageName;
  final String? groupCode;
  final String? source;
  final DateTime? updatedAt;
  final List<StandingRecord> records;
}

final class StandingRecord {
  const StandingRecord({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.deductionPoints,
    this.teamLogoUrl,
    this.form,
  });

  final int rank;
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int deductionPoints;
  final String? form;
}

final class PlayerRankRecord {
  const PlayerRankRecord({
    required this.rank,
    required this.playerId,
    required this.playerName,
    this.playerAvatarUrl,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.value,
    this.displayValue,
    this.appearances,
    this.starts,
    this.minutes,
    this.updatedAt,
  });

  final int rank;
  final int playerId;
  final String playerName;
  final String? playerAvatarUrl;
  final int? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final double? value;
  final String? displayValue;
  final int? appearances;
  final int? starts;
  final int? minutes;
  final DateTime? updatedAt;
}

final class TeamRankRecord {
  const TeamRankRecord({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.value,
    this.displayValue,
    this.played,
    this.sortDirection,
    this.updatedAt,
  });

  final int rank;
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final double? value;
  final String? displayValue;
  final int? played;
  final String? sortDirection;
  final DateTime? updatedAt;
}
