import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/search/data/dto/search_entity_dto.dart';

void main() {
  test('parses all Backend V1 entity fields and large ids', () {
    final entity = SearchEntityDto.fromRaw({
      'entityType': 'MATCH',
      'entityId': 15000000000000017,
      'name': '利物浦 vs 曼彻斯特城',
      'subtitle': '英格兰足球超级联赛',
      'homeTeamId': 13000000000000002,
      'awayTeamId': 13000000000000003,
      'matchStatus': 'FINISHED',
      'matchTime': '2026-07-19T11:00:00',
    }).toDomain();

    expect(entity.type, SearchEntityType.match);
    expect(entity.entityId, 15000000000000017);
    expect(entity.homeTeamId, 13000000000000002);
    expect(entity.matchTime, isNotNull);
  });

  test('unknown and missing fields degrade without throwing', () {
    final unknown = SearchEntityDto.fromRaw({
      'entityType': 'COACH',
      'entityId': null,
    }).toDomain();
    final malformed = SearchEntityDto.fromRaw('bad').toDomain();

    expect(unknown.type, SearchEntityType.unknown);
    expect(unknown.name, '未命名结果');
    expect(unknown.entityId, isNull);
    expect(malformed.type, SearchEntityType.unknown);
  });
}
