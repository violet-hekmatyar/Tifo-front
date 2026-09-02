import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/json_value.dart';
import 'package:tifo/core/network/media_url_resolver.dart';

void main() {
  test('Backend V1 enums accept frozen values and degrade unknown values', () {
    expect(FeedTab.fromWire('team'), FeedTab.team);
    expect(FeedTab.fromWire('mixed'), FeedTab.unknown);
    expect(FeedCardType.fromWire('HOT_COMMENT'), FeedCardType.hotComment);
    expect(FeedCardType.fromWire('CONTENT_CARD'), FeedCardType.unknown);
    expect(SearchEntityType.fromWire('CONTENT'), SearchEntityType.content);
    expect(
      RecommendationBehaviorType.fromWire('EXPOSE'),
      RecommendationBehaviorType.expose,
    );
    expect(
      RecommendationTargetType.fromWire('PLAYER_RATING'),
      RecommendationTargetType.playerRating,
    );
    expect(
      RankingSnapshotType.fromWire('CURRENT_STANDING').displayLabel,
      '当前排名',
    );
    expect(
      RankingSnapshotType.fromWire('PRE_MATCH'),
      RankingSnapshotType.unknown,
    );
  });

  test(
    'shared JSON values keep Long, nullable, empty list, and ISO semantics',
    () {
      expect(jsonInt(9007199254740991), 9007199254740991);
      expect(jsonInt(null), isNull);
      expect(jsonList<Object>(null, (item) => item), isEmpty);
      expect(jsonList<int>(const [], jsonInt), isEmpty);
      expect(jsonIsoDateTime('2026-08-30T20:15:00'), isNotNull);
      expect(jsonIsoDateTime('not-a-time'), isNull);
    },
  );

  test('relative media URL resolves only against the Spring API base URL', () {
    final config = AppConfig.fromValues(
      apiBaseUrl: 'http://10.0.2.2:8080/api/',
    );
    expect(
      resolveMediaUrl(config, '/api/public/files/7'),
      'http://10.0.2.2:8080/api/public/files/7',
    );
    expect(
      resolveMediaUrl(config, 'https://cdn.example.test/a.png'),
      'https://cdn.example.test/a.png',
    );
    expect(resolveMediaUrl(config, null), isNull);
  });
}
