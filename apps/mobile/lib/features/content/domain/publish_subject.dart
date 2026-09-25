import 'content_detail.dart';

enum PublishAuxiliaryKind {
  topic('TOPIC'),
  hotspot('HOT_EVENT');

  const PublishAuxiliaryKind(this.wireValue);
  final String wireValue;
}

final class PublishAuxiliaryItem {
  const PublishAuxiliaryItem({
    required this.id,
    required this.name,
    required this.count,
    required this.kind,
    this.summary,
    this.coverUrl,
  });

  final int id;
  final String name;
  final int count;
  final PublishAuxiliaryKind kind;
  final String? summary;
  final String? coverUrl;

  ContentRelationInput toRelation() =>
      ContentRelationInput(type: kind.wireValue, id: id);

  String get stableKey => '${kind.wireValue}:$id';
}

final class PublishSubjectPage {
  const PublishSubjectPage({
    required this.records,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  final List<PublishAuxiliaryItem> records;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;

  bool get hasMore => pageNum < pages;
}
