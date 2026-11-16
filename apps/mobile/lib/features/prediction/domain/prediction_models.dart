import '../../../core/network/json_value.dart';

final class PredictionTeam {
  const PredictionTeam({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String shortName;
  final String? logoUrl;

  factory PredictionTeam.fromJson(Map<Object?, Object?> json) => PredictionTeam(
    id: jsonInt(json['id']) ?? 0,
    name: jsonString(json['name']) ?? '主队',
    shortName: jsonString(json['shortName']) ?? jsonString(json['name']) ?? '主队',
    logoUrl: jsonString(json['logoUrl']),
  );
}

final class PredictionConsensus {
  const PredictionConsensus({
    required this.homePercent,
    required this.drawPercent,
    required this.awayPercent,
    required this.participantCount,
  });

  final int homePercent;
  final int drawPercent;
  final int awayPercent;
  final int participantCount;
}

final class PredictionMine {
  const PredictionMine({
    required this.id,
    required this.homeProbability,
    required this.drawProbability,
    required this.awayProbability,
    required this.predictedOutcome,
    required this.predictedOutcomeLabel,
    required this.insightScore,
    required this.stake,
    required this.challengeResult,
    required this.rewardBeans,
    this.submittedAt,
    this.settledAt,
  });

  final int id;
  final int homeProbability;
  final int drawProbability;
  final int awayProbability;
  final String predictedOutcome;
  final String predictedOutcomeLabel;
  final int? insightScore;
  final int stake;
  final String challengeResult;
  final int rewardBeans;
  final DateTime? submittedAt;
  final DateTime? settledAt;
}

final class PredictionChallenge {
  const PredictionChallenge({
    required this.enabled,
    required this.stakes,
    required this.minStake,
    required this.maxStake,
    required this.ruleText,
    this.balance,
  });

  final bool enabled;
  final int? balance;
  final List<int> stakes;
  final int minStake;
  final int maxStake;
  final String ruleText;
}

final class PredictionPostMatch {
  const PredictionPostMatch({
    required this.score,
    required this.calibrationLabel,
    required this.hit,
    required this.rewardBeans,
    required this.balance,
    required this.headline,
    required this.actualOutcome,
    required this.actualOutcomeLabel,
    required this.highlights,
  });

  final int score;
  final String calibrationLabel;
  final bool hit;
  final int rewardBeans;
  final int balance;
  final String headline;
  final String actualOutcome;
  final String actualOutcomeLabel;
  final List<String> highlights;
}

final class PredictionTrajectoryPoint {
  const PredictionTrajectoryPoint({
    required this.stageLabel,
    required this.homePercent,
    required this.drawPercent,
    required this.awayPercent,
    required this.outcomeLabel,
  });

  final String stageLabel;
  final int homePercent;
  final int drawPercent;
  final int awayPercent;
  final String outcomeLabel;
}

final class PredictionMarket {
  const PredictionMarket({
    required this.label,
    required this.participantCount,
    required this.percent,
  });

  final String label;
  final int participantCount;
  final int percent;
}

final class MatchPrediction {
  const MatchPrediction({
    required this.matchId,
    required this.matchStatus,
    required this.window,
    required this.canSubmit,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.consensus,
    required this.challenge,
    required this.trajectory,
    required this.morePredictions,
    required this.disclaimer,
    this.lockReason,
    this.matchTime,
    this.homeScore,
    this.awayScore,
    this.myPrediction,
    this.postMatch,
  });

  final int matchId;
  final String matchStatus;
  final String window;
  final bool canSubmit;
  final String? lockReason;
  final String leagueName;
  final DateTime? matchTime;
  final int? homeScore;
  final int? awayScore;
  final PredictionTeam homeTeam;
  final PredictionTeam awayTeam;
  final PredictionConsensus consensus;
  final PredictionMine? myPrediction;
  final PredictionChallenge challenge;
  final PredictionPostMatch? postMatch;
  final List<PredictionTrajectoryPoint> trajectory;
  final List<PredictionMarket> morePredictions;
  final String disclaimer;

  bool get isPostMatch => window == 'POST_MATCH' || postMatch != null;
  bool get isLocked => !canSubmit;

  String get homeLabel => '${homeTeam.shortName}胜';
  String get drawLabel => '平局';
  String get awayLabel => '${awayTeam.shortName}胜';
}
