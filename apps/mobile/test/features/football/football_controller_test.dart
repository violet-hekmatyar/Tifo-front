import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/controllers/football_data_controller.dart';
import 'package:tifo/features/football/presentation/controllers/football_detail_providers.dart';

void main() {
  test(
    'loads leagues and important schedule then switches competition',
    () async {
      final repository = _FootballRepository();
      final controller = FootballDataController(repository);
      await controller.loadInitial();
      expect(controller.state.status, FootballDataStatus.ready);
      expect(controller.state.leagues.single.name, '测试联赛');
      expect(controller.state.matches.single.id, 1);

      await controller.selectSource(const LeagueSource(10));
      expect(controller.state.source, isA<LeagueSource>());
      expect(repository.leagueRequests, [10]);
    },
  );

  test('pagination deduplicates and prevents concurrent loads', () async {
    final next = Completer<FootballPage<FootballMatch>>();
    final repository = _FootballRepository(
      importantPages: {
        1: _page(1, [_match(1)], pages: 2),
      },
      importantDeferred: {2: next},
    );
    final controller = FootballDataController(repository);
    await controller.loadInitial();
    final first = controller.loadMore();
    final ignored = controller.loadMore();
    expect(repository.pageRequests.where((value) => value == 2), hasLength(1));
    next.complete(_page(2, [_match(1), _match(2)], pages: 2));
    await Future.wait([first, ignored]);
    expect(controller.state.matches.map((item) => item.id), [1, 2]);
    expect(controller.state.hasMore, isFalse);
  });

  test('source change ignores a stale response', () async {
    final stale = Completer<FootballPage<FootballMatch>>();
    final repository = _FootballRepository(importantDeferred: {1: stale});
    final controller = FootballDataController(repository);
    final initial = controller.loadInitial();
    repository.importantDeferred.clear();
    repository.leaguePages[1] = _page(1, [_match(9)]);
    await controller.selectSource(const LeagueSource(10));
    stale.complete(_page(1, [_match(8)]));
    await initial;
    expect(controller.state.matches.single.id, 9);
  });

  test('empty, retryable failure, and append failure preserve state', () async {
    final repository = _FootballRepository(importantPages: {1: _page(1, [])});
    final controller = FootballDataController(repository);
    await controller.loadInitial();
    expect(controller.state.status, FootballDataStatus.empty);
    repository
      ..error = const NetworkException('down')
      ..importantPages[1] = _page(1, [_match(1)], pages: 2);
    await controller.loadInitial();
    expect(controller.state.status, FootballDataStatus.failure);
    expect(controller.state.message, contains('网络连接失败'));
    repository.error = null;
    await controller.loadInitial();
    repository.error = const TimeoutException('slow');
    await controller.loadMore();
    expect(controller.state.matches.single.id, 1);
    expect(controller.state.appendMessage, contains('请求超时'));
  });

  test(
    'team schedule paginates and keeps old data on append failure',
    () async {
      final repository = _FootballRepository(
        teamPages: {
          1: _page(1, [_match(1)], pages: 2),
        },
      );
      final controller = TeamScheduleController(repository, teamId: 3);
      await controller.loadInitial();
      expect(controller.state.status, TeamScheduleStatus.ready);
      repository.error = const NetworkException('down');
      await controller.loadMore();
      expect(controller.state.matches.single.id, 1);
      expect(controller.state.appendMessage, 'down');
    },
  );

  test('all sources sort and stale pagination cannot cross filters', () async {
    final stalePage = Completer<FootballPage<FootballMatch>>();
    final unsorted = _page(1, [
      _matchAt(1, 'FINISHED', DateTime(2026, 7, 10)),
      _matchAt(2, 'SCHEDULED', DateTime(2026, 7, 20)),
      _matchAt(3, 'LIVE', DateTime(2026, 7, 13)),
    ], pages: 2);
    final repository = _FootballRepository(
      importantPages: {1: unsorted},
      importantDeferred: {2: stalePage},
      followingPages: {1: unsorted},
    );
    repository.leaguePages[1] = unsorted;
    final controller = FootballDataController(repository);
    await controller.loadInitial();
    expect(controller.state.matches.map((item) => item.id), [3, 2, 1]);

    final staleLoad = controller.loadMore();
    await controller.selectSource(const FollowingSource());
    expect(controller.state.matches.map((item) => item.id), [3, 2, 1]);
    stalePage.complete(_page(2, [_match(99)], pages: 2));
    await staleLoad;
    expect(controller.state.matches.map((item) => item.id), [3, 2, 1]);

    await controller.selectSource(const LeagueSource(10));
    expect(controller.state.matches.map((item) => item.id), [3, 2, 1]);
  });
}

