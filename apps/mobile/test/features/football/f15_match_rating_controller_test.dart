import 'dart:async';

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

      expect(await controller.submit(50, 11), isFalse);
      expect(controller.state.records.single.currentUserRating, isNull);

      expect(await controller.submit(50, 8.5), isTrue);
      expect(controller.state.records.single.currentUserRating, 8.5);
      expect(await controller.submit(50, 9), isTrue);
      expect(controller.state.records.single.currentUserRating, 9);

      repository.businessFail = true;
      expect(await controller.submit(50, 6), isFalse);
      expect(controller.state.records.single.currentUserRating, 9);
      expect(controller.state.message, isNotNull);

      repository.fail = false;
      expect(await controller.cancel(50), isTrue);
      expect(controller.state.records.single.currentUserRating, isNull);
      expect(controller.state.records.single.averageRating, isNull);
    },
  );

  test(
    'MATCH-17 MATCH-18 rating busy and invalid ids never duplicate writes',
    () async {
      final repository = _Repository();
      final controller = MatchRatingsController(repository, matchId: 70);
      await controller.load();
      final pending = Completer<MatchRatingResult>();
      repository.pending = pending;

      final first = controller.submit(50, 8.5);
      expect(controller.isBusy(50), isTrue);
      expect(await controller.submit(50, 9), isFalse);
      expect(repository.submitCalls, 1);
      pending.complete(
        const MatchRatingResult(
          matchId: 70,
          playerId: 50,
          myRating: 8.5,
          averageRating: 8.5,
          ratingCount: 2,
        ),
      );
      expect(await first, isTrue);
      expect(controller.isBusy(50), isFalse);
      expect(controller.state.records.single.currentUserRating, 8.5);

      final invalid = MatchRatingsController(_Repository(), matchId: 0);
      expect(await invalid.submit(50, 8), isFalse);
      expect(await invalid.cancel(50), isFalse);
    },
  );

  test(
    'MATCH-17 concurrent ratings merge inverse completions without losing busy state',
    () async {
      final repository = _ConcurrentRepository();
      final first = Completer<MatchRatingResult>();
      final second = Completer<MatchRatingResult>();
      repository.pending[50] = first;
      repository.pending[51] = second;
      final controller = MatchRatingsController(repository, matchId: 70);
      await controller.load();

      final firstWrite = controller.submit(50, 8);
      final secondWrite = controller.submit(51, 9);
      expect(controller.state.busyPlayerIds, {50, 51});
      second.complete(_ratingResult(51, 9));
      expect(await secondWrite, isTrue);
      expect(controller.state.busyPlayerIds, {50});
      expect(controller.state.records[1].currentUserRating, 9);
      expect(controller.state.records[0].currentUserRating, isNull);
      first.complete(_ratingResult(50, 8));
      expect(await firstWrite, isTrue);
      expect(controller.state.busyPlayerIds, isEmpty);
      expect(controller.state.records[0].currentUserRating, 8);
      expect(controller.state.records[1].currentUserRating, 9);
      expect(repository.submitCalls, 2);
    },
  );

  test(
    'MATCH-18 concurrent rating success and network failure preserve the other result',
    () async {
      final repository = _ConcurrentRepository();
      final failed = Completer<MatchRatingResult>();
      final succeeded = Completer<MatchRatingResult>();
      repository.pending[50] = failed;
      repository.pending[51] = succeeded;
      final controller = MatchRatingsController(repository, matchId: 70);
      await controller.load();
      final failedWrite = controller.submit(50, 8);
      final successWrite = controller.submit(51, 9);
      succeeded.complete(_ratingResult(51, 9));
      expect(await successWrite, isTrue);
      failed.completeError(const NetworkException('network down'));
      expect(await failedWrite, isFalse);
      expect(controller.state.records[0].currentUserRating, isNull);
      expect(controller.state.records[1].currentUserRating, 9);
      expect(controller.state.busyPlayerIds, isEmpty);
      expect(controller.state.message, contains('network down'));
    },
  );

  test(
    'MATCH-18 concurrent rating success and business failure preserve busy context',
    () async {
      final repository = _ConcurrentRepository();
      final failed = Completer<MatchRatingResult>();
      final succeeded = Completer<MatchRatingResult>();
      repository.pending[50] = failed;
      repository.pending[51] = succeeded;
      final controller = MatchRatingsController(repository, matchId: 70);
      await controller.load();
      final failedWrite = controller.submit(50, 8);
      final successWrite = controller.submit(51, 9);
      expect(controller.state.busyPlayerIds, {50, 51});
      failed.completeError(
        const BusinessException('not allowed', code: 403, traceId: null),
      );
      expect(await failedWrite, isFalse);
      expect(controller.state.busyPlayerIds, {51});
      expect(controller.state.message, 'not allowed');
      controller.clearMessage();
      expect(controller.state.busyPlayerIds, {51});
      succeeded.complete(_ratingResult(51, 9));
      expect(await successWrite, isTrue);
      expect(controller.state.busyPlayerIds, isEmpty);
      expect(controller.state.records[1].currentUserRating, 9);
    },
  );
}

MatchRatingResult _ratingResult(int playerId, double value) =>
    MatchRatingResult(
      matchId: 70,
      playerId: playerId,
      myRating: value,
      averageRating: value,
      ratingCount: 2,
    );

final class _Repository implements MatchDetailRepositoryContract {
  bool fail = false;
  bool businessFail = false;
  Completer<MatchRatingResult>? pending;
  int submitCalls = 0;
  double? mine;
  @override
  Future<FootballPage<MatchRelatedContent>> contents(
    int matchId, {
    int page = 1,
    int size = 10,
    String? contentType,
  }) async => const FootballPage(records: [], pageNum: 1, pages: 0, total: 0);
  @override
  Future<List<MatchRatingSummary>> ratings(int matchId, {int? teamId}) async =>
      const [MatchRatingSummary(playerId: 50, playerName: '测试球员', teamId: 40)];
  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) async {
    submitCalls++;
    if (pending != null) return pending!.future;
    if (businessFail) {
      throw const BusinessException('forbidden', code: 403, traceId: null);
    }
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
    int size, {
    int? teamId,
    String? position,
  }) => throw UnimplementedError();
}

final class _ConcurrentRepository implements MatchDetailRepositoryContract {
  final pending = <int, Completer<MatchRatingResult>>{};
  int submitCalls = 0;

  @override
  Future<FootballPage<MatchRelatedContent>> contents(
    int matchId, {
    int page = 1,
    int size = 10,
    String? contentType,
  }) async => const FootballPage(records: [], pageNum: 1, pages: 0, total: 0);

  @override
  Future<List<MatchRatingSummary>> ratings(int matchId, {int? teamId}) async =>
      const [
        MatchRatingSummary(playerId: 50, playerName: '甲', teamId: 40),
        MatchRatingSummary(playerId: 51, playerName: '乙', teamId: 41),
      ];

  @override
  Future<MatchRatingResult> submitRating(
    int matchId,
    int playerId,
    double rating,
  ) {
    submitCalls++;
    return pending[playerId]!.future;
  }

  @override
  Future<MatchRatingResult> cancelRating(int matchId, int playerId) =>
      Future.value(_ratingResult(playerId, 0));

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
    int size, {
    int? teamId,
    String? position,
  }) => throw UnimplementedError();
}
