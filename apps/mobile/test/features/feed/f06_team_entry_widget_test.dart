import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/feed/domain/feed_page.dart';
import 'package:tifo/features/feed/presentation/controllers/feed_controller.dart';
import 'package:tifo/features/feed/presentation/pages/home_feed_page.dart';
import 'package:tifo/features/feed/presentation/widgets/followed_team_bar.dart';

void main() {
  testWidgets(
    'team tile is the only detail target and all remains a feed filter',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      int? selectedTeam = 99;
      int? openedTeam;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: Scaffold(
                body: FollowedTeamBar(
                  teams: const [FollowedTeam(teamId: 7, teamName: '主队')],
                  selectedTeamId: selectedTeam,
                  onSelected: (value) => selectedTeam = value,
                  onOpenTeam: (value) => openedTeam = value,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.bySemanticsLabel(RegExp('查看 主队 详情')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('followed_team_7')));
      await tester.pump();
      expect(openedTeam, 7);
      expect(selectedTeam, 99);

      await tester.tap(find.text('全部'));
      await tester.pump();
      expect(selectedTeam, isNull);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('invalid team id is disabled and never navigates', (
    tester,
  ) async {
    int? openedTeam;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FollowedTeamBar(
              teams: const [FollowedTeam(teamId: -1, teamName: '未知球队')],
              selectedTeamId: null,
              onSelected: (_) {},
              onOpenTeam: (value) => openedTeam = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('followed_team_-1')));
    await tester.pump();
    expect(openedTeam, isNull);
  });

  testWidgets('team detail push and pop preserves feed state and scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _TrackingRepository();
    final controller = FeedController(repository);
    await controller.loadInitial();
    await controller.selectFilter(FeedFilter.news);
    await controller.selectTeam(7);
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        GoRoute(path: '/app/home', builder: (_, _) => const HomeFeedPage()),
        GoRoute(
          path: '/teams/:teamId',
          builder: (_, state) => Text('球队 ${state.pathParameters['teamId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedControllerProvider.overrideWith((_) => controller),
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(apiBaseUrl: 'http://localhost:8080'),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    final offsetBefore = scrollView.controller!.offset;
    final requestsBefore = repository.requests.length;

    await tester.tap(find.byKey(const ValueKey('followed_team_7')));
    await tester.pumpAndSettle();
    expect(find.text('球队 7'), findsOneWidget);
    expect(repository.requests.length, requestsBefore);
    expect(controller.state.filter, FeedFilter.news);
    expect(controller.state.teamId, 7);

    router.pop();
    await tester.pumpAndSettle();
    expect(controller.state.filter, FeedFilter.news);
    expect(controller.state.teamId, 7);
    expect(
      tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!
          .offset,
      offsetBefore,
    );
  });
}

final class _TrackingRepository implements FeedRepositoryContract {
  final requests = <(FeedFilter, int?, int)>[];

  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async {
    requests.add((filter, teamId, pageNum));
    return FeedPage(
      cards: [
        for (var index = 0; index < 12; index++)
          ContentFeedCard(
            cardId: 'content-$index',
            rawCardType: 'CONTENT',
            contentId: index,
            contentType: 'POST',
            title: '资讯 $index',
            author: const FeedAuthor(userId: 1, nickname: '作者'),
            likeCount: 0,
            commentCount: 0,
          ),
      ],
      total: 12,
      pageNum: 1,
      pageSize: pageSize,
      pages: 1,
    );
  }

  @override
  Future<List<FollowedTeam>> loadFollowedTeams() async => const [
    FollowedTeam(teamId: 7, teamName: '主队'),
  ];
}
