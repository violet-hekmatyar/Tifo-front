import '../../../core/network/api_client.dart';
import '../../../core/network/backend_v1_contract.dart';
import '../../../core/network/page_result.dart';
import '../domain/search_models.dart';
import 'dto/search_entity_dto.dart';

final class SearchApi {
  const SearchApi(this._client);

  final ApiClient _client;

  Future<SearchPageResult> entities({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) => _client.get<SearchPageResult>(
    '/api/app/search/entities',
    queryParameters: {
      'keyword': keyword,
      'entityType': ?entityType?.wireValue,
      'pageNum': pageNum,
      'pageSize': pageSize,
    },
    decode: (raw) {
      final page = PageResult<SearchEntity>.fromRaw(
        raw,
        (item) => SearchEntityDto.fromRaw(item).toDomain(),
      );
      return SearchPageResult(
        records: page.records,
        total: page.total,
        pageNum: page.pageNum,
        pageSize: page.pageSize,
        pages: page.pages,
      );
    },
  );
}
