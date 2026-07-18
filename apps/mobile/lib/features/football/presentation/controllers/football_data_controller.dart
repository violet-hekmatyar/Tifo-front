import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/football_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/match_display_sort.dart';

sealed class FootballSource {
  const FootballSource();
}

final class ImportantSource extends FootballSource {
  const ImportantSource();
}

final class FollowingSource extends FootballSource {
  const FollowingSource();
}

final class LeagueSource extends FootballSource {
  const LeagueSource(this.leagueId);
  final int leagueId;
}

enum FootballDataStatus { loading, ready, empty, failure }

final class FootballDataState {
  const FootballDataState({
    required this.status,
    this.source = const ImportantSource(),
    this.leagues = const [],
    this.matches = const [],
    this.pageNum = 0,
    this.hasMore = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.message,
    this.appendMessage,
  });
  const FootballDataState.loading() : this(status: FootballDataStatus.loading);

  final FootballDataStatus status;
  final FootballSource source;
  final List<League> leagues;
  final List<FootballMatch> matches;
  final int pageNum;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? message;
  final String? appendMessage;
}

final footballDataControllerProvider =
    ChangeNotifierProvider.autoDispose<FootballDataController>(
      (ref) => FootballDataController(ref.watch(footballRepositoryProvider)),
    );

final class FootballDataController extends ChangeNotifier {
  FootballDataController(this._repository);
  static const pageSize = 10;
  final FootballRepositoryContract _repository;
  FootballDataState _state = const FootballDataState.loading();
  int _generation = 0;
  FootballDataState get state => _state;

  Future<void> loadInitial() async {
    final generation = ++_generation;
    _set(
      FootballDataState(
        status: FootballDataStatus.loading,
        source: _state.source,
        leagues: _state.leagues,
      ),
    );
    try {
      final results = await Future.wait<Object>([
        _state.leagues.isEmpty
            ? _repository.leagues()
            : Future.value(_state.leagues),
        _loadPage(1),
      ]);
      if (generation != _generation) return;
      _setPage(
        results[1] as FootballPage<FootballMatch>,
        leagues: results[0] as List<League>,
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _set(
        FootballDataState(
          status: FootballDataStatus.failure,
          source: _state.source,
          leagues: _state.leagues,
          message: footballErrorMessage(error, target: '赛程'),
        ),
      );
    }
  }

  Future<void> selectSource(FootballSource source) async {
    if (_sameSource(_state.source, source)) return;
    _state = FootballDataState(
      status: FootballDataStatus.loading,
      source: source,
      leagues: _state.leagues,
    );
    notifyListeners();
    await loadInitial();
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    final generation = ++_generation;
    _copy(isRefreshing: true, clearMessages: true);
    try {
      final results = await Future.wait<Object>([
        _repository.leagues(),
        _loadPage(1),
      ]);
      if (generation != _generation) return;
      _setPage(
        results[1] as FootballPage<FootballMatch>,
        leagues: results[0] as List<League>,
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(
        isRefreshing: false,
        message: footballErrorMessage(error, target: '赛程'),
      );
    }
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || !_state.hasMore) return;
    final generation = _generation;
    _copy(isLoadingMore: true, clearMessages: true);
    try {
      final page = await _loadPage(_state.pageNum + 1);
      if (generation != _generation) return;
      final values = <int, FootballMatch>{
        for (final item in _state.matches) item.id: item,
        for (final item in page.records) item.id: item,
      };
      _set(
        FootballDataState(
          status: FootballDataStatus.ready,
          source: _state.source,
          leagues: _state.leagues,
          matches: sortMatchesForDisplay(values.values),
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(
        isLoadingMore: false,
        appendMessage: footballErrorMessage(error, target: '更多赛程'),
      );
    }
  }

  Future<FootballPage<FootballMatch>> _loadPage(int page) =>
      switch (_state.source) {
        ImportantSource() => _repository.importantMatches(page, pageSize),
        FollowingSource() => _repository.followingMatches(page, pageSize),
        LeagueSource(:final leagueId) => _repository.leagueMatches(
          leagueId,
          page,
          pageSize,
        ),
      };

  void _setPage(
    FootballPage<FootballMatch> page, {
    required List<League> leagues,
  }) => _set(
    FootballDataState(
      status: page.records.isEmpty
          ? FootballDataStatus.empty
          : FootballDataStatus.ready,
      source: _state.source,
      leagues: leagues,
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
    FootballDataState(
      status: _state.status,
      source: _state.source,
      leagues: _state.leagues,
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

  bool _sameSource(FootballSource a, FootballSource b) =>
      a.runtimeType == b.runtimeType &&
      (a is! LeagueSource || b is! LeagueSource || a.leagueId == b.leagueId);

  void _set(FootballDataState value) {
    _state = value;
    notifyListeners();
  }
}

String footballErrorMessage(
  AppNetworkException error, {
  required String target,
}) => switch (error) {
  NetworkException() => '网络连接失败，请检查后重试。',
  TimeoutException() => '请求超时，请稍后重试。',
  BusinessException(code: 40401) => '$target不存在或已下架。',
  BusinessException(code: 40101 || 40102) => '登录状态已失效，请重新登录。',
  BusinessException() => error.message,
  HttpException(statusCode: 403) => '当前账号无权访问该内容。',
  ParseException() => '$target数据格式异常，请重试。',
  _ => '$target加载失败，请稍后重试。',
};
