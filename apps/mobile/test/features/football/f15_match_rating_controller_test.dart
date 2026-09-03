import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/data/match_detail_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_detail_models.dart';
import 'package:tifo/features/football/presentation/controllers/match_detail_controllers.dart';

void main() {
  test(
    'rating submit overwrite cancel and failure restore real state',
    () async {
      final repository = _Repository();
      final controller = MatchRatingsController(repository, matchId: 70);
      await controller.load();
      expect(controller.state.records.single.currentUserRating, isNull);

      expect(await controller.submit(50, 8.5), isTrue);
      expect(controller.state.records.single.currentUserRating, 8.5);
      expect(await controller.submit(50, 9), isTrue);
      expect(controller.state.records.single.currentUserRating, 9);

      repository.fail = true;
      expect(await controller.submit(50, 6), isFalse);
      expect(controller.state.records.single.currentUserRating, 9);
      expect(controller.state.message, isNotNull);

      repository.fail = false;
      expect(await controller.cancel(50), isTrue);
      expect(controller.state.records.single.currentUserRating, isNull);
      expect(controller.state.records.single.averageRating, isNull);
    },
  );
}

final class _Repository implements MatchDetailRepositoryContract {
  bool fail = false;
  double? mine;
  @override
  Future<List<MatchRatingSummary>> ratings(int matchId) async => const [
    MatchRatingSummary(playerId: 50, playerName: '测试球员', teamId: 40),
  ];
  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) async {
    if (fail) throw const NetworkException('down');
    mine = rating;
    return MatchRatingResult(
      matchId: matchId,
      playerId: playerId,
      myRating: rating,
      averageRating: rating,
      ratingCount: 1,
    );
  }

  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) async {
    mine = null;
    return MatchRatingResult(matchId: matchId, playerId: playerId);
  }

  @override
  Future<MatchOverviewV1> overview(int matchId) => throw UnimplementedError();
  @override
  Future<MatchLineups> lineups(int matchId) => throw UnimplementedError();
  @override
  Future<List<MatchTeamStatItem>> stats(int matchId) =>
      throw UnimplementedError();
  @override
  Future<FootballPage<MatchPlayerStat>> playerStats(
    int matchId,
    int page,
    int size,
  ) => throw UnimplementedError();
}
