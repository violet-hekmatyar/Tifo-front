import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/page_result.dart';
import '../domain/publish_subject.dart';

final class PublishSubjectApi {
  const PublishSubjectApi(this._client);
  final ApiClient _client;

  Future<PublishSubjectPage> list({
    required PublishAuxiliaryKind kind,
    required String keyword,
    required int pageNum,
    required int pageSize,
  }) => _client.get<PublishSubjectPage>(
    '/api/app/publish/subjects',
    queryParameters: {
      'type': kind.wireValue,
      'keyword': keyword,
      'pageNum': pageNum,
      'pageSize': pageSize,
    },
    decode: (raw) {
      final page = PageResult<PublishAuxiliaryItem>.fromRaw(
        raw,
        (item) => _item(item, kind),
      );
      return PublishSubjectPage(
        records: page.records,
        total: page.total,
        pageNum: page.pageNum,
        pageSize: page.pageSize,
        pages: page.pages,
      );
    },
  );
}

PublishAuxiliaryItem _item(Object? raw, PublishAuxiliaryKind requestedKind) {
  final map = jsonMap(raw);
  final id = jsonInt(map?['subjectId']);
  final name = jsonString(map?['name']);
  final type = jsonString(map?['subjectType']);
  final count = jsonInt(map?['discussionCount']);
  if (id == null || id <= 0 || name == null || count == null) {
    throw const FormatException('Invalid publish subject record.');
  }
  final kind = type == requestedKind.wireValue
      ? requestedKind
      : switch (type) {
          'TOPIC' => PublishAuxiliaryKind.topic,
          'HOT_EVENT' => PublishAuxiliaryKind.hotspot,
          _ => throw const FormatException('Invalid publish subject type.'),
        };
  return PublishAuxiliaryItem(
    id: id,
    name: name,
    count: count,
    kind: kind,
    summary: jsonString(map?['summary']),
    coverUrl: jsonString(map?['coverUrl']),
  );
}
