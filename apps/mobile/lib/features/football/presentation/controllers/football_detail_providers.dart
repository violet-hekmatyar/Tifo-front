import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/football_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/match_display_sort.dart';

final matchDetailProvider = FutureProvider.autoDispose.family<MatchDetail, int>(
  (ref, id) => ref.watch(footballRepositoryProvider).matchDetail(id),
);

final teamDetailProvider = FutureProvider.autoDispose.family<TeamDetail, int>(
  (ref, id) => ref.watch(footballRepositoryProvider).teamDetail(id),
);

final playerDetailProvider = FutureProvider.autoDispose
    .family<PlayerDetail, int>(
      (ref, id) => ref.watch(footballRepositoryProvider).playerDetail(id),
    );

enum TeamScheduleStatus { loading, ready, empty, failure }

final class TeamScheduleState {
  const TeamScheduleState({
    required this.status,
    this.matches = const [],
    this.pageNum = 0,
    this.hasMore = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.message,
    this.appendMessage,
  });
  final TeamScheduleStatus status;
  final List<FootballMatch> matches;
  final int pageNum;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? message;
  final String? appendMessage;
}

final teamScheduleControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamScheduleController, int>(
      (ref, id) => TeamScheduleController(
        ref.watch(footballRepositoryProvider),
        teamId: id,
      ),
    );

final class TeamScheduleController extends ChangeNotifier {
  TeamScheduleController(this._repository, {required this.teamId});
  static const pageSize = 10;
  final FootballRepositoryContract _repository;
  final int teamId;
  var _generation = 0;
  TeamScheduleState _state = const TeamScheduleState(
    status: TeamScheduleStatus.loading,
  );
  TeamScheduleState get state => _state;

  Future<void> loadInitial() async {
    final generation = ++_generation;
    _set(const TeamScheduleState(status: TeamScheduleStatus.loading));
    try {
      final page = await _repository.teamMatches(teamId, 1, pageSize);
      if (generation != _generation) return;
      _replace(page);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        TeamScheduleState(
          status: TeamScheduleStatus.failure,
          message: error.message,
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    final generation = ++_generation;
    _copy(isRefreshing: true, clearMessages: true);
    try {
      final page = await _repository.teamMatches(teamId, 1, pageSize);
      if (generation != _generation) return;
      _replace(page);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(isRefreshing: false, message: error.message);
    }
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || !_state.hasMore) return;
    final generation = _generation;
    _copy(isLoadingMore: true, clearMessages: true);
    try {
      final page = await _repository.teamMatches(
        teamId,
        _state.pageNum + 1,
        pageSize,
      );
      if (generation != _generation) return;
      final values = <int, FootballMatch>{
        for (final item in _state.matches) item.id: item,
        for (final item in page.records) item.id: item,
      };
      _set(
        TeamScheduleState(
          status: TeamScheduleStatus.ready,
          matches: sortMatchesForDisplay(values.values),
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(isLoadingMore: false, appendMessage: error.message);
    }
  }

  void _replace(FootballPage<FootballMatch> page) => _set(
    TeamScheduleState(
      status: page.records.isEmpty
          ? TeamScheduleStatus.empty
          : TeamScheduleStatus.ready,
      matches: sortMatchesForDisplay(page.records),
      pageNum: page.pageNum,
      hasMore: page.hasMore,
    ),
  );

  void _copy({
    bool? isRefreshing,
    bool? isLoadingMore,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => _set(
    TeamScheduleState(
      status: _state.status,
      matches: _state.matches,
      pageNum: _state.pageNum,
      hasMore: _state.hasMore,
      isRefreshing: isRefreshing ?? _state.isRefreshing,
      isLoadingMore: isLoadingMore ?? _state.isLoadingMore,
      message: clearMessages ? null : message ?? _state.message,
      appendMessage: clearMessages
          ? null
          : appendMessage ?? _state.appendMessage,
    ),
  );

  void _set(TeamScheduleState value) {
    _state = value;
    notifyListeners();
  }
}
