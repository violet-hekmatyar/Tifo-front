import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/football/data/football_repository.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/presentation/controllers/football_data_controller.dart';
import 'package:tifo/features/football/presentation/pages/football_data_page.dart';
import 'package:tifo/features/football/presentation/pages/match_detail_page.dart';
import 'package:tifo/features/football/presentation/pages/player_detail_page.dart';
import 'package:tifo/features/football/presentation/pages/team_detail_page.dart';
import 'package:tifo/features/football/presentation/widgets/football_widgets.dart';

void main() {
  testWidgets('data page replaces placeholder and renders sources and dates', (
    tester,
  ) async {
    final repository = _WidgetFootballRepository();
    final controller = FootballDataController(repository);
    await _pumpData(tester, repository, controller);
    await tester.pumpAndSettle();
    expect(find.text('数据'), findsOneWidget);
    expect(find.text('重要'), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    expect(find.text('测试联赛'), findsWidgets);
    expect(find.text('2026-07-18'), findsOneWidget);
    expect(find.text('足球数据入口已建立'), findsNothing);

    await tester.tap(find.text('测试联赛').first);
    await tester.pumpAndSettle();
    expect(repository.leagueLoads, 1);
  });

  testWidgets('data page exposes loading, empty and retry states', (
    tester,
  ) async {
    final pending = Completer<FootballPage<FootballMatch>>();
    final repository = _WidgetFootballRepository(pendingImportant: pending);
    final controller = FootballDataController(repository);
    await _pumpData(tester, repository, controller);
    await tester.pump();
    expect(find.text('正在加载赛程'), findsOneWidget);
    pending.complete(_page([]));
    await tester.pumpAndSettle();
    expect(find.text('暂无比赛'), findsOneWidget);

    repository.error = const NetworkException('down');
    await controller.loadInitial();
    await tester.pump();
    expect(find.text('赛程加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('scroll loads page two, retries once, and shows final footer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _PagedWidgetRepository();
    final controller = FootballDataController(repository);
    await _pumpData(tester, repository, controller);
    await tester.pumpAndSettle();
    expect(controller.state.hasMore, isTrue);
    await tester.drag(
      find.byKey(const PageStorageKey('football_data_list')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('点击重试'), findsOneWidget);
    expect(controller.state.matches, hasLength(2));
    await tester.tap(find.textContaining('点击重试'));
    await tester.pumpAndSettle();
    expect(repository.pageTwoRequests, 2);
    expect(controller.state.matches, hasLength(4));
    await tester.drag(
      find.byKey(const PageStorageKey('football_data_list')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('已经到底了'), findsOneWidget);
  });

  testWidgets('match cards map statuses and never invent a score', (
    tester,
  ) async {
    for (final entry in {
      'SCHEDULED': '未开始',
      'LIVE': '进行中',
      'FINISHED': '已结束',
      'POSTPONED': '已延期',
      'ABANDONED': 'ABANDONED',
    }.entries) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_configOverride],
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleMatchCard(match: _match(status: entry.key)),
            ),
          ),
        ),
      );
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.textContaining('0 : 0'), findsNothing);
    }
  });

  testWidgets('match detail shows events, report and unsupported empty tabs', (
    tester,
  ) async {
    final repository = _WidgetFootballRepository();
    await _pumpRouter(tester, repository, '/matches/50001');
    expect(find.text('主队'), findsOneWidget);
    expect(find.text('客队'), findsOneWidget);
    expect(find.text('进球 · 1:0'), findsOneWidget);
    expect(find.text('UNKNOWN_EVENT'), findsOneWidget);
    expect(find.text('测试战报'), findsOneWidget);
    await tester.tap(find.text('阵容'));
    await tester.pump();
    expect(find.text('暂无比赛阵容'), findsOneWidget);
    await tester.tap(find.text('排名'));
    await tester.pump();
    expect(find.text('暂无联赛排名'), findsOneWidget);
    await tester.tap(find.text('数据'));
    await tester.pump();
    expect(find.text('暂无比赛统计'), findsOneWidget);
  });

  testWidgets('team detail uses real fields and keeps selected tab', (
    tester,
  ) async {
    final repository = _WidgetFootballRepository();
    await _pumpRouter(tester, repository, '/teams/30001');
    expect(find.text('测试球队'), findsOneWidget);
    expect(find.text('测试球场'), findsOneWidget);
    expect(find.text('虚构荣誉'), findsNothing);
    await tester.tap(find.text('阵容'));
    await tester.pump();
    expect(find.text('暂无球队阵容'), findsOneWidget);
    await tester.tap(find.text('数据'));
    await tester.pump();
    expect(find.text('暂无球队统计'), findsOneWidget);
    await tester.tap(find.text('阵容'));
    await tester.pump();
    expect(find.text('暂无球队阵容'), findsOneWidget);
  });

  testWidgets('player detail shows retirement and navigates to current team', (
    tester,
  ) async {
    final repository = _WidgetFootballRepository();
    await _pumpRouter(tester, repository, '/players/40001');
    expect(find.text('测试球员'), findsOneWidget);
    expect(find.textContaining('已退役'), findsWidgets);
    expect(find.text('当前球队'), findsOneWidget);
    await tester.tap(find.text('测试球队').last);
    await tester.pumpAndSettle();
    expect(find.byType(TeamDetailPage), findsOneWidget);
  });

  testWidgets('404 detail is distinct from retryable errors', (tester) async {
    final repository = _WidgetFootballRepository(
      detailError: const BusinessException('missing', code: 40401),
    );
    await _pumpRouter(tester, repository, '/players/-1');
    expect(find.text('球员不存在'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('core details remain usable at Pixel 8 and 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _WidgetFootballRepository();
    await _pumpRouter(tester, repository, '/matches/50001', textScale: 1.4);
    expect(tester.takeException(), isNull);
  });
}

final _configOverride = appConfigProvider.overrideWithValue(
  AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
);

Future<void> _pumpData(
  WidgetTester tester,
  FootballRepositoryContract repository,
  FootballDataController controller,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      _configOverride,
      footballRepositoryProvider.overrideWithValue(repository),
      footballDataControllerProvider.overrideWith((_) => controller),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const FootballDataPage()),
  ),
);

