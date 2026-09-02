import 'api_response.dart';
import 'json_value.dart';
import 'network_exceptions.dart';

final class PageResult<T> {
  const PageResult({
    required this.records,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  factory PageResult.fromRaw(Object? raw, JsonDecoder<T> decodeItem) {
    if (raw is! Map) {
      throw const ParseException('Page data must be a JSON object.');
    }
    final records = raw['records'];
    final total = jsonInt(raw['total']);
    final pageNum = jsonInt(raw['pageNum']);
    final pageSize = jsonInt(raw['pageSize']);
    final pages = jsonInt(raw['pages']);
    if (records is! List ||
        total == null ||
        pageNum == null ||
        pageSize == null ||
        pages == null) {
      throw const ParseException('Page data has invalid fields.');
    }
    try {
      return PageResult<T>(
        records: records.map(decodeItem).toList(growable: false),
        total: total,
        pageNum: pageNum,
        pageSize: pageSize,
        pages: pages,
      );
    } on AppNetworkException {
      rethrow;
    } catch (error) {
      throw ParseException('Failed to decode page records.', cause: error);
    }
  }

  final List<T> records;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;
}
