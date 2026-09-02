import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/football_rankings_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/football_ranking_models.dart';
import 'football_data_controller.dart';

enum FootballRankingsStatus { idle, loading, ready, empty, failure }

final class FootballRankingsState {
  const FootballRankingsState({
    this.status = FootballRankingsStatus.idle,
    this.view = FootballRankingView.standings,
    this.leagues = const [],
    this.seasons = const [],
    this.stages = const [],
    this.standings,
    this.playerRecords = const [],
    this.teamRecords = const [],
    this.playerRankType = PlayerRankType.goals,
    this.teamRankType = TeamRankType.goalsFor,
    this.pageNum = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
    this.appendMessage,
    this.selectedLeagueId,
    this.selectedSeasonId,
    this.selectedStageId,
  });

  final FootballRankingsStatus status;
  final FootballRankingView view;
  final List<League> leagues;
  final List<FootballSeason> seasons;
  final List<FootballStage> stages;
  final int? selectedLeagueId;
  final int? selectedSeasonId;
  final int? selectedStageId;
  final StandingTable? standings;
  final List<PlayerRankRecord> playerRecords;
  final List<TeamRankRecord> teamRecords;
  final PlayerRankType playerRankType;
  final TeamRankType teamRankType;
  final int pageNum;
  final bool hasMore;
  final bool loadingMore;
  final String? message;
  final String? appendMessage;
}

final footballRankingsControllerProvider =
    ChangeNotifierProvider.autoDispose<FootballRankingsController>(
      (ref) => FootballRankingsController(
        ref.watch(footballRankingsRepositoryProvider),
      ),
    );

final class FootballRankingsController extends ChangeNotifier {
  FootballRankingsController(this._repository);

  static const pageSize = 20;
  final FootballRankingsRepositoryContract _repository;
  FootballRankingsState _state = const FootballRankingsState();
  int _generation = 0;

  FootballRankingsState get state => _state;

