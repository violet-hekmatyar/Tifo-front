import '../../../core/network/backend_v1_contract.dart';

final class SearchEntity {
  const SearchEntity({
    required this.type,
    required this.rawType,
    required this.name,
    this.entityId,
    this.nameEn,
    this.subtitle,
    this.logoUrl,
    this.avatarUrl,
    this.status,
    this.homeTeamId,
    this.awayTeamId,
    this.matchStatus,
    this.matchTime,
    this.contentType,
    this.publishTime,
  });

  final SearchEntityType type;
  final String rawType;
  final int? entityId;
  final String name;
  final String? nameEn;
  final String? subtitle;
  final String? logoUrl;
  final String? avatarUrl;
  final String? status;
  final int? homeTeamId;
  final int? awayTeamId;
  final String? matchStatus;
  final DateTime? matchTime;
  final String? contentType;
  final DateTime? publishTime;

  String get stableKey => '${type.wireValue}:${entityId ?? '$rawType:$name'}';
}

final class SearchPageResult {
  const SearchPageResult({
    required this.records,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  final List<SearchEntity> records;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;

  bool get hasMore => pageNum < pages;
}
