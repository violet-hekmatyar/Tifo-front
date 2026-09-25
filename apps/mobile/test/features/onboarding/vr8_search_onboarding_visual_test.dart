import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/auth/auth_providers.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets('VR8 onboarding removes legacy banner and step block', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.text('南看台 · 首次设置'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding_step_indicator')),
      findsNothing,
    );
    expect(find.text('搜索结果'), findsOneWidget);
    final header = tester.getRect(
      find.byKey(const ValueKey('onboarding_green_header')),
    );
    final panel = tester.getRect(
      find.byKey(const ValueKey('onboarding_results_panel')),
    );
    final actions = tester.getRect(
      find.byKey(const ValueKey('onboarding_bottom_actions')),
    );
    expect(header.bottom, closeTo(panel.top, 1));
    expect(actions.bottom, lessThanOrEqualTo(915));
  });

  testWidgets('VR8 main team is required and automatically followed', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding_selection_message')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('main_team_1')));
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('follow_team_1')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
  });

  testWidgets('VR8 local empty keeps the fixed action reachable', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_main_team_search')),
      '不存在的球队',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding_local_empty')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboarding_next')), findsOneWidget);
  });

  testWidgets('VR8 back preserves team search and selection state', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.byKey(const ValueKey('main_team_1')));
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_team_search')),
      '北',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('我的主队'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('main_team_1')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('onboarding_main_team_search')),
          )
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('VR8 360dp and 140 percent text keeps controls in bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpOnboarding(tester, textScale: 1.4);
    final search = tester.getRect(
      find.byKey(const ValueKey('onboarding_main_team_search')),
    );
    final actions = tester.getRect(
      find.byKey(const ValueKey('onboarding_bottom_actions')),
    );
    expect(search.right, lessThanOrEqualTo(360));
    expect(actions.right, lessThanOrEqualTo(360));
    expect(actions.bottom, lessThanOrEqualTo(915));
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR8-R1 onboarding results use prototype geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpOnboarding(tester);

    final header = tester.getRect(
      find.byKey(const ValueKey('onboarding_green_header')),
    );
    final panel = tester.getRect(
      find.byKey(const ValueKey('onboarding_results_panel')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('onboarding_results_title')),
    );
    final card = tester.getRect(find.byKey(const ValueKey('main_team_1')));
    final actions = tester.getRect(
      find.byKey(const ValueKey('onboarding_bottom_actions')),
    );
    // Prototype coordinates are measured from the content panel, not from
    // the device status bar. The first-card body has its own key so margin
    // and the inter-card rhythm are tested independently.
    expect(header.bottom - panel.top, closeTo(0, 1));
    expect(title.left - panel.left, closeTo(24, 24 * .08));
    final cardBody = tester.getRect(
      find.byKey(const ValueKey('main_team_1_body')),
    );
    expect(card.top - panel.top, closeTo(48.48, 48.48 * .08));
    expect(cardBody.height, closeTo(60.96, 60.96 * .08));
    final secondCardBody = tester.getRect(
      find.byKey(const ValueKey('main_team_2_body')),
    );
    expect(secondCardBody.top - cardBody.bottom, closeTo(38.88, 38.88 * .08));
    expect(actions.height, closeTo(72, 72 * .08));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding_bottom_actions')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  testWidgets('VR8-R1 onboarding action labels stay single line at 140%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpOnboarding(tester, textScale: 1.4);
    await tester.tap(find.byKey(const ValueKey('main_team_1')));
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();
    final previous = tester.getRect(
      find.byKey(const ValueKey('onboarding_previous')),
    );
    final next = tester.getRect(find.byKey(const ValueKey('onboarding_next')));
    expect(previous.bottom, lessThanOrEqualTo(915));
    expect(next.bottom, lessThanOrEqualTo(915));
    expect(find.text('上一步'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  final repository = _OnboardingRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        onboardingRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const OnboardingPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _OnboardingRepository implements OnboardingRepositoryContract {
  @override
  Future<OnboardingOptions> loadOptions() async => const OnboardingOptions(
    teams: [
      TeamOption(id: 1, name: '南城队', leagueName: 'League 1', followed: false),
      TeamOption(id: 2, name: '北岸队', leagueName: 'League 2', followed: false),
    ],
    players: [
      PlayerOption(id: 10, name: '阿南', teamName: '南城队', followed: false),
    ],
  );

  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) async => SavedPreferences(
    completed: true,
    mainTeamId: mainTeamId,
    followTeamCount: followTeamIds.length,
    followPlayerCount: followPlayerIds.length,
  );
}

final class _AuthRepository implements AuthRepositoryContract {
  @override
  Future<AuthUser> currentUser() async => const AuthUser(
    id: 1,
    username: 'vr8-test',
    roleType: 'USER',
    status: 'ACTIVE',
    onboardingCompleted: false,
  );

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => currentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => currentUser();

  @override
  Future<AuthUser> restore() async => currentUser();

  @override
  Future<String?> storedToken() async => null;
}
