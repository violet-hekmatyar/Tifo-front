import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/controllers/team_detail_controllers.dart';

void main() {
  test('team tab pagination deduplicates and reports append errors', () async {
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

FootballMatch _match(int id) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '联赛',
  homeTeam: const FootballTeam(id: 40, name: '主队'),
  awayTeam: const FootballTeam(id: 41, name: '客队'),
  status: 'SCHEDULED',
);
