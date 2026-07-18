import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/app/router/auth_redirect.dart';
import 'package:tifo/core/auth/auth_providers.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/auth/presentation/pages/authenticated_placeholder_page.dart';
import 'package:tifo/features/auth/presentation/pages/login_page.dart';
import 'package:tifo/features/auth/presentation/pages/register_page.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:tifo/shared/widgets/app_entity_avatar.dart';
import 'package:tifo/shared/widgets/app_player_avatar.dart';
import 'package:tifo/shared/widgets/app_team_logo.dart';

void main() {
  testWidgets('login shows brand title and primary action', (tester) async {
    await _pumpPage(tester, const LoginPage());
    expect(find.text('南看台'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });

  testWidgets('login remains usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPage(tester, const LoginPage(), textScale: 1.4);
    await tester.showKeyboard(find.widgetWithText(TextFormField, '密码'));
    await tester.pump();
    expect(find.text('登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register shows all required fields', (tester) async {
    await _pumpPage(tester, const RegisterPage());
    for (final label in ['用户名', '手机号', '密码', '确认密码']) {
      expect(find.widgetWithText(TextFormField, label), findsOneWidget);
    }
    expect(find.text('注册'), findsOneWidget);
  });

  testWidgets('onboarding starts at step one and requires a main team', (
    tester,
  ) async {
    await _pumpOnboarding(tester, _ReadyOnboardingRepository());
    expect(find.text('步骤 1 / 3'), findsOneWidget);
    expect(find.text('选择我的主队'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('three-step selections survive forward and backward navigation', (
    tester,
  ) async {
    await _pumpOnboarding(tester, _ReadyOnboardingRepository());
    await tester.tap(find.byKey(const ValueKey('main_team_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pump();
    expect(find.text('步骤 2 / 3'), findsOneWidget);
    expect(find.textContaining('已选择 1 支'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('follow_team_2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_next')));
    await tester.pump();
    expect(find.text('步骤 3 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_submit')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_previous')));
    await tester.pump();
    expect(find.textContaining('已选择 2 支'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_previous')));
    await tester.pump();
    expect(find.text('步骤 1 / 3'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('main_team_1')),
        matching: find.byKey(const ValueKey('selected')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('onboarding exposes loading, empty, error, and retry states', (
    tester,
  ) async {
    final pending = Completer<OnboardingOptions>();
    await _pumpOnboarding(
      tester,
      _DeferredOnboardingRepository(pending),
      settle: false,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('onboarding_loading')), findsOneWidget);
    pending.complete(const OnboardingOptions(teams: [], players: []));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_empty')), findsOneWidget);

    final failing = _FailingOnboardingRepository();
    await _pumpOnboarding(tester, failing);
    expect(find.byKey(const ValueKey('onboarding_error')), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(failing.loadCount, 2);
  });

  testWidgets('team missing logo and player image failure use placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              AppTeamLogo(identity: 'team:1', name: '南队'),
              AppPlayerAvatar(
                identity: 'player:1',
                name: '阿南',
                imageUrl: 'invalid://avatar',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('南'), findsOneWidget);
    expect(find.text('阿'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('same entity placeholder color is stable', () {
    expect(stableEntityColor('team:42'), stableEntityColor('team:42'));
  });

  testWidgets('Pixel 8 size keeps onboarding actions usable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpOnboarding(tester, _ReadyOnboardingRepository(), textScale: 1.3);
    expect(find.byKey(const ValueKey('onboarding_next')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('presentation pages do not access Dio or secure storage directly', () {
    for (final path in [
      'lib/features/auth/presentation/pages/login_page.dart',
      'lib/features/auth/presentation/pages/register_page.dart',
      'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('package:dio')));
      expect(source, isNot(contains('flutter_secure_storage')));
    }
  });

  test('F03 authentication route decisions remain unchanged', () {
    expect(
      authRedirect(AuthStatus.unauthenticated, '/authenticated'),
      '/login',
    );
    expect(
      authRedirect(AuthStatus.authenticatedNeedsOnboarding, '/login'),
      '/onboarding',
    );
    expect(
      authRedirect(AuthStatus.authenticatedReady, '/onboarding'),
      '/app/home',
    );
  });

  testWidgets('temporary completion page contains no F04 fake data', (
    tester,
  ) async {
    await _pumpPage(tester, const AuthenticatedPlaceholderPage());
    expect(find.text('登录与首次设置已完成'), findsOneWidget);
    expect(find.text('F04 主框架与首页待开发'), findsOneWidget);
    expect(find.textContaining('新闻'), findsNothing);
    expect(find.textContaining('比赛'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  OnboardingRepositoryContract repository, {
  bool settle = true,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
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
  if (settle) await tester.pumpAndSettle();
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  static const user = AuthUser(
    id: 1,
    username: 'supporter',
    nickname: '看台用户',
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

final class _ReadyOnboardingRepository implements OnboardingRepositoryContract {
  @override
  Future<OnboardingOptions> loadOptions() async => const OnboardingOptions(
    teams: [
      TeamOption(id: 1, name: '南城队', followed: false, country: '中国'),
      TeamOption(id: 2, name: '北岸队', followed: false, country: '中国'),
    ],
    players: [
      PlayerOption(
        id: 10,
        name: '阿南',
        followed: false,
        teamId: 1,
        teamName: '南城队',
        position: '前锋',
      ),
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

final class _DeferredOnboardingRepository
    implements OnboardingRepositoryContract {
  _DeferredOnboardingRepository(this.completer);
  final Completer<OnboardingOptions> completer;
  @override
  Future<OnboardingOptions> loadOptions() => completer.future;
  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) => throw UnimplementedError();
}

final class _FailingOnboardingRepository
    implements OnboardingRepositoryContract {
  int loadCount = 0;
  @override
  Future<OnboardingOptions> loadOptions() async {
    loadCount++;
    throw const NetworkException('offline');
  }

  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) => throw UnimplementedError();
}
