import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/football/data/football_api.dart';
import 'package:tifo/features/football/domain/football_ranking_models.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real seasons stages standings player and team ranks',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final api = FootballApi(
        ApiClient(
          AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
          Dio(),
        ),
      );
      final leagues = await api.leagues();
      expect(leagues, isNotEmpty);
      final league = leagues.first;
      final seasons = await api.seasons(league.id);
      expect(seasons, isNotEmpty);
      final season =
          seasons.where((item) => item.current).firstOrNull ?? seasons.first;
      final stages = await api.stages(league.id, season.id);
      final stageId = stages.firstOrNull?.id;
      final standings = await api.standings(
        leagueId: league.id,
        seasonId: season.id,
        stageId: stageId,
      );
      final players = await api.playerRanks(
        leagueId: league.id,
        seasonId: season.id,
        stageId: stageId,
        rankType: PlayerRankType.goals,
        pageNum: 1,
        pageSize: 2,
      );
      final teams = await api.teamRanks(
        leagueId: league.id,
        seasonId: season.id,
        stageId: stageId,
        rankType: TeamRankType.goalsFor,
        pageNum: 1,
        pageSize: 2,
      );

      expect(standings.leagueId, league.id);
      expect(players.pageNum, 1);
      expect(teams.pageNum, 1);
      expect(
        players.records.map((item) => item.playerId).toSet().length,
        players.records.length,
      );
      expect(
        teams.records.map((item) => item.teamId).toSet().length,
        teams.records.length,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
