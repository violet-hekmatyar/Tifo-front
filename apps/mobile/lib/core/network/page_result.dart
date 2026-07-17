import 'api_response.dart';
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
    final total = raw['total'];
    final pageNum = raw['pageNum'];
    final pageSize = raw['pageSize'];
    final pages = raw['pages'];
    if (records is! List ||
        total is! num ||
        pageNum is! num ||
        pageSize is! num ||
        pages is! num) {
      throw const ParseException('Page data has invalid fields.');
    }
    try {
      return PageResult<T>(
        records: records.map(decodeItem).toList(growable: false),
        total: total.toInt(),
        pageNum: pageNum.toInt(),
        pageSize: pageSize.toInt(),
        pages: pages.toInt(),
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
