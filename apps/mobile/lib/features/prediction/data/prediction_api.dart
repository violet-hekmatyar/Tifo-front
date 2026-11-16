import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_exceptions.dart';
import '../domain/prediction_models.dart';

final class PredictionApi {
  const PredictionApi(this._client);
  final ApiClient _client;

  Future<MatchPrediction> detail(int matchId) => _client.get(
    '/api/app/football/matches/$matchId/prediction',
    decode: _prediction,
  );

  Future<MatchPrediction> submit(
    int matchId, {
    required int homeProbability,
    required int drawProbability,
    required int awayProbability,
    required int stake,
  }) => _client.post(
    '/api/app/football/matches/$matchId/prediction',
    body: {
      'homeProbability': homeProbability,
      'drawProbability': drawProbability,
      'awayProbability': awayProbability,
      'stake': stake,
    },
    decode: _prediction,
  );

  MatchPrediction _prediction(Object? raw) {
    final json = jsonMap(raw);
    if (json == null) throw const ParseException('预测数据格式不正确。');
    final matchId = jsonInt(json['matchId']);
    if (matchId == null) throw const ParseException('预测比赛编号缺失。');
    final home = jsonMap(json['homeTeam']);
    final away = jsonMap(json['awayTeam']);
    if (home == null || away == null) {
      throw const ParseException('预测球队数据缺失。');
    }
    return MatchPrediction(
      matchId: matchId,
      matchStatus: jsonString(json['matchStatus']) ?? 'SCHEDULED',
      window: jsonString(json['window']) ?? 'PRE_MATCH',
      canSubmit: json['canSubmit'] == true,
      lockReason: jsonString(json['lockReason']),
      leagueName: jsonString(json['leagueName']) ?? '比赛',
      matchTime: jsonIsoDateTime(json['matchTime']),
      homeScore: jsonInt(json['homeScore']),
      awayScore: jsonInt(json['awayScore']),
      homeTeam: PredictionTeam.fromJson(home),
      awayTeam: PredictionTeam.fromJson(away),
      consensus: _consensus(json['consensus']),
      myPrediction: _mine(json['myPrediction']),
      challenge: _challenge(json['challenge']),
      postMatch: _postMatch(json['postMatch']),
      trajectory: jsonList(json['trajectory'], _trajectory),
      morePredictions: jsonList(json['morePredictions'], _market),
      disclaimer:
          jsonString(json['disclaimer']) ?? '娱乐性质竞猜，不涉及现金。看台豆仅用于站内挑战与数字成就。',
    );
  }

  PredictionConsensus _consensus(Object? raw) {
    final json = jsonMap(raw);
    return PredictionConsensus(
      homePercent: jsonInt(json?['homePercent']) ?? 0,
      drawPercent: jsonInt(json?['drawPercent']) ?? 0,
      awayPercent: jsonInt(json?['awayPercent']) ?? 0,
      participantCount: jsonInt(json?['participantCount']) ?? 0,
    );
  }

  PredictionMine? _mine(Object? raw) {
    final json = jsonMap(raw);
    final id = jsonInt(json?['id']);
    if (json == null || id == null) return null;
    return PredictionMine(
      id: id,
      homeProbability: jsonInt(json['homeProbability']) ?? 0,
      drawProbability: jsonInt(json['drawProbability']) ?? 0,
      awayProbability: jsonInt(json['awayProbability']) ?? 0,
      predictedOutcome: jsonString(json['predictedOutcome']) ?? 'HOME',
      predictedOutcomeLabel: jsonString(json['predictedOutcomeLabel']) ?? '主胜',
      insightScore: jsonInt(json['insightScore']),
      stake: jsonInt(json['stake']) ?? 0,
      challengeResult: jsonString(json['challengeResult']) ?? 'NONE',
      rewardBeans: jsonInt(json['rewardBeans']) ?? 0,
      submittedAt: jsonIsoDateTime(json['submittedAt']),
      settledAt: jsonIsoDateTime(json['settledAt']),
    );
  }

  PredictionChallenge _challenge(Object? raw) {
    final json = jsonMap(raw);
    return PredictionChallenge(
      enabled: json?['enabled'] == true,
      balance: jsonInt(json?['balance']),
      stakes: List<int>.from(jsonList(json?['stakes'], jsonInt))..sort(),
      minStake: jsonInt(json?['minStake']) ?? 10,
      maxStake: jsonInt(json?['maxStake']) ?? 50,
      ruleText: jsonString(json?['ruleText']) ?? '每场仅可参与一次，开场锁定，不涉及现金。',
    );
  }

  PredictionPostMatch? _postMatch(Object? raw) {
    final json = jsonMap(raw);
    final score = jsonInt(json?['score']);
    if (json == null || score == null) return null;
    return PredictionPostMatch(
      score: score,
      calibrationLabel: jsonString(json['calibrationLabel']) ?? '—',
      hit: json['hit'] == true,
      rewardBeans: jsonInt(json['rewardBeans']) ?? 0,
      balance: jsonInt(json['balance']) ?? 0,
      headline: jsonString(json['headline']) ?? '本场预测已结算',
      actualOutcome: jsonString(json['actualOutcome']) ?? 'HOME',
      actualOutcomeLabel: jsonString(json['actualOutcomeLabel']) ?? '主胜',
      highlights: jsonList(json['highlights'], jsonString),
    );
  }

  PredictionTrajectoryPoint? _trajectory(Object? raw) {
    final json = jsonMap(raw);
    final stage = jsonString(json?['stageLabel']);
    if (json == null || stage == null) return null;
    return PredictionTrajectoryPoint(
      stageLabel: stage,
      homePercent: jsonInt(json['homePercent']) ?? 0,
      drawPercent: jsonInt(json['drawPercent']) ?? 0,
      awayPercent: jsonInt(json['awayPercent']) ?? 0,
      outcomeLabel: jsonString(json['outcomeLabel']) ?? '—',
    );
  }

  PredictionMarket? _market(Object? raw) {
    final json = jsonMap(raw);
    final label = jsonString(json?['label']);
    if (json == null || label == null) return null;
    return PredictionMarket(
      label: label,
      participantCount: jsonInt(json['participantCount']) ?? 0,
      percent: jsonInt(json['percent']) ?? 0,
    );
  }
}