  Future<void> loadInitial() async {
    if (_state.status != FootballRankingsStatus.idle) return;
    final generation = ++_generation;
    _set(_copy(status: FootballRankingsStatus.loading, clearMessages: true));
    try {
      final leagues = await _repository.leagues();
      if (generation != _generation) return;
      if (leagues.isEmpty) {
        _set(_copy(status: FootballRankingsStatus.empty, leagues: leagues));
        return;
      }
      await _loadLeague(
        leagues.first.id,
        leagues: leagues,
        generation: generation,
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _fail(error, '榜单');
    }
  }

  Future<void> retry() async {
    if (_state.selectedLeagueId == null || _state.selectedSeasonId == null) {
      _set(const FootballRankingsState());
      await loadInitial();
      return;
    }
    await _reloadRanking();
  }

  Future<void> selectLeague(int leagueId) async {
    if (leagueId == _state.selectedLeagueId) return;
    final generation = ++_generation;
    _set(
      _copy(
        status: FootballRankingsStatus.loading,
        selectedLeagueId: leagueId,
        clearSeason: true,
        seasons: const [],
        stages: const [],
        clearData: true,
        clearMessages: true,
      ),
    );
    try {
      await _loadLeague(leagueId, generation: generation);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _fail(error, '赛季');
    }
  }

  Future<void> _loadLeague(
    int leagueId, {
    List<League>? leagues,
    required int generation,
  }) async {
    final seasons = await _repository.seasons(leagueId);
    if (generation != _generation) return;
    if (seasons.isEmpty) {
      _set(
        _copy(
          status: FootballRankingsStatus.empty,
          leagues: leagues,
          seasons: seasons,
          selectedLeagueId: leagueId,
          clearSeason: true,
          clearData: true,
        ),
      );
      return;
    }
    final season =
        seasons.where((item) => item.current).firstOrNull ?? seasons.first;
    final stages = await _repository.stages(leagueId, season.id);
    if (generation != _generation) return;
    final stage = stages.firstOrNull;
    _set(
      _copy(
        status: FootballRankingsStatus.loading,
        leagues: leagues,
        seasons: seasons,
        stages: stages,
        selectedLeagueId: leagueId,
        selectedSeasonId: season.id,
        selectedStageId: stage?.id,
        clearStage: stage == null,
        clearData: true,
      ),
    );
    await _loadRanking(reset: true, generation: generation);
  }

  Future<void> selectSeason(int seasonId) async {
    final leagueId = _state.selectedLeagueId;
    if (leagueId == null || seasonId == _state.selectedSeasonId) return;
    final generation = ++_generation;
    _set(
      _copy(
        status: FootballRankingsStatus.loading,
        selectedSeasonId: seasonId,
        clearStage: true,
        stages: const [],
        clearData: true,
        clearMessages: true,
      ),
    );
    try {
      final stages = await _repository.stages(leagueId, seasonId);
      if (generation != _generation) return;
      final stage = stages.firstOrNull;
      _set(
        _copy(
          status: FootballRankingsStatus.loading,
          stages: stages,
          selectedStageId: stage?.id,
          clearStage: stage == null,
        ),
      );
      await _loadRanking(reset: true, generation: generation);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _fail(error, '阶段');
    }
  }

  Future<void> selectStage(int? stageId) async {
    if (stageId == _state.selectedStageId) return;
    _set(_copy(selectedStageId: stageId, clearStage: stageId == null));
    await _reloadRanking();
  }

  Future<void> selectView(FootballRankingView view) async {
    if (view == _state.view && _state.status != FootballRankingsStatus.idle) {
      return;
    }
    _set(_copy(view: view, clearData: true));
    if (_state.status == FootballRankingsStatus.idle) {
      await loadInitial();
    } else {
      await _reloadRanking();
    }
  }

  Future<void> selectPlayerRankType(PlayerRankType value) async {
    if (value == _state.playerRankType) return;
    _set(_copy(playerRankType: value, clearData: true));
    await _reloadRanking();
  }

  Future<void> selectTeamRankType(TeamRankType value) async {
    if (value == _state.teamRankType) return;
    _set(_copy(teamRankType: value, clearData: true));
    await _reloadRanking();
  }

  Future<void> _reloadRanking() async {
    try {
      await _loadRanking(reset: true);
    } on AppNetworkException catch (error) {
      _fail(error, '榜单');
    }
  }

  Future<void> loadMore() async {
    if (_state.loadingMore ||
        !_state.hasMore ||
        _state.view == FootballRankingView.standings) {
      return;
    }
    final generation = _generation;
    _set(_copy(loadingMore: true, clearMessages: true));
    try {
      await _loadRanking(reset: false, generation: generation);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        _copy(
          loadingMore: false,
          appendMessage: footballErrorMessage(error, target: '更多榜单'),
        ),
      );
    }
  }

