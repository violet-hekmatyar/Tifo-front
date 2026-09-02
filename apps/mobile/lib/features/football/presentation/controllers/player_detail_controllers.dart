import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/player_detail_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/player_detail_models.dart';
import '../../domain/team_detail_models.dart';
import 'team_detail_controllers.dart';

final playerOverviewV1Provider = FutureProvider.autoDispose
    .family<PlayerOverview, PlayerDetailContext>(
      (ref, request) => ref
          .watch(playerDetailRepositoryProvider)
          .overview(request.playerId, seasonId: request.seasonId),
    );

final playerStatsV1Provider = FutureProvider.autoDispose
    .family<List<PlayerSeasonStats>, PlayerDetailContext>(
      (ref, request) => ref
          .watch(playerDetailRepositoryProvider)
          .stats(
            request.playerId,
            leagueId: request.leagueId,
            seasonId: request.seasonId,
            stageId: request.stageId,
          ),
    );

final playerTeamsV1Provider = FutureProvider.autoDispose
    .family<List<PlayerTeamHistory>, int>(
      (ref, id) => ref.watch(playerDetailRepositoryProvider).teams(id),
    );

final playerCareerV1Provider = FutureProvider.autoDispose
    .family<PlayerCareer, int>(
      (ref, id) => ref.watch(playerDetailRepositoryProvider).career(id),
    );

final playerMatchesV1ControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<FootballMatch>, int>((ref, playerId) {
      final repository = ref.watch(playerDetailRepositoryProvider);
      return TeamPagedController(
        target: '球员比赛',
        loader: (page, size) => repository.matches(playerId, page, size),
        itemId: (item) => item.id,
      );
    });

final playerContentsV1ControllerProvider = ChangeNotifierProvider.autoDispose
    .family<TeamPagedController<TeamContentSummary>, int>((ref, playerId) {
      final repository = ref.watch(playerDetailRepositoryProvider);
      return TeamPagedController(
        target: '球员动态',
        loader: (page, size) => repository.contents(playerId, page, size),
        itemId: (item) => item.id,
      );
    });
