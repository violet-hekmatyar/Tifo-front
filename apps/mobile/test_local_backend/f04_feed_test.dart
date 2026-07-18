import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/onboarding/data/onboarding_api.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real backend provides authenticated home feed and followed teams',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
      }
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final client = ApiClient(config, dio);
      final auth = AuthRepository(AuthApi(client), storage);
      final onboarding = OnboardingRepository(OnboardingApi(client));
      final feed = FeedRepository(FeedApi(client));

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f04_${suffix.substring(suffix.length - 12)}';
      final phone = '136${suffix.substring(suffix.length - 8)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}f';
      await auth.register(username: username, phone: phone, password: password);
      await auth.login(username: username, password: password);

      final options = await onboarding.loadOptions();
      expect(options.teams, isNotEmpty);
      final selectedTeams = options.teams
          .take(2)
          .map((team) => team.id)
          .toList();
      await onboarding.savePreferences(
        mainTeamId: selectedTeams.first,
        followTeamIds: selectedTeams,
        followPlayerIds: options.players.take(1).map((player) => player.id),
      );

      final page = await feed.loadFeed(
        filter: FeedFilter.recommend,
        pageNum: 1,
        pageSize: 5,
      );
      expect(page.pageNum, 1);
      expect(page.pageSize, 5);
      expect(page.total, greaterThan(0));
      expect(page.pages, greaterThanOrEqualTo(1));
      expect(page.cards, isNotEmpty);
      expect(
        page.cards.whereType<ContentFeedCard>().isNotEmpty ||
            page.cards.whereType<MatchFeedCard>().isNotEmpty,
        isTrue,
      );
      expect(page.cards.whereType<UnknownFeedCard>(), isEmpty);

      final followed = await feed.loadFollowedTeams();
      expect(
        followed.map((team) => team.teamId),
        contains(selectedTeams.first),
      );
      expect(followed.every((team) => team.teamName.isNotEmpty), isTrue);

      final teamPage = await feed.loadFeed(
        filter: FeedFilter.recommend,
        teamId: selectedTeams.first,
        pageNum: 1,
        pageSize: 5,
      );
      expect(teamPage.pageNum, 1);
      expect(teamPage.pageSize, 5);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
