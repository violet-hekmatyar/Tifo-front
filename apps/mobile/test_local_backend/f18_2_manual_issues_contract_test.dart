import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/football/data/match_detail_api.dart';
import 'package:tifo/features/notification/data/notification_api.dart';
import 'package:tifo/features/notification/domain/app_notification.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real feed paging, follow notification and match lineup remain usable',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final actor = await _Account.create(baseUrl, 'actor');
      final recipient = await _Account.create(baseUrl, 'recipient');

      final feed = FeedApi(recipient.client);
      final first = await feed.feed(
        tab: FeedTab.recommend,
        pageNum: 1,
        pageSize: 10,
      );
      final second = await feed.feed(
        tab: FeedTab.recommend,
        pageNum: 2,
        pageSize: 10,
      );
      final firstKeys = first.cards.map((card) => card.cardId).toSet();
      final appended = [
        ...first.cards,
        ...second.cards.where((card) => !firstKeys.contains(card.cardId)),
      ];
      expect(appended.take(first.cards.length), first.cards);

      await actor.client.post<Object?>(
        '/api/app/users/${recipient.userId}/follow',
        decode: (raw) => raw,
      );
      final notifications = NotificationApi(recipient.client);
      final page = await notifications.list();
      final follow = page.records.firstWhere(
        (item) => item.type == AppNotificationType.userFollowed,
      );
      expect(follow.targetId, actor.userId);
      expect(follow.targetAvailable, isTrue);
      expect(await notifications.unreadCount(), greaterThanOrEqualTo(1));
      expect(await notifications.markRead(follow.notificationId), isTrue);

      const matchId = 15000000000000017;
      final match = MatchDetailApi(recipient.client);
      final lineups = await match.lineups(matchId);
      final playerStats = await match.playerStats(matchId);
      expect(lineups.home?.starters.length, 11);
      expect(lineups.away?.starters.length, 11);
      expect(lineups.home?.bench, isNotEmpty);
      expect(lineups.away?.bench, isNotEmpty);
      expect(playerStats.records, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

final class _Account {
  const _Account(this.client, this.userId);
  final ApiClient client;
  final int userId;

  static Future<_Account> create(String baseUrl, String role) async {
    final storage = InMemoryTokenStorage();
    final dio = Dio();
    dio.interceptors.add(
      buildRequestHeadersInterceptor(() async {
        final token = await storage.readAccessToken();
        return token == null ? const {} : {'Authorization': 'Bearer $token'};
      }),
    );
    final client = ApiClient(
      AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
      dio,
    );
    final auth = AuthRepository(AuthApi(client), storage);
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final username = 'f182_${role}_${suffix.substring(suffix.length - 9)}';
    final password = 'T!${suffix.substring(suffix.length - 10)}z';
    await auth.register(
      username: username,
      phone: '134${suffix.substring(suffix.length - 8)}',
      password: password,
    );
    final user = await auth.login(username: username, password: password);
    return _Account(client, user.id);
  }
}
