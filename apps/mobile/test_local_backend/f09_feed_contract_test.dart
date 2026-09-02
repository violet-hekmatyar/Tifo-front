import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/feed/data/feed_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real Backend V1 recommend Feed parses through the F09 contract',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }

      final api = FeedApi(
        ApiClient(
          AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
          Dio(),
        ),
      );
      final page = await api.feed(
        tab: FeedTab.recommend,
        pageNum: 1,
        pageSize: 20,
      );

      expect(page.cards, isNotEmpty);
      expect(page.pageNum, 1);
      expect(page.pageSize, 20);
      expect(page.attribution.algorithmVersion, isNotEmpty);
      expect(page.attribution.requestId, isNotEmpty);
      expect(
        page.cards.every((card) => card.cardType != FeedCardType.unknown),
        isTrue,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
