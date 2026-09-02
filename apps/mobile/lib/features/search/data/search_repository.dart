import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/backend_v1_contract.dart';
import '../../../core/network/network_providers.dart';
import '../domain/search_models.dart';
import 'search_api.dart';

abstract interface class SearchRepositoryContract {
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  });
}

final searchRepositoryProvider = Provider<SearchRepositoryContract>(
  (ref) => SearchRepository(SearchApi(ref.watch(apiClientProvider))),
);

final class SearchRepository implements SearchRepositoryContract {
  const SearchRepository(this._api);

  final SearchApi _api;

  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) => _api.entities(
    keyword: keyword,
    entityType: entityType,
    pageNum: pageNum,
    pageSize: pageSize,
  );
}
