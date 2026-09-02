import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/football_api.dart';
import 'package:tifo/features/football/data/team_detail_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real team overview players stats honors matches and contents',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final client = ApiClient(
        AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
        Dio(),
      );
      final football = FootballApi(client);
      final teams = TeamDetailApi(client);
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
      final teamId = standings.records.first.teamId;

      final overview = await teams.overview(teamId, seasonId: season.id);
      final players = await teams.players(
        teamId,
        seasonId: season.id,
        pageSize: 2,
      );
      final stats = await teams.stats(
        teamId,
        seasonId: season.id,
        stageId: stages.firstOrNull?.id,
      );
      final honors = await teams.honors(teamId);
      final matches = await teams.matches(teamId, pageSize: 2);
      final contents = await teams.contents(teamId, pageSize: 2);

      expect(overview.teamId, teamId);
      expect(players.pageNum, 1);
      expect(stats.played, isNotNull);
      expect(honors.map((item) => item.id).toSet().length, honors.length);
      expect(
        matches.records.every(
          (item) => item.homeTeam.id == teamId || item.awayTeam.id == teamId,
        ),
        isTrue,
      );
      expect(
        contents.records.map((item) => item.id).toSet().length,
        contents.records.length,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
