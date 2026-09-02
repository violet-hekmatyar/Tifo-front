import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/team_detail_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/team_detail_models.dart';
import 'football_data_controller.dart';

final teamOverviewProvider = FutureProvider.autoDispose
    .family<TeamOverview, TeamDetailContext>(
      (ref, request) => ref
          .watch(teamDetailRepositoryProvider)
          .overview(request.teamId, seasonId: request.seasonId),
    );

final teamStatsProvider = FutureProvider.autoDispose
    .family<TeamStats, TeamDetailContext>(
      (ref, request) => ref
          .watch(teamDetailRepositoryProvider)
          .stats(
            request.teamId,
            seasonId: request.seasonId,
            stageId: request.stageId,
          ),
    );

final teamHonorsProvider = FutureProvider.autoDispose
    .family<List<TeamHonor>, int>(
      (ref, teamId) => ref.watch(teamDetailRepositoryProvider).honors(teamId),
    );

enum TeamPagedStatus { loading, ready, empty, failure }

final class TeamPagedState<T> {
  const TeamPagedState({
    this.status = TeamPagedStatus.loading,
    this.records = const [],
    this.pageNum = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
    this.appendMessage,
  });
  final TeamPagedStatus status;
  final List<T> records;
  final int pageNum;
  final bool hasMore;
  final bool loadingMore;
  final String? message;
  final String? appendMessage;
}

typedef TeamPageLoader<T> =
    Future<FootballPage<T>> Function(int page, int size);
typedef TeamItemId<T> = int Function(T item);

final class TeamPagedController<T> extends ChangeNotifier {
  TeamPagedController({
    required this.loader,
    required this.itemId,
    required this.target,
    this.pageSize = 20,
  });
  final TeamPageLoader<T> loader;
  final TeamItemId<T> itemId;
  final String target;
  final int pageSize;
  TeamPagedState<T> _state = TeamPagedState<T>();
  int _generation = 0;
  TeamPagedState<T> get state => _state;

  Future<void> loadInitial() async {
    final generation = ++_generation;
    _set(TeamPagedState<T>());
    try {
      final page = await loader(1, pageSize);
      if (generation != _generation) return;
      _replace(page);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        TeamPagedState<T>(
          status: TeamPagedStatus.failure,
          message: footballErrorMessage(error, target: target),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (_state.loadingMore || !_state.hasMore) return;
    final generation = _generation;
    _set(_copy(loadingMore: true, clearMessages: true));
    try {
      final page = await loader(_state.pageNum + 1, pageSize);
      if (generation != _generation) return;
      final unique = <int, T>{
        for (final item in _state.records) itemId(item): item,
        for (final item in page.records) itemId(item): item,
      };
      _set(
        TeamPagedState<T>(
          status: unique.isEmpty
              ? TeamPagedStatus.empty
              : TeamPagedStatus.ready,
          records: unique.values.toList(growable: false),
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

  void _replace(FootballPage<T> page) => _set(
    TeamPagedState<T>(
      status: page.records.isEmpty
          ? TeamPagedStatus.empty
          : TeamPagedStatus.ready,
      records: page.records,
      pageNum: page.pageNum,
      hasMore: page.hasMore,
    ),
  );

  TeamPagedState<T> _copy({
    bool? loadingMore,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) => TeamPagedState<T>(
    status: _state.status,
    records: _state.records,
    pageNum: _state.pageNum,
    hasMore: _state.hasMore,
    loadingMore: loadingMore ?? _state.loadingMore,
    message: clearMessages ? null : message ?? _state.message,
    appendMessage: clearMessages ? null : appendMessage ?? _state.appendMessage,
  );

  void _set(TeamPagedState<T> value) {
    _state = value;
    notifyListeners();
  }
}

final teamPlayersControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<TeamRosterPlayer>, TeamDetailContext>((
      ref,
      request,
    ) {
      final repository = ref.watch(teamDetailRepositoryProvider);
      return TeamPagedController(
        target: '球队球员',
        pageSize: 50,
        loader: (page, size) => repository.players(
          request.teamId,
          page,
          size,
          seasonId: request.seasonId,
        ),
        itemId: (item) => item.id,
      );
    });

final teamMatchesControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<FootballMatch>, int>((ref, teamId) {
      final repository = ref.watch(teamDetailRepositoryProvider);
      return TeamPagedController(
        target: '球队赛程',
        loader: (page, size) => repository.matches(teamId, page, size),
        itemId: (item) => item.id,
      );
    });

final teamContentsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<TeamContentSummary>, int>((ref, teamId) {
      final repository = ref.watch(teamDetailRepositoryProvider);
      return TeamPagedController(
        target: '球队动态',
        loader: (page, size) => repository.contents(teamId, page, size),
        itemId: (item) => item.id,
      );
    });
