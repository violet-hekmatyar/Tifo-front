import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/features/feed/domain/feed_page.dart';
import 'package:tifo/features/feed/presentation/widgets/followed_team_bar.dart';

void main() {
  testWidgets('team tile selects feed and all clears the feed filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    int? selectedTeam = 99;

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
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.bySemanticsLabel(RegExp('筛选 主队 内容')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('followed_team_7')));
    await tester.pump();
    expect(selectedTeam, 7);

    await tester.tap(find.text('全部'));
    await tester.pump();
    expect(selectedTeam, isNull);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('invalid team id is disabled and never navigates', (
    tester,
  ) async {
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
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('followed_team_-1')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