final class _FootballRepository implements FootballRepositoryContract {
  _FootballRepository({
    Map<int, FootballPage<FootballMatch>>? importantPages,
    Map<int, Completer<FootballPage<FootballMatch>>>? importantDeferred,
    Map<int, FootballPage<FootballMatch>>? teamPages,
    Map<int, FootballPage<FootballMatch>>? followingPages,
  }) : importantPages =
           importantPages ??
           {
             1: _page(1, [_match(1)]),
           },
       importantDeferred = importantDeferred ?? {},
       teamPages = teamPages ?? {},
       followingPages = followingPages ?? {};

  final Map<int, FootballPage<FootballMatch>> importantPages;
  final Map<int, Completer<FootballPage<FootballMatch>>> importantDeferred;
  final Map<int, FootballPage<FootballMatch>> leaguePages = {};
  final Map<int, FootballPage<FootballMatch>> teamPages;
  final Map<int, FootballPage<FootballMatch>> followingPages;
  final List<int> pageRequests = [];
  final List<int> leagueRequests = [];
  AppNetworkException? error;

  Future<FootballPage<FootballMatch>> _result(
    int page,
    Map<int, FootballPage<FootballMatch>> pages,
  ) async {
    pageRequests.add(page);
    if (error case final value?) throw value;
    if (importantDeferred[page] case final value?) return value.future;
    return pages[page] ?? _page(page, []);
  }

  @override
  Future<List<League>> leagues() async => const [League(id: 10, name: '测试联赛')];
  @override
  Future<FootballPage<FootballMatch>> importantMatches(int page, int size) =>
      _result(page, importantPages);
  @override
  Future<FootballPage<FootballMatch>> followingMatches(int page, int size) =>
      _result(page, followingPages.isEmpty ? importantPages : followingPages);
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) {
    leagueRequests.add(id);
    return _result(page, leaguePages.isEmpty ? importantPages : leaguePages);
  }

  @override
  Future<FootballPage<FootballMatch>> teamMatches(int id, int page, int size) =>
      _result(page, teamPages);
  @override
  Future<MatchDetail> matchDetail(int id) => throw UnimplementedError();
  @override
  Future<TeamDetail> teamDetail(int id) => throw UnimplementedError();
  @override
  Future<PlayerDetail> playerDetail(int id) => throw UnimplementedError();
}

FootballPage<FootballMatch> _page(
  int page,
  List<FootballMatch> matches, {
  int pages = 1,
}) => FootballPage(
  records: matches,
  pageNum: page,
  pages: pages,
  total: matches.length,
);

FootballMatch _match(int id) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 1, name: '主队'),
  awayTeam: const FootballTeam(id: 2, name: '客队'),
  status: 'SCHEDULED',
  matchTime: DateTime(2026, 7, 18, 20),
);

FootballMatch _matchAt(int id, String status, DateTime time) => FootballMatch(
  id: id,
  leagueId: 10,
  leagueName: '测试联赛',
  homeTeam: const FootballTeam(id: 1, name: '主队'),
  awayTeam: const FootballTeam(id: 2, name: '客队'),
  status: status,
  matchTime: time,
);
