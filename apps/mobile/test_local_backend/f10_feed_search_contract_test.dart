import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/search/data/search_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real Backend V1 Feed and Search parse through F10 models',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final client = ApiClient(
        AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
        Dio(),
      );
      final feed = await FeedApi(
        client,
      ).feed(tab: FeedTab.recommend, pageNum: 1, pageSize: 50);
      final types = feed.cards.map((card) => card.cardType).toSet();
      expect(
        types,
        containsAll(const {
          FeedCardType.content,
          FeedCardType.match,
          FeedCardType.hotComment,
          FeedCardType.discussion,
          FeedCardType.ranking,
          FeedCardType.playerRating,
        }),
      );
      expect(types, isNot(contains(FeedCardType.unknown)));

      final api = SearchApi(client);
      final mixed = await api.entities(keyword: '曼', pageNum: 1, pageSize: 20);
      expect(mixed.records, isNotEmpty);
      for (final type in const [
        SearchEntityType.team,
        SearchEntityType.player,
        SearchEntityType.match,
        SearchEntityType.content,
      ]) {
        final page = await api.entities(
          keyword: '曼',
          entityType: type,
          pageNum: 1,
          pageSize: 3,
        );
        expect(
          page.records,
          isNotEmpty,
          reason: '${type.wireValue} should exist',
        );
        expect(page.records.every((entity) => entity.type == type), isTrue);
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