Future<void> _pumpRouter(
  WidgetTester tester,
  _WidgetFootballRepository repository,
  String location, {
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/app/data', builder: (_, _) => const Text('数据入口')),
      GoRoute(
        path: '/matches/:id',
        builder: (_, state) =>
            MatchDetailPage(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/teams/:id',
        builder: (_, state) =>
            TeamDetailPage(teamId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (_, state) =>
            PlayerDetailPage(playerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/contents/:id', builder: (_, _) => const Text('战报详情')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _configOverride,
        footballRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _WidgetFootballRepository implements FootballRepositoryContract {
  _WidgetFootballRepository({this.pendingImportant, this.detailError});
  final Completer<FootballPage<FootballMatch>>? pendingImportant;
  final AppNetworkException? detailError;
  AppNetworkException? error;
  int leagueLoads = 0;

  void _checkDetail() {
    if (detailError case final value?) throw value;
  }

  @override
  Future<List<League>> leagues() async => const [
    League(id: 10003, name: '测试联赛'),
  ];
  @override
  Future<FootballPage<FootballMatch>> importantMatches(int page, int size) {
    if (error case final value?) throw value;
    if (pendingImportant case final value?) return value.future;
    return Future.value(_page([_match()]));
  }

  @override
  Future<FootballPage<FootballMatch>> followingMatches(int page, int size) =>
      importantMatches(page, size);
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) {
    leagueLoads++;
    return importantMatches(page, size);
  }

  @override
  Future<FootballPage<FootballMatch>> teamMatches(
    int id,
    int page,
    int size,
  ) async => _page([_match()]);
  @override
  Future<MatchDetail> matchDetail(int id) async {
    _checkDetail();
    return MatchDetail(
      match: _match(status: 'FINISHED', scores: true),
      venue: '测试球场',
      events: const [
        MatchEvent(
          id: 1,
          type: 'GOAL',
          minute: 12,
          playerId: 40001,
          playerName: '测试球员',
          scoreAfter: '1:0',
        ),
        MatchEvent(id: 2, type: 'UNKNOWN_EVENT', minute: 20),
      ],
      report: const MatchReport(contentId: 20004, title: '测试战报'),
    );
  }

  @override
  Future<TeamDetail> teamDetail(int id) async {
    _checkDetail();
    return TeamDetail(
      id: 30001,
      name: '测试球队',
      country: '中国',
      stadiumName: '测试球场',
      followed: true,
      followerCount: 8,
      recentMatches: const [],
      upcomingMatches: [_match()],
    );
  }

  @override
  Future<PlayerDetail> playerDetail(int id) async {
    _checkDetail();
    return const PlayerDetail(
      id: 40001,
      name: '测试球员',
      position: '前锋',
      nationality: '中国',
      retired: true,
      followed: false,
      followerCount: 3,
      team: PlayerTeam(id: 30001, name: '测试球队'),
    );
  }
}

final class _PagedWidgetRepository implements FootballRepositoryContract {
  int pageTwoRequests = 0;

  FootballPage<FootballMatch> _result(int page) {
    if (page == 1) {
      return FootballPage(
        records: [
          _matchWithId(1, 'FINISHED', DateTime(2026, 7, 10)),
          _matchWithId(2, 'SCHEDULED', DateTime(2026, 7, 20)),
        ],
        pageNum: 1,
        pages: 2,
        total: 4,
      );
    }
    pageTwoRequests++;
    if (pageTwoRequests == 1) throw const NetworkException('第二页加载失败');
    return FootballPage(
      records: [
        _matchWithId(3, 'LIVE', DateTime(2026, 7, 13)),
        _matchWithId(4, 'FINISHED', DateTime(2026, 7, 8)),
      ],
      pageNum: 2,
      pages: 2,
      total: 4,
    );
  }

  @override
  Future<List<League>> leagues() async => const [
    League(id: 10003, name: '测试联赛'),
  ];
  @override
  Future<FootballPage<FootballMatch>> importantMatches(
    int page,
    int size,
  ) async => _result(page);
  @override
  Future<FootballPage<FootballMatch>> followingMatches(
    int page,
    int size,
  ) async => _result(page);
  @override
  Future<FootballPage<FootballMatch>> leagueMatches(
    int id,
    int page,
    int size,
  ) async => _result(page);
  @override
  Future<FootballPage<FootballMatch>> teamMatches(
    int id,
    int page,
    int size,
  ) async => _result(page);
  @override
  Future<MatchDetail> matchDetail(int id) => throw UnimplementedError();
  @override
  Future<TeamDetail> teamDetail(int id) => throw UnimplementedError();
  @override
  Future<PlayerDetail> playerDetail(int id) => throw UnimplementedError();
}

FootballPage<FootballMatch> _page(List<FootballMatch> matches) =>
    FootballPage(records: matches, pageNum: 1, pages: 1, total: matches.length);

FootballMatch _match({String status = 'SCHEDULED', bool scores = false}) =>
    FootballMatch(
      id: 50001,
      leagueId: 10003,
      leagueName: '测试联赛',
      homeTeam: FootballTeam(id: 30001, name: '主队', score: scores ? 1 : null),
      awayTeam: FootballTeam(id: 30002, name: '客队', score: scores ? 0 : null),
      status: status,
      matchTime: DateTime(2026, 7, 18, 20),
    );

FootballMatch _matchWithId(int id, String status, DateTime time) =>
    FootballMatch(
      id: id,
      leagueId: 10003,
      leagueName: '测试联赛',
      homeTeam: const FootballTeam(id: 30001, name: '主队'),
      awayTeam: const FootballTeam(id: 30002, name: '客队'),
      status: status,
      matchTime: time,
    );
