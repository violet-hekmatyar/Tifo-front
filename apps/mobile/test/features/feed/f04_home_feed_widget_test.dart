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
import 'package:tifo/features/feed/presentation/widgets/content_card.dart';
import 'package:tifo/features/feed/presentation/widgets/match_card.dart';
import 'package:tifo/features/feed/presentation/widgets/unknown_card.dart';
import 'package:tifo/features/main_shell/presentation/main_shell_page.dart';

void main() {
  testWidgets('home renders real mixed feed controls and cards', (
    tester,
  ) async {
    final repository = _WidgetRepository();
    final controller = FeedController(repository);
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        GoRoute(path: '/app/home', builder: (_, _) => const HomeFeedPage()),
        for (final path in ['/search', '/publish'])
          GoRoute(path: path, builder: (_, _) => Text(path)),
        GoRoute(path: '/content/:id', builder: (_, _) => const Text('内容详情')),
        GoRoute(path: '/match/:id', builder: (_, _) => const Text('比赛详情')),
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

    expect(find.text('南看台'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_search')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_publish')), findsOneWidget);
    for (final label in ['推荐', '资讯', '关注']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('followed_team_7')), findsOneWidget);
    expect(find.byType(ContentCard), findsNWidgets(2));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(MatchCard), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.byType(UnknownCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'content title is capped and missing image uses neutral fallback',
    (tester) async {
      final card = _content('one', title: '很长的标题' * 20);
      await _pumpWidget(
        tester,
        SizedBox(
          width: 180,
          child: ContentCard(card: card, onTap: () {}),
        ),
      );
      final title = tester.widget<Text>(find.text(card.title));
      expect(title.maxLines, 2);
      expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
      expect(find.text('帖子'), findsOneWidget);
    },
  );

  testWidgets('content without hot comment leaves no synthetic comment block', (
    tester,
  ) async {
    await _pumpWidget(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          child: ContentCard(card: _content('plain'), onTap: () {}),
        ),
      ),
    );
    expect(find.text('热门评论'), findsNothing);
    expect(find.byType(ContentCard), findsOneWidget);
  });

  for (final entry in {
    'LIVE': '进行中',
    'FINISHED': '已结束',
    'SCHEDULED': '未开始',
  }.entries) {
    testWidgets('match maps ${entry.key} to ${entry.value}', (tester) async {
      await _pumpWidget(
        tester,
        MatchCard(
          card: _match(status: entry.key),
          onTap: () {},
        ),
      );
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets(
    'scheduled match without score shows time rather than fake score',
    (tester) async {
      await _pumpWidget(
        tester,
        MatchCard(
          card: _match(status: 'SCHEDULED'),
          onTap: () {},
        ),
      );
      expect(find.text('07-17 20:00'), findsOneWidget);
      expect(find.textContaining('0 : 0'), findsNothing);
    },
  );

  testWidgets('unknown card is isolated and readable', (tester) async {
    await _pumpWidget(
      tester,
      const UnknownCard(
        card: UnknownFeedCard(cardId: 'x', rawCardType: 'POLL'),
      ),
    );
    expect(find.text('该卡片类型暂未支持'), findsOneWidget);
    expect(find.text('POLL'), findsOneWidget);
  });

  testWidgets('four-tab shell preserves branch state', (tester) async {
    final router = GoRouter(
      initialLocation: '/app/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainShellPage(navigationShell: shell),
          branches: [
            for (var index = 0; index < 4; index++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: [
                      '/app/home',
                      '/app/data',
                      '/app/messages',
                      '/app/profile',
                    ][index],
                    builder: (_, _) => _BranchPage(index: index),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (final label in ['首页', '数据', '消息', '我的']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('branch_button_0')));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);
    await tester.tap(find.text('数据'));
    await tester.pumpAndSettle();
    expect(find.text('branch 1'), findsOneWidget);
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget);
  });

  testWidgets('home controls remain usable at Pixel 8 width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpWidget(
      tester,
      const Row(
        children: [
          Expanded(child: Text('南看台')),
          IconButton(onPressed: null, icon: Icon(Icons.search)),
          FilledButton(onPressed: null, child: Text('发布')),
        ],
      ),
      textScale: 1.4,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpWidget(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: child),
    ),
  ),
);

final class _WidgetRepository implements FeedRepositoryContract {
  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) async => FeedPage(
    cards: [
      _content('first'),
      _content('second'),
      _match(status: 'LIVE'),
      const UnknownFeedCard(cardId: 'unknown', rawCardType: 'POLL'),
    ],
    total: 4,
    pageNum: 1,
    pageSize: 10,
    pages: 1,
  );

  @override
  Future<List<FollowedTeam>> loadFollowedTeams() async => const [
    FollowedTeam(teamId: 7, teamName: '主队'),
  ];
}

ContentFeedCard _content(String id, {String? title}) => ContentFeedCard(
  cardId: id,
  rawCardType: 'CONTENT',
  contentId: id.hashCode,
  contentType: 'POST',
  title: title ?? '真实内容 $id',
  author: const FeedAuthor(userId: 1, nickname: '作者'),
  likeCount: 2,
  commentCount: 1,
);

MatchFeedCard _match({required String status}) => MatchFeedCard(
  cardId: 'match-$status',
  rawCardType: 'MATCH',
  matchId: 9,
  leagueName: '测试联赛',
  homeTeam: const FeedTeam(teamId: 1, teamName: '主队'),
  awayTeam: const FeedTeam(teamId: 2, teamName: '客队'),
  matchStatus: status,
  matchTime: DateTime(2026, 7, 17, 20),
);

class _BranchPage extends StatefulWidget {
  const _BranchPage({required this.index});
  final int index;

  @override
  State<_BranchPage> createState() => _BranchPageState();
}

class _BranchPageState extends State<_BranchPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('branch ${widget.index}'),
        Text('count $count'),
        FilledButton(
          key: ValueKey('branch_button_${widget.index}'),
          onPressed: () => setState(() => count++),
          child: const Text('increase'),
        ),
      ],
    ),
  );
}
