import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/football_repository.dart';
import '../../data/match_detail_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/match_detail_models.dart';
import 'football_data_controller.dart';
import 'team_detail_controllers.dart';

enum MatchResourceStatus { loading, ready, failure }

final class MatchResourceState<T> {
  const MatchResourceState({
    required this.status,
    this.value,
    this.message,
    this.refreshing = false,
  });
  final MatchResourceStatus status;
  final T? value;
  final String? message;
  final bool refreshing;
}

final class MatchResourceController<T> extends ChangeNotifier {
  MatchResourceController({required this.loader, required this.target});
  final Future<T> Function() loader;
  final String target;
  MatchResourceState<T> _state = const MatchResourceState(
    status: MatchResourceStatus.loading,
  );
  int _generation = 0;
  bool _loaded = false;
  MatchResourceState<T> get state => _state;

  Future<void> load() async {
    if (_loaded && _state.status != MatchResourceStatus.failure) return;
    _loaded = true;
    await _request(preserve: false);
  }

  Future<void> refresh() async {
    if (_state.refreshing) return;
    await _request(preserve: true);
  }

  Future<void> _request({required bool preserve}) async {
    final generation = ++_generation;
    final previous = _state.value;
    _set(
      MatchResourceState<T>(
        status: preserve && previous != null
            ? MatchResourceStatus.ready
            : MatchResourceStatus.loading,
        value: previous,
        refreshing: preserve && previous != null,
      ),
    );
    try {
      final value = await loader();
      if (generation != _generation) return;
      _set(
        MatchResourceState<T>(status: MatchResourceStatus.ready, value: value),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        MatchResourceState<T>(
          status: previous == null
              ? MatchResourceStatus.failure
              : MatchResourceStatus.ready,
          value: previous,
          message: footballErrorMessage(error, target: target),
        ),
      );
    }
  }

  void _set(MatchResourceState<T> value) {
    _state = value;
    notifyListeners();
  }
}

final matchOverviewV1Provider = FutureProvider.autoDispose
    .family<MatchOverviewV1, int>(
      (ref, id) => ref.watch(matchDetailRepositoryProvider).overview(id),
    );

final matchDetailControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchResourceController<MatchDetail>, int>(
      (ref, id) => MatchResourceController(
        target: '比赛详情',
        loader: () => ref.watch(footballRepositoryProvider).matchDetail(id),
      ),
    );

final matchOverviewControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchResourceController<MatchOverviewV1>, int>(
      (ref, id) => MatchResourceController(
        target: '比赛概览',
        loader: () => ref.watch(matchDetailRepositoryProvider).overview(id),
      ),
    );

final matchLineupsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchResourceController<MatchLineups>, int>(
      (ref, id) => MatchResourceController(
        target: '比赛阵容',
        loader: () => ref.watch(matchDetailRepositoryProvider).lineups(id),
      ),
    );

final matchTeamStatsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchResourceController<List<MatchTeamStatItem>>, int>(
      (ref, id) => MatchResourceController(
        target: '球队统计',
        loader: () => ref.watch(matchDetailRepositoryProvider).stats(id),
      ),
    );

final matchPlayerStatsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MatchPlayerStatsController, int>((ref, id) {
      final repository = ref.watch(matchDetailRepositoryProvider);
      return MatchPlayerStatsController(
        target: '球员统计',
        loader: (page, size, teamId, position) => repository.playerStats(
          id,
          page,
          size,
          teamId: teamId,
          position: position,
        ),
      );
    });

typedef MatchPlayerStatsLoader =
    Future<FootballPage<MatchPlayerStat>> Function(
      int page,
      int size,
      int? teamId,
      String? position,
    );

final class MatchPlayerStatsController extends ChangeNotifier {
  MatchPlayerStatsController({required this.target, required this.loader});
  final String target;
  final MatchPlayerStatsLoader loader;
  TeamPagedState<MatchPlayerStat> _state = const TeamPagedState();
  int? _teamId;
  String? _position;
  int _generation = 0;
  bool _loaded = false;
  TeamPagedState<MatchPlayerStat> get state => _state;
  int? get teamId => _teamId;
  String? get position => _position;