  Future<void> _loadRanking({required bool reset, int? generation}) async {
    final leagueId = _state.selectedLeagueId;
    final seasonId = _state.selectedSeasonId;
    if (leagueId == null || seasonId == null) return;
    final requestGeneration = generation ?? ++_generation;
    if (reset) {
      _set(
        _copy(
          status: FootballRankingsStatus.loading,
          loadingMore: false,
          clearData: true,
          clearMessages: true,
        ),
      );
    }
    switch (_state.view) {
      case FootballRankingView.standings:
        final table = await _repository.standings(
          leagueId: leagueId,
          seasonId: seasonId,
          stageId: _state.selectedStageId,
          groupCode: _selectedStage?.groupCode,
        );
        if (requestGeneration != _generation) return;
        _set(
          _copy(
            status: table.records.isEmpty
                ? FootballRankingsStatus.empty
                : FootballRankingsStatus.ready,
            standings: table,
            pageNum: 1,
            hasMore: false,
          ),
        );
      case FootballRankingView.players:
        final page = await _repository.playerRanks(
          leagueId: leagueId,
          seasonId: seasonId,
          stageId: _state.selectedStageId,
          rankType: _state.playerRankType,
          page: reset ? 1 : _state.pageNum + 1,
          size: pageSize,
        );
        if (requestGeneration != _generation) return;
        final records = <int, PlayerRankRecord>{
          if (!reset)
            for (final item in _state.playerRecords) item.playerId: item,
          for (final item in page.records) item.playerId: item,
        }.values.toList(growable: false);
        _set(
          _copy(
            status: records.isEmpty
                ? FootballRankingsStatus.empty
                : FootballRankingsStatus.ready,
            playerRecords: records,
            pageNum: page.pageNum,
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
      case FootballRankingView.teams:
        final page = await _repository.teamRanks(
          leagueId: leagueId,
          seasonId: seasonId,
          stageId: _state.selectedStageId,
          rankType: _state.teamRankType,
          page: reset ? 1 : _state.pageNum + 1,
          size: pageSize,
        );
        if (requestGeneration != _generation) return;
        final records = <int, TeamRankRecord>{
          if (!reset)
            for (final item in _state.teamRecords) item.teamId: item,
          for (final item in page.records) item.teamId: item,
        }.values.toList(growable: false);
        _set(
          _copy(
            status: records.isEmpty
                ? FootballRankingsStatus.empty
                : FootballRankingsStatus.ready,
            teamRecords: records,
            pageNum: page.pageNum,
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
    }
  }

  FootballStage? get _selectedStage => _state.stages
      .where((item) => item.id == _state.selectedStageId)
      .firstOrNull;

  void _fail(AppNetworkException error, String target) => _set(
    _copy(
      status: FootballRankingsStatus.failure,
      loadingMore: false,
      message: footballErrorMessage(error, target: target),
    ),
  );

  FootballRankingsState _copy({
    FootballRankingsStatus? status,
    FootballRankingView? view,
    List<League>? leagues,
    List<FootballSeason>? seasons,
    List<FootballStage>? stages,
    int? selectedLeagueId,
    int? selectedSeasonId,
    int? selectedStageId,
    StandingTable? standings,
    List<PlayerRankRecord>? playerRecords,
    List<TeamRankRecord>? teamRecords,
    PlayerRankType? playerRankType,
    TeamRankType? teamRankType,
    int? pageNum,
    bool? hasMore,
    bool? loadingMore,
    String? message,
    String? appendMessage,
    bool clearSeason = false,
    bool clearStage = false,
    bool clearData = false,
    bool clearMessages = false,
  }) => FootballRankingsState(
    status: status ?? _state.status,
    view: view ?? _state.view,
    leagues: leagues ?? _state.leagues,
    seasons: seasons ?? _state.seasons,
    stages: stages ?? _state.stages,
    selectedLeagueId:
        selectedLeagueId ?? (clearSeason ? null : _state.selectedLeagueId),
    selectedSeasonId:
        selectedSeasonId ?? (clearSeason ? null : _state.selectedSeasonId),
    selectedStageId:
        selectedStageId ??
        (clearStage || clearSeason ? null : _state.selectedStageId),
    standings: clearData ? null : standings ?? _state.standings,
    playerRecords: clearData ? const [] : playerRecords ?? _state.playerRecords,
    teamRecords: clearData ? const [] : teamRecords ?? _state.teamRecords,
    playerRankType: playerRankType ?? _state.playerRankType,
    teamRankType: teamRankType ?? _state.teamRankType,
    pageNum: clearData ? 0 : pageNum ?? _state.pageNum,
    hasMore: clearData ? false : hasMore ?? _state.hasMore,
    loadingMore: loadingMore ?? _state.loadingMore,
    message: clearMessages ? null : message ?? _state.message,
    appendMessage: clearMessages ? null : appendMessage ?? _state.appendMessage,
  );

  void _set(FootballRankingsState value) {
    _state = value;
    notifyListeners();
  }
}
