import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/publish_subject_repository.dart';
import '../../domain/publish_subject.dart';

enum PublishSubjectStatus { idle, loading, ready, empty, failure }

final class PublishSubjectState {
  const PublishSubjectState({
    required this.kind,
    this.status = PublishSubjectStatus.idle,
    this.keyword = '',
    this.records = const [],
    this.pageNum = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.message,
  });

  final PublishAuxiliaryKind kind;
  final PublishSubjectStatus status;
  final String keyword;
  final List<PublishAuxiliaryItem> records;
  final int pageNum;
  final bool hasMore;
  final bool isLoadingMore;
  final String? message;
}

final publishSubjectControllerProvider = ChangeNotifierProvider.autoDispose
    .family<PublishSubjectController, PublishAuxiliaryKind>(
      (ref, kind) => PublishSubjectController(
        ref.watch(publishSubjectRepositoryProvider),
        kind,
      ),
    );

final class PublishSubjectController extends ChangeNotifier {
  PublishSubjectController(this._repository, this.kind)
    : _state = PublishSubjectState(kind: kind);

  static const pageSize = 20;
  final PublishSubjectRepositoryContract _repository;
  final PublishAuxiliaryKind kind;
  PublishSubjectState _state;
  int _generation = 0;
  Timer? _debounce;
  bool _disposed = false;

  PublishSubjectState get state => _state;

  void search(String value) {
    final keyword = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_load(keyword));
    });
  }

  Future<void> loadInitial() => _load(_state.keyword);

  Future<void> retry() => _load(_state.keyword);

  Future<void> loadMore() async {
    if (_disposed || _state.isLoadingMore || !_state.hasMore) return;
    final generation = _generation;
    _set(_copy(isLoadingMore: true, clearMessage: true));
    try {
      final page = await _repository.list(
        kind: kind,
        keyword: _state.keyword,
        pageNum: _state.pageNum + 1,
        pageSize: pageSize,
      );
      if (_disposed || generation != _generation) return;
      final byKey = <String, PublishAuxiliaryItem>{
        for (final item in _state.records) item.stableKey: item,
      };
      for (final item in page.records) {
        byKey[item.stableKey] = item;
      }
      _set(
        PublishSubjectState(
          kind: kind,
          status: byKey.isEmpty
              ? PublishSubjectStatus.empty
              : PublishSubjectStatus.ready,
          keyword: _state.keyword,
          records: List.unmodifiable(byKey.values),
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (!_disposed && generation == _generation) {
        _set(_copy(isLoadingMore: false, message: error.message));
      }
    }
  }

  Future<void> _load(String keyword) async {
    if (_disposed) return;
    final generation = ++_generation;
    _set(
      PublishSubjectState(
        kind: kind,
        status: PublishSubjectStatus.loading,
        keyword: keyword,
      ),
    );
    try {
      final page = await _repository.list(
        kind: kind,
        keyword: keyword,
        pageNum: 1,
        pageSize: pageSize,
      );
      if (_disposed || generation != _generation) return;
      _set(
        PublishSubjectState(
          kind: kind,
          status: page.records.isEmpty
              ? PublishSubjectStatus.empty
              : PublishSubjectStatus.ready,
          keyword: keyword,
          records: page.records,
          pageNum: page.pageNum,
          hasMore: page.hasMore,
        ),
      );
    } on AppNetworkException catch (error) {
      if (!_disposed && generation == _generation) {
        _set(
          PublishSubjectState(
            kind: kind,
            status: PublishSubjectStatus.failure,
            keyword: keyword,
            message: error.message,
          ),
        );
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _set(
          PublishSubjectState(
            kind: kind,
            status: PublishSubjectStatus.failure,
            keyword: keyword,
            message: '目录数据解析失败，请重试。',
          ),
        );
      }
    }
  }

  PublishSubjectState _copy({
    bool? isLoadingMore,
    String? message,
    bool clearMessage = false,
  }) => PublishSubjectState(
    kind: kind,
    status: _state.status,
    keyword: _state.keyword,
    records: _state.records,
    pageNum: _state.pageNum,
    hasMore: _state.hasMore,
    isLoadingMore: isLoadingMore ?? _state.isLoadingMore,
    message: clearMessage ? null : message ?? _state.message,
  );

  void _set(PublishSubjectState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