  Future<void> loadInitial() async {
    if (_loaded && _state.status != TeamPagedStatus.failure) return;
    _loaded = true;
    final generation = ++_generation;
    _set(const TeamPagedState());
    await _request(generation, page: 1, preserve: false);
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    final generation = ++_generation;
    _set(_copy(isRefreshing: true, loadingMore: false, clearMessages: true));
    await _request(generation, page: 1, preserve: true);
  }

  Future<void> setFilter({int? teamId, String? position}) async {
    final normalized = position?.trim();
    if (_teamId == teamId && _position == normalized) return;
    _teamId = teamId;
    _position = normalized?.isEmpty == true ? null : normalized;
    _loaded = true;
    final generation = ++_generation;
    _set(const TeamPagedState());
    await _request(generation, page: 1, preserve: false);
  }

  Future<void> loadMore() async {
    if (_state.loadingMore || !_state.hasMore) return;
    final generation = _generation;
    _set(_copy(loadingMore: true, clearMessages: true));
    try {
      final page = await loader(_state.pageNum + 1, 20, _teamId, _position);
      if (generation != _generation) return;
      _set(
        TeamPagedState(
          status: _merged(_state.records, page.records).isEmpty
              ? TeamPagedStatus.empty
              : TeamPagedStatus.ready,
          records: _merged(_state.records, page.records),
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        _copy(
          loadingMore: false,
          appendMessage: footballErrorMessage(error, target: '更多$target'),
        ),
      );
    }
  }

  Future<void> _request(
    int generation, {
    required int page,
    required bool preserve,
  }) async {
    try {
      final result = await loader(page, 20, _teamId, _position);
      if (generation != _generation) return;
      final records = _merged(
        preserve ? _state.records : const [],
        result.records,
      );
      _set(
        TeamPagedState(
          status: records.isEmpty
              ? TeamPagedStatus.empty
              : TeamPagedStatus.ready,
          records: records,
          pageNum: result.pageNum,
          hasMore: result.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        TeamPagedState(
          status: preserve && _state.records.isNotEmpty
              ? TeamPagedStatus.ready
              : TeamPagedStatus.failure,
          records: _state.records,
          pageNum: _state.pageNum,
          hasMore: _state.hasMore,
          message: footballErrorMessage(error, target: target),
        ),
      );
    }
  }

  List<MatchPlayerStat> _merged(
    Iterable<MatchPlayerStat> current,
    Iterable<MatchPlayerStat> incoming,
  ) {
    final byId = <int, MatchPlayerStat>{};
    final invalid = <MatchPlayerStat>[];
    for (final item in [...current, ...incoming]) {
      if (item.playerId > 0) {
        byId[item.playerId] = item;
      } else {
        invalid.add(item);
      }
    }
    return [...byId.values, ...invalid];
  }

  TeamPagedState<MatchPlayerStat> _copy({
    bool? loadingMore,
    bool? isRefreshing,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => TeamPagedState(
    status: _state.status,
    records: _state.records,
    pageNum: _state.pageNum,
    hasMore: _state.hasMore,
    isRefreshing: isRefreshing ?? _state.isRefreshing,
    loadingMore: loadingMore ?? _state.loadingMore,
    message: clearMessages ? null : message ?? _state.message,
    appendMessage: clearMessages ? null : appendMessage ?? _state.appendMessage,
  );

  void _set(TeamPagedState<MatchPlayerStat> value) {
    _state = value;
    notifyListeners();
  }
}

enum MatchRatingsStatus { loading, ready, empty, failure }

final class MatchRatingsState {
  const MatchRatingsState({
    required this.status,
    this.records = const [],
    this.busyPlayerId,
    this.busyPlayerIds = const {},
    this.message,
    this.isRefreshing = false,
  });
  final MatchRatingsStatus status;
  final List<MatchRatingSummary> records;
  final int? busyPlayerId;
  final Set<int> busyPlayerIds;
  final String? message;
  final bool isRefreshing;
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
  int? _teamId;
  int _generation = 0;
  bool _loaded = false;
  MatchRatingsState get state => _state;
  int? get teamId => _teamId;

  Future<void> load({int? teamId, bool force = false}) async {
    if (!force &&
        _loaded &&
        _teamId == teamId &&
        _state.status != MatchRatingsStatus.failure) {
      return;
    }
    _loaded = true;
    _teamId = teamId;
    final generation = ++_generation;
    _set(const MatchRatingsState(status: MatchRatingsStatus.loading));
    try {
      final values = await _repository.ratings(matchId, teamId: teamId);
      if (generation != _generation) return;
      _set(
        MatchRatingsState(
          status: values.isEmpty
              ? MatchRatingsStatus.empty
              : MatchRatingsStatus.ready,
          records: values,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        MatchRatingsState(
          status: MatchRatingsStatus.failure,
          message: error.message,
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    final generation = ++_generation;
    final previous = _state.records;
    _set(
      MatchRatingsState(
        status: previous.isEmpty
            ? MatchRatingsStatus.loading
            : MatchRatingsStatus.ready,
        records: previous,
        isRefreshing: previous.isNotEmpty,
      ),
    );
    try {
      final values = await _repository.ratings(matchId, teamId: _teamId);
      if (generation != _generation) return;
      _set(
        MatchRatingsState(
          status: values.isEmpty
              ? MatchRatingsStatus.empty
              : MatchRatingsStatus.ready,
          records: values,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        MatchRatingsState(
          status: previous.isEmpty
              ? MatchRatingsStatus.failure
              : MatchRatingsStatus.ready,
          records: previous,
          message: footballErrorMessage(error, target: '球员评分'),
        ),
      );
    }
  }

  Future<bool> submit(int playerId, double rating) {
    if (!rating.isFinite || rating < 1 || rating > 10) {
      _set(
        MatchRatingsState(
          status: _state.status,
          records: _state.records,
          busyPlayerIds: _state.busyPlayerIds,
          message: '评分范围为 1.0-10.0',
        ),
      );
      return Future.value(false);
    }
    return _write(
      playerId,
      () => _repository.submitRating(matchId, playerId, rating),
    );
  }

  Future<bool> cancel(int playerId) =>
      _write(playerId, () => _repository.cancelRating(matchId, playerId));

  Future<bool> _write(
    int playerId,
    Future<MatchRatingResult> Function() action,
  ) async {
    if (matchId <= 0 || playerId <= 0) return false;
    if (_state.busyPlayerIds.contains(playerId)) return false;
    final before = _state;
    final busy = {...before.busyPlayerIds, playerId};
    _set(
      MatchRatingsState(
        status: before.status,
        records: before.records,
        busyPlayerId: playerId,
        busyPlayerIds: busy,
        message: before.message,
      ),
    );
    try {
      final result = await action();
      final current = _state;
      final busy = {...current.busyPlayerIds}..remove(playerId);
      final records = [
        for (final item in current.records)
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
        MatchRatingsState(
          status: MatchRatingsStatus.ready,
          records: records,
          busyPlayerId: busy.isEmpty ? null : busy.first,
          busyPlayerIds: busy,
          message: current.message,
          isRefreshing: current.isRefreshing,
        ),
      );
      return true;
    } on AppNetworkException catch (error) {
      final current = _state;
      final busy = {...current.busyPlayerIds}..remove(playerId);
      _set(
        MatchRatingsState(
          status: current.status,
          records: current.records,
          busyPlayerId: busy.isEmpty ? null : busy.first,
          busyPlayerIds: busy,
          message: error.message,
          isRefreshing: current.isRefreshing,
        ),
      );
      return false;
    }
  }

  void clearMessage() {
    if (_state.message == null) return;
    _set(
      MatchRatingsState(
        status: _state.status,
        records: _state.records,
        busyPlayerId: _state.busyPlayerId,
        busyPlayerIds: _state.busyPlayerIds,
        isRefreshing: _state.isRefreshing,
      ),
    );
  }

  bool isBusy(int playerId) => _state.busyPlayerIds.contains(playerId);

  void _set(MatchRatingsState value) {
    _state = value;
    notifyListeners();
  }
}
