import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_card.dart';
import '../../domain/feed_filter.dart';
import '../../domain/feed_page.dart';

enum FeedLoadStatus { loading, ready, empty, failure }

final class FeedState {
  const FeedState({
    required this.status,
    this.cards = const [],
    this.followedTeams = const [],
    this.filter = FeedFilter.recommend,
    this.teamId,
    this.pageNum = 0,
    this.hasMore = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.message,
    this.appendMessage,
  });

  const FeedState.loading() : this(status: FeedLoadStatus.loading);

  final FeedLoadStatus status;
  final List<FeedCard> cards;
  final List<FollowedTeam> followedTeams;
  final FeedFilter filter;
  final int? teamId;
  final int pageNum;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? message;
  final String? appendMessage;
}

final feedControllerProvider =
    ChangeNotifierProvider.autoDispose<FeedController>(
      (ref) => FeedController(ref.watch(feedRepositoryProvider)),
    );

final class FeedController extends ChangeNotifier {
  FeedController(this._repository);

  static const pageSize = 10;
  final FeedRepositoryContract _repository;
  FeedState _state = const FeedState.loading();
  int _generation = 0;

  FeedState get state => _state;

  Future<void> loadInitial() async {
    final generation = ++_generation;
    _setState(
      FeedState(
        status: FeedLoadStatus.loading,
        filter: _state.filter,
        teamId: _state.teamId,
        followedTeams: _state.followedTeams,
      ),
    );
    try {
      final teamsFuture = _state.followedTeams.isEmpty
          ? _repository.loadFollowedTeams()
          : Future.value(_state.followedTeams);
      final pageFuture = _loadPage(1);
      final results = await Future.wait<Object>([teamsFuture, pageFuture]);
      if (generation != _generation) return;
      final teams = results[0] as List<FollowedTeam>;
      final page = results[1] as FeedPage;
      _setPage(page, teams: teams);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _setState(
        FeedState(
          status: FeedLoadStatus.failure,
          filter: _state.filter,
          teamId: _state.teamId,
          followedTeams: _state.followedTeams,
          message: _messageFor(error),
        ),
      );
    }
  }

  Future<void> selectFilter(FeedFilter filter) async {
    if (_state.filter == filter && _state.teamId == null) return;
    _state = FeedState(
      status: FeedLoadStatus.loading,
      filter: filter,
      followedTeams: _state.followedTeams,
    );
    notifyListeners();
    await loadInitial();
  }

  Future<void> selectTeam(int? teamId) async {
    if (_state.teamId == teamId) return;
    _state = FeedState(
      status: FeedLoadStatus.loading,
      filter: _state.filter,
      teamId: teamId,
      followedTeams: _state.followedTeams,
    );
    notifyListeners();
    await loadInitial();
  }

  Future<void> refresh() async {
    if (_state.isRefreshing) return;
    final generation = ++_generation;
    _copy(isRefreshing: true, clearMessages: true);
    try {
      final page = await _loadPage(1);
      if (generation != _generation) return;
      _setPage(page, teams: _state.followedTeams);
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(isRefreshing: false, message: _messageFor(error));
    }
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || !_state.hasMore) return;
    final generation = _generation;
    _copy(isLoadingMore: true, clearMessages: true);
    try {
      final page = await _loadPage(_state.pageNum + 1);
      if (generation != _generation) return;
      final byId = <String, FeedCard>{
        for (final card in _state.cards) feedCardStableKey(card): card,
      };
      for (final card in page.cards) {
        byId.putIfAbsent(feedCardStableKey(card), () => card);
      }
      _setState(
        FeedState(
          status: FeedLoadStatus.ready,
          cards: List.unmodifiable(byId.values),
          followedTeams: _state.followedTeams,
          filter: _state.filter,
          teamId: _state.teamId,
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(isLoadingMore: false, appendMessage: _messageFor(error));
    }
  }

  Future<FeedPage> _loadPage(int pageNum) => _repository.loadFeed(
    filter: _state.filter,
    teamId: _state.teamId,
    pageNum: pageNum,
    pageSize: pageSize,
  );

  void _setPage(FeedPage page, {required List<FollowedTeam> teams}) {
    final preservingLoadedPages =
        _state.isRefreshing && _state.cards.isNotEmpty;
    final cards = preservingLoadedPages
        ? _mergeRefreshedCards(page.cards)
        : page.cards;
    _setState(
      FeedState(
        status: cards.isEmpty ? FeedLoadStatus.empty : FeedLoadStatus.ready,
        cards: cards,
        followedTeams: teams,
        filter: _state.filter,
        teamId: _state.teamId,
        pageNum: preservingLoadedPages ? _state.pageNum : page.pageNum,
        hasMore: preservingLoadedPages ? _state.hasMore : page.hasMore,
      ),
    );
  }

  List<FeedCard> _mergeRefreshedCards(List<FeedCard> refreshed) {
    final refreshedKeys = {
      for (final card in refreshed) feedCardStableKey(card),
    };
    return List.unmodifiable([
      ...refreshed,
      for (final card in _state.cards)
        if (!refreshedKeys.contains(feedCardStableKey(card))) card,
    ]);
  }

  void _copy({
    bool? isRefreshing,
    bool? isLoadingMore,
    String? message,
    String? appendMessage,
    bool clearMessages = false,
  }) {
    _setState(
      FeedState(
        status: _state.status,
        cards: _state.cards,
        followedTeams: _state.followedTeams,
        filter: _state.filter,
        teamId: _state.teamId,
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
  }

  String _messageFor(AppNetworkException error) => switch (error) {
    NetworkException() => '网络连接失败，请检查后重试。',
    TimeoutException() => '请求超时，请稍后重试。',
    BusinessException() => error.message,
    HttpException(statusCode: 403) => '当前账号无权访问该内容。',
    ParseException() => '首页数据格式异常，请重试。',
    _ => '首页加载失败，请稍后重试。',
  };

  void _setState(FeedState value) {
    _state = value;
    notifyListeners();
  }
}
