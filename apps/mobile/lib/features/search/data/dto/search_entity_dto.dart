import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/json_value.dart';
import '../../domain/search_models.dart';

final class SearchEntityDto {
  const SearchEntityDto(this.entity);

  factory SearchEntityDto.fromRaw(Object? raw) {
    final map = jsonMap(raw);
    final rawType = jsonString(map?['entityType']) ?? 'UNKNOWN';
    return SearchEntityDto(
      SearchEntity(
        type: SearchEntityType.fromWire(rawType),
        rawType: rawType,
        entityId: jsonInt(map?['entityId']),
        name: jsonString(map?['name']) ?? '未命名结果',
        nameEn: jsonString(map?['nameEn']),
        subtitle: jsonString(map?['subtitle']),
        logoUrl: jsonString(map?['logoUrl']),
        avatarUrl: jsonString(map?['avatarUrl']),
        status: jsonString(map?['status']),
        homeTeamId: jsonInt(map?['homeTeamId']),
        awayTeamId: jsonInt(map?['awayTeamId']),
        matchStatus: jsonString(map?['matchStatus']),
        matchTime: jsonIsoDateTime(map?['matchTime']),
        contentType: jsonString(map?['contentType']),
        publishTime: jsonIsoDateTime(map?['publishTime']),
      ),
    );
  }

  final SearchEntity entity;

  SearchEntity toDomain() => entity;
}
