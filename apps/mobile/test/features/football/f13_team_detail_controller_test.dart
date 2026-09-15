import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/controllers/team_detail_controllers.dart';

void main() {
  test(
    'TEAM-08 TEAM-10 TEAM-14 pagination deduplicates and retries append errors',
    () async {
      var failSecond = false;
      var secondCalls = 0;
      final controller = TeamPagedController<FootballMatch>(
        target: '球队赛程',
        itemId: (item) => item.id,
        loader: (page, _) async {
          if (page == 1) return _page(1, [_match(1)], pages: 2);
          secondCalls++;
          if (failSecond) throw const NetworkException('down');
          return _page(2, [_match(1), _match(2)], pages: 2);
        },
      );

      await controller.loadInitial();
      await controller.loadMore();
      expect(controller.state.records.map((item) => item.id), [1, 2]);
      expect(controller.state.hasMore, isFalse);

      final failing = TeamPagedController<FootballMatch>(
        target: '球队赛程',
        itemId: (item) => item.id,
        loader: (page, _) async {
          if (page == 1) return _page(1, [_match(1)], pages: 2);
          failSecond = true;
          throw const NetworkException('down');
        },
      );
      await failing.loadInitial();
      await failing.loadMore();
      expect(failing.state.records.single.id, 1);
      expect(failing.state.appendMessage, contains('网络连接失败'));
      expect(secondCalls, 1);
    },
  );

  test(
    'TEAM-12 stale initial response cannot replace the latest request',
    () async {
      final first = Completer<FootballPage<FootballMatch>>();
      final second = Completer<FootballPage<FootballMatch>>();
      var calls = 0;
      final controller = TeamPagedController<FootballMatch>(
        target: '球队赛程',
        itemId: (item) => item.id,
        loader: (page, _) {
          calls++;
          return calls == 1 ? first.future : second.future;
        },
      );

      final oldRequest = controller.loadInitial();
      final latestRequest = controller.loadInitial();
      second.complete(_page(1, [_match(2)]));
      await latestRequest;
      first.complete(_page(1, [_match(1)]));
      await oldRequest;

      expect(controller.state.records.single.id, 2);
    },
  );

  test(
    'TEAM-14 refresh failure keeps loaded records and exposes retry message',
    () async {
      var refresh = false;
      final controller = TeamPagedController<FootballMatch>(
        target: '球队赛程',
        itemId: (item) => item.id,
        loader: (page, _) async {
          if (refresh) {
            throw const BusinessException(
              'temporary',
              code: 40001,
              traceId: null,
            );
          }
          return _page(1, [_match(1)]);
        },
      );

      await controller.loadInitial();
      refresh = true;
      await controller.refresh();

      expect(controller.state.status, TeamPagedStatus.ready);
      expect(controller.state.records.single.id, 1);
      expect(controller.state.message, contains('temporary'));
    },
  );
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

FootballMatch _match(int id) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '联赛',
  homeTeam: const FootballTeam(id: 40, name: '主队'),
  awayTeam: const FootballTeam(id: 41, name: '客队'),
  status: 'SCHEDULED',
);
