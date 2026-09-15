import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/player_detail_models.dart';
import 'package:tifo/features/football/presentation/controllers/team_detail_controllers.dart';

void main() {
  test(
    'PLAYER-07 PLAYER-09 player matches pagination deduplicates and keeps data on append failure',
    () async {
      final controller = TeamPagedController<FootballMatch>(
        target: '球员比赛',
        itemId: (item) => item.id,
        loader: (page, _) async => page == 1
            ? _page(1, [_match(1)], pages: 2)
            : _page(2, [_match(1), _match(2)], pages: 2),
      );
      await controller.loadInitial();
      await controller.loadMore();
      expect(controller.state.records.map((item) => item.id), [1, 2]);

      final failing = TeamPagedController<FootballMatch>(
        target: '球员比赛',
        itemId: (item) => item.id,
        loader: (page, _) async {
          if (page == 1) return _page(1, [_match(1)], pages: 2);
          throw const NetworkException('down');
        },
      );
      await failing.loadInitial();
      await failing.loadMore();
      expect(failing.state.records.single.id, 1);
      expect(failing.state.appendMessage, contains('网络连接失败'));
    },
  );

  test(
    'PLAYER-08 player match sorter keeps dated records before unknown dates',
    () async {
      final controller = TeamPagedController<FootballMatch>(
        target: '球员比赛',
        itemId: (item) => item.id,
        sorter: (records) => records.toList()
          ..sort((a, b) {
            if (a.matchTime == null) return 1;
            if (b.matchTime == null) return -1;
            return a.matchTime!.compareTo(b.matchTime!);
          }),
        loader: (page, _) async =>
            _page(1, [_match(2, null), _match(1, DateTime(2026, 1, 1))]),
      );
      await controller.loadInitial();
      expect(controller.state.records.map((item) => item.id), [1, 2]);
    },
  );

  test(
    'PLAYER-07 PLAYER-17 stale request and refresh failure preserve records',
    () async {
      final first = Completer<FootballPage<FootballMatch>>();
      final second = Completer<FootballPage<FootballMatch>>();
      var calls = 0;
      final controller = TeamPagedController<FootballMatch>(
        target: '球员比赛',
        itemId: (item) => item.id,
        loader: (page, _) {
          calls++;
          if (calls == 1) return first.future;
          if (calls == 2) return second.future;
          throw const NetworkException('refresh');
        },
      );
      final old = controller.loadInitial();
      final latest = controller.loadInitial();
      second.complete(_page(1, [_match(2, null)]));
      await latest;
      first.complete(_page(1, [_match(1, null)]));
      await old;
      expect(controller.state.records.single.id, 2);
      await controller.refresh();
      expect(controller.state.status, TeamPagedStatus.ready);
      expect(controller.state.records.single.id, 2);
      expect(controller.state.message, contains('网络连接失败'));
    },
  );

  test('PLAYER-12 career hasData recognizes every real total field', () {
    expect(const PlayerCareer(totalStarts: 1).hasData, isTrue);
    expect(const PlayerCareer(totalMinutes: 1).hasData, isTrue);
    expect(const PlayerCareer(totalAssists: 0).hasData, isTrue);
    expect(const PlayerCareer(totalYellowCards: 1).hasData, isTrue);
    expect(const PlayerCareer(totalRedCards: 0).hasData, isTrue);
    expect(const PlayerCareer(totalShots: 1).hasData, isTrue);
    expect(const PlayerCareer(totalShotsOnTarget: 1).hasData, isTrue);
    expect(const PlayerCareer(totalSaves: 0).hasData, isTrue);
    expect(const PlayerCareer(teamCount: 0).hasData, isTrue);
    expect(const PlayerCareer(seasonCount: 0).hasData, isTrue);
  });
}

FootballPage<FootballMatch> _page(
  int page,
  List<FootballMatch> records, {
  int pages = 1,
}) => FootballPage(
  records: records,
  pageNum: page,
  pages: pages,
  total: records.length,
);
FootballMatch _match(int id, [DateTime? time]) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '联赛',
  homeTeam: const FootballTeam(id: 40, name: '主队'),
  awayTeam: const FootballTeam(id: 41, name: '客队'),
  status: 'SCHEDULED',
  matchTime: time,
);
