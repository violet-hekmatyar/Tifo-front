import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/content/data/content_api.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/football/data/football_api.dart';
import 'package:tifo/features/football/data/match_detail_api.dart';
import 'package:tifo/features/football/data/player_detail_api.dart';
import 'package:tifo/features/football/data/team_detail_api.dart';
import 'package:tifo/features/recommendation/data/recommendation_behavior_api.dart';
import 'package:tifo/features/recommendation/domain/recommendation_behavior.dart';
import 'package:tifo/features/search/data/search_api.dart';
import 'package:tifo/features/user_center/data/user_center_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'F18 Backend V1 critical paths smoke',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }

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

      final feed = await FeedApi(
        client,
      ).feed(tab: FeedTab.recommend, pageNum: 1, pageSize: 50);
      expect(
        feed.cards.map((card) => card.cardType).toSet(),
        containsAll(const {
          FeedCardType.content,
          FeedCardType.match,
          FeedCardType.hotComment,
          FeedCardType.discussion,
          FeedCardType.ranking,
          FeedCardType.playerRating,
        }),
      );

      final search = SearchApi(client);
      final entities = <SearchEntityType, int>{};
      for (final type in const [
        SearchEntityType.team,
        SearchEntityType.player,
        SearchEntityType.match,
        SearchEntityType.content,
      ]) {
        final page = await search.entities(
          keyword: '曼',
          entityType: type,
          pageNum: 1,
          pageSize: 5,
        );
        expect(
          page.records,
          isNotEmpty,
          reason: '${type.wireValue} smoke data',
        );
        entities[type] = page.records.first.entityId!;
      }

      final content = await ContentApi(
        client,
      ).detail(entities[SearchEntityType.content]!);
      expect(content.contentId, entities[SearchEntityType.content]);

      final football = FootballApi(client);
      final league = (await football.leagues()).first;
      final seasons = await football.seasons(league.id);
      final season =
          seasons.where((item) => item.current).firstOrNull ?? seasons.first;
      final stages = await football.stages(league.id, season.id);
      final standings = await football.standings(
        leagueId: league.id,
        seasonId: season.id,
        stageId: stages.firstOrNull?.id,
      );
      expect(standings.records, isNotEmpty);

      final teamId = entities[SearchEntityType.team]!;
      final teams = TeamDetailApi(client);
      expect((await teams.overview(teamId)).teamId, teamId);
      await Future.wait<Object?>([
        teams.players(teamId, pageSize: 1),
        teams.stats(teamId),
        teams.honors(teamId),
        teams.matches(teamId, pageSize: 1),
        teams.contents(teamId, pageSize: 1),
      ]);

      final playerId = entities[SearchEntityType.player]!;
      final players = PlayerDetailApi(client);
      expect((await players.overview(playerId)).id, playerId);
      await Future.wait<Object?>([
        players.stats(playerId),
        players.teams(playerId),
        players.career(playerId),
        players.matches(playerId, pageSize: 1),
        players.contents(playerId, pageSize: 1),
      ]);

      final matchId = entities[SearchEntityType.match]!;
      final matches = MatchDetailApi(client);
      expect((await matches.overview(matchId)).matchId, matchId);
      await Future.wait<Object?>([
        matches.lineups(matchId),
        matches.stats(matchId),
        matches.playerStats(matchId, pageSize: 1),
        matches.ratings(matchId),
      ]);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f18_${suffix.substring(suffix.length - 12)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      final auth = AuthRepository(AuthApi(client), storage);
      await auth.register(
        username: username,
        phone: '133${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      await auth.login(username: username, password: password);
      expect((await UserCenterApi(client).summary()).userId, greaterThan(0));

      final event = RecommendationBehaviorEvent(
        clientEventId: 'f18-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: 'f18-smoke',
        behaviorType: RecommendationBehaviorType.expose,
        source: RecommendationSourceContext(
          targetType: RecommendationTargetType.content,
          targetId: content.contentId,
          attribution: const RecommendationAttribution(
            algorithmVersion: 'F18_SMOKE',
            requestId: 'f18-smoke',
            impressionId: 'f18-smoke-content',
            position: 0,
          ),
        ),
        eventTime: DateTime.now(),
      );
      final behaviors = RecommendationBehaviorApi(client);
      final saved = await behaviors.sendBatch([event]);
      expect(saved.saved, 1);
      final duplicate = await behaviors.sendBatch([event]);
      expect(duplicate.duplicated, 1);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
