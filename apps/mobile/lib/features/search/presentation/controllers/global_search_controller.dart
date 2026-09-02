import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../data/search_repository.dart';
import '../../domain/search_models.dart';

enum GlobalSearchStatus { idle, loading, ready, empty, failure }

final class GlobalSearchState {
  const GlobalSearchState({
    this.status = GlobalSearchStatus.idle,
    this.keyword = '',
    this.entityType,
    this.records = const [],
    this.pageNum = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.message,
    this.appendMessage,
  });

  final GlobalSearchStatus status;
  final String keyword;
  final SearchEntityType? entityType;
  final List<SearchEntity> records;
  final int pageNum;
  final bool hasMore;
  final bool isLoadingMore;
  final String? message;
  final String? appendMessage;
}

final globalSearchControllerProvider =
    ChangeNotifierProvider.autoDispose<GlobalSearchController>(
      (ref) => GlobalSearchController(ref.watch(searchRepositoryProvider)),
    );

final class GlobalSearchController extends ChangeNotifier {
  GlobalSearchController(this._repository);

  static const pageSize = 20;
  final SearchRepositoryContract _repository;
  GlobalSearchState _state = const GlobalSearchState();
  int _generation = 0;

  GlobalSearchState get state => _state;

  Future<void> search(String value) async {
    final keyword = value.trim();
    final generation = ++_generation;
    if (keyword.isEmpty) {
      _setState(GlobalSearchState(entityType: _state.entityType));
      return;
    }
    _setState(
      GlobalSearchState(
        status: GlobalSearchStatus.loading,
        keyword: keyword,
        entityType: _state.entityType,
      ),
    );
    await _loadFirstPage(generation);
  }

  Future<void> selectType(SearchEntityType? entityType) async {
    if (_state.entityType == entityType) return;
    final generation = ++_generation;
    final keyword = _state.keyword;
    if (keyword.isEmpty) {
      _setState(GlobalSearchState(entityType: entityType));
      return;
    }
    _setState(
      GlobalSearchState(
        status: GlobalSearchStatus.loading,
        keyword: keyword,
        entityType: entityType,
      ),
    );
    await _loadFirstPage(generation);
  }

  Future<void> retry() async {
    if (_state.keyword.isEmpty) return;
    final generation = ++_generation;
    _setState(
      GlobalSearchState(
        status: GlobalSearchStatus.loading,
        keyword: _state.keyword,
        entityType: _state.entityType,
      ),
    );
    await _loadFirstPage(generation);
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || !_state.hasMore || _state.keyword.isEmpty) {
      return;
    }
    final generation = _generation;
    _copy(isLoadingMore: true, clearAppendMessage: true);
    try {
      final page = await _repository.search(
        keyword: _state.keyword,
        entityType: _state.entityType,
        pageNum: _state.pageNum + 1,
        pageSize: pageSize,
      );
      if (generation != _generation) return;
      final byKey = <String, SearchEntity>{
        for (final entity in _state.records) entity.stableKey: entity,
      };
      for (final entity in page.records) {
        byKey[entity.stableKey] = entity;
      }
      _setState(
        GlobalSearchState(
          status: byKey.isEmpty
              ? GlobalSearchStatus.empty
              : GlobalSearchStatus.ready,
          keyword: _state.keyword,
          entityType: _state.entityType,
          records: List.unmodifiable(byKey.values),
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _copy(isLoadingMore: false, appendMessage: _messageFor(error));
    }
  }

  Future<void> _loadFirstPage(int generation) async {
    try {
      final page = await _repository.search(
        keyword: _state.keyword,
        entityType: _state.entityType,
        pageNum: 1,
        pageSize: pageSize,
      );
      if (generation != _generation) return;
      _setState(
        GlobalSearchState(
          status: page.records.isEmpty
              ? GlobalSearchStatus.empty
              : GlobalSearchStatus.ready,
          keyword: _state.keyword,
          entityType: _state.entityType,
          records: page.records,
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (generation != _generation) return;
      _setState(
        GlobalSearchState(
          status: GlobalSearchStatus.failure,
          keyword: _state.keyword,
          entityType: _state.entityType,
          message: _messageFor(error),
        ),
      );
    }
  }

  void _copy({
    bool? isLoadingMore,
    String? appendMessage,
    bool clearAppendMessage = false,
  }) {
    _setState(
      GlobalSearchState(
        status: _state.status,
        keyword: _state.keyword,
        entityType: _state.entityType,
        records: _state.records,
        pageNum: _state.pageNum,
        hasMore: _state.hasMore,
        isLoadingMore: isLoadingMore ?? _state.isLoadingMore,
        message: _state.message,
        appendMessage: clearAppendMessage
            ? null
            : appendMessage ?? _state.appendMessage,
      ),
    );
  }

  String _messageFor(AppNetworkException error) => switch (error) {
    NetworkException() => '网络连接失败，请检查后重试。',
    TimeoutException() => '搜索超时，请稍后重试。',
    BusinessException() => error.message,
    ParseException() => '搜索结果格式异常，请重试。',
    _ => '搜索失败，请稍后重试。',
  };

  void _setState(GlobalSearchState value) {
    _state = value;
    notifyListeners();
  }
}
