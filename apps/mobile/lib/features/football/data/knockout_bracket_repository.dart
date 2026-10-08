import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/bracket_models.dart';
import 'football_api.dart';

final knockoutBracketProvider = Provider<FootballApi>(
  (ref) => FootballApi(ref.watch(apiClientProvider)),
);

final knockoutBracketFutureProvider =
    FutureProvider.family<List<BracketStage>, (int, int)>(
      (ref, args) => ref
          .watch(knockoutBracketProvider)
          .knockoutBracket(leagueId: args.$1, seasonId: args.$2),
    );
