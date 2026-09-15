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
  testWidgets('SEA-10 main team blocks next and auto-enters followed teams', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding_selection_message')),
      findsOneWidget,
    );
    expect(find.text('选择我的主队'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main_team_1')));
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.text('关注球队'), findsOneWidget);
    expect(find.textContaining('当前已选择 1 支'), findsOneWidget);
  });

  testWidgets(
    'SEA-11 local team and player filters keep selections across steps',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_team_search')),
        '北',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('follow_team_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('follow_team_1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('follow_team_2')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_player_search')),
        '阿',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('player_10')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_previous')));
      await tester.pumpAndSettle();
      expect(find.text('关注球队'), findsOneWidget);
    },
  );

  testWidgets(
    'SEA-13 onboarding is usable at 412px with safe area and 1.4x text',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, textScale: 1.4);
      expect(find.byKey(const ValueKey('onboarding_next')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        onboardingRepositoryProvider.overrideWithValue(_OnboardingRepository()),
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
      TeamOption(id: 1, name: '南城队', followed: false),
      TeamOption(id: 2, name: '北岸队', followed: false),
    ],
    players: [
      PlayerOption(id: 10, name: '阿南', followed: false, teamName: '南城队'),
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
  static const user = AuthUser(
    id: 1,
    username: 'onboarding-test',
    roleType: 'USER',
    status: 'ACTIVE',
    onboardingCompleted: false,
  );

  @override
  Future<AuthUser> currentUser() async => user;
  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async => user;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => user;
  @override
  Future<AuthUser> restore() async => user;
  @override
  Future<String?> storedToken() async => null;
}
