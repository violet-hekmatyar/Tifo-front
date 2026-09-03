import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/match_detail_repository.dart';
import '../../domain/match_detail_models.dart';
import 'team_detail_controllers.dart';

final matchOverviewV1Provider = FutureProvider.autoDispose
    .family<MatchOverviewV1, int>(
      (ref, id) => ref.watch(matchDetailRepositoryProvider).overview(id),
    );
final matchLineupsProvider = FutureProvider.autoDispose
    .family<MatchLineups, int>(
      (ref, id) => ref.watch(matchDetailRepositoryProvider).lineups(id),
    );
final matchTeamStatsProvider = FutureProvider.autoDispose
    .family<List<MatchTeamStatItem>, int>(
      (ref, id) => ref.watch(matchDetailRepositoryProvider).stats(id),
    );
final matchPlayerStatsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<MatchPlayerStat>, int>((ref, id) {
      final repository = ref.watch(matchDetailRepositoryProvider);
      return TeamPagedController(
        target: '球员统计',
        loader: (page, size) => repository.playerStats(id, page, size),
        itemId: (item) => item.playerId,
      );
    });

enum MatchRatingsStatus { loading, ready, empty, failure }

final class MatchRatingsState {
  const MatchRatingsState({
    required this.status,
    this.records = const [],
    this.busyPlayerId,
    this.message,
  });
  final MatchRatingsStatus status;
  final List<MatchRatingSummary> records;
  final int? busyPlayerId;
  final String? message;
}

final matchRatingsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchRatingsController, int>(
      (ref, id) => MatchRatingsController(
        ref.watch(matchDetailRepositoryProvider),
        matchId: id,
      ),
    );

final class MatchRatingsController extends ChangeNotifier {
  MatchRatingsController(this._repository, {required this.matchId});
  final MatchDetailRepositoryContract _repository;
  final int matchId;
  MatchRatingsState _state = const MatchRatingsState(
    status: MatchRatingsStatus.loading,
  );
  MatchRatingsState get state => _state;

  Future<void> load() async {
    _set(const MatchRatingsState(status: MatchRatingsStatus.loading));
    try {
      final values = await _repository.ratings(matchId);
      _set(
        MatchRatingsState(
          status: values.isEmpty
              ? MatchRatingsStatus.empty
              : MatchRatingsStatus.ready,
          records: values,
        ),
      );
    } on AppNetworkException catch (error) {
      _set(
        MatchRatingsState(
          status: MatchRatingsStatus.failure,
          message: error.message,
        ),
      );
    }
  }

  Future<bool> submit(int playerId, double rating) => _write(
    playerId,
    () => _repository.submitRating(matchId, playerId, rating),
  );

  Future<bool> cancel(int playerId) =>
      _write(playerId, () => _repository.cancelRating(matchId, playerId));

  Future<bool> _write(
    int playerId,
    Future<MatchRatingResult> Function() action,
  ) async {
    if (_state.busyPlayerId != null) return false;
    final before = _state;
    _set(
      MatchRatingsState(
        status: before.status,
        records: before.records,
        busyPlayerId: playerId,
      ),
    );
    try {
      final result = await action();
      final records = [
        for (final item in before.records)
          if (item.playerId == playerId)
            item.copyWith(
              myRating: result.myRating,
              average: result.averageRating,
              count: result.ratingCount,
              clearMine: result.myRating == null,
              clearAverage: result.averageRating == null,
            )
          else
            item,
      ];
      _set(
        MatchRatingsState(status: MatchRatingsStatus.ready, records: records),
      );
      return true;
    } on AppNetworkException catch (error) {
      _set(
        MatchRatingsState(
          status: before.status,
          records: before.records,
          message: error.message,
        ),
      );
      return false;
    }
  }

  void clearMessage() {
    if (_state.message == null) return;
    _set(MatchRatingsState(status: _state.status, records: _state.records));
  }

  void _set(MatchRatingsState value) {
    _state = value;
    notifyListeners();
  }
}
