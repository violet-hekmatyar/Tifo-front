import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/controllers/team_detail_controllers.dart';

void main() {
  test(
    'player matches pagination deduplicates and keeps data on append failure',
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
