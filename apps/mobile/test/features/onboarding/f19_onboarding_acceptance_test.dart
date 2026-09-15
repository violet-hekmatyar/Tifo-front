import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/auth/auth_providers.dart';
import 'package:tifo/app/router/auth_redirect.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:tifo/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  test(
    'ONB-06/07 options loading is deduped and retry wins over stale response',
    () async {
      final old = Completer<OnboardingOptions>();
      final newest = Completer<OnboardingOptions>();
      final repository = _OnboardingRepository(pending: [old, newest]);
      final controller = _controller(repository);
      final first = controller.load();
      expect(repository.loadCalls, 1);
      expect(controller.state.status, OnboardingLoadStatus.loading);

      final retry = controller.retry();
      expect(repository.loadCalls, 2);
      newest.complete(_options(teamCount: 2));
      await retry;
      old.complete(_options(teamCount: 1));
      await first;
      expect(controller.state.options!.teams, hasLength(2));
      expect(controller.state.status, OnboardingLoadStatus.ready);
    },
  );

  test(
    'ONB-02/03/09/10 selections are valid, unbounded and include main team',
    () async {
      final repository = _OnboardingRepository(options: _options(teamCount: 7));
      final controller = _controller(repository);
      await controller.load();
      controller.selectMainTeam(1);
      for (var id = 2; id <= 7; id++) {
        controller.toggleTeam(id);
      }
      controller.toggleTeam(1);
      controller.togglePlayer(10);
      controller.togglePlayer(11);
      controller.toggleTeam(0);
      controller.toggleTeam(-2);
      controller.togglePlayer(0);
      controller.togglePlayer(-3);
      expect(controller.state.followTeamIds, {1, 2, 3, 4, 5, 6, 7});
      expect(controller.state.followPlayerIds, {10, 11});

      expect(await controller.submit(), isTrue);
      expect(repository.savedMainTeam, 1);
      expect(repository.savedTeams, {1, 2, 3, 4, 5, 6, 7});
      expect(controller.state.isSubmitting, isFalse);
    },
  );

  test(
    'ONB-08/11 save failure preserves selections and retry succeeds',
    () async {
      final repository = _OnboardingRepository(
        options: _options(),
        saveErrors: [const BusinessException('保存失败', code: 50021)],
      );
      final controller = _controller(repository);
      await controller.load();
      controller.selectMainTeam(1);
      controller.toggleTeam(2);
      controller.togglePlayer(10);
      expect(await controller.submit(), isFalse);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.mainTeamId, 1);
      expect(controller.state.followTeamIds, {1, 2});
      expect(controller.state.followPlayerIds, {10});
      expect(controller.state.message, '保存失败');
      expect(await controller.submit(), isTrue);
      expect(repository.saveCalls, 2);
    },
  );

  test(
    'ONB-10/12 empty player selection is allowed and current-user failure is visible',
    () async {
      final repository = _OnboardingRepository(
        options: const OnboardingOptions(
          teams: [TeamOption(id: 1, name: '主队', followed: false)],
          players: [],
        ),
      );
      final authRepository = _AuthRepository(
        currentUserError: const NetworkException('用户刷新失败'),
      );
      final auth = AuthController(authRepository);
      await auth.initialize();
      final controller = OnboardingController(repository, auth);
      await controller.load();
      controller.selectMainTeam(1);
      expect(await controller.submit(), isFalse);
      expect(repository.savedTeams, {1});
      expect(controller.state.message, '用户刷新失败');
      expect(controller.state.followPlayerIds, isEmpty);
    },
  );

  testWidgets(
    'ONB-06 options error exposes local retry and then renders choices',
    (tester) async {
      final repository = _OnboardingRepository(
        options: _options(),
        loadErrors: [const NetworkException('选项加载失败')],
      );
      final controller = _controller(repository);
      await _pumpOnboarding(tester, controller, repository);
      expect(find.byKey(const ValueKey('onboarding_error')), findsOneWidget);
      expect(find.text('网络连接失败，请重试。'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('main_team_1')), findsOneWidget);
    },
  );

  testWidgets(
    'ONB-05 Android back returns from later step without losing state',
    (tester) async {
      final repository = _OnboardingRepository(options: _options());
      final controller = _controller(repository);
      await _pumpOnboarding(tester, controller, repository);
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('选择我的主队'), findsOneWidget);
      expect(controller.state.mainTeamId, 1);
    },
  );

  testWidgets(
    'ONB-01/04/05 team and player searches are independent and preserve selections',
    (tester) async {
      final repository = _OnboardingRepository(options: _options(teamCount: 3));
      final controller = _controller(repository);
      await _pumpOnboarding(tester, controller, repository);

      expect(find.text('步骤 1 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding_previous')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_main_team_search')),
        '英格兰',
      );
      expect(find.byKey(const ValueKey('main_team_1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('步骤 2 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('follow_team_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('follow_team_2')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('onboarding_team_search')),
        '超级联赛',
      );
      expect(find.byKey(const ValueKey('follow_team_2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('follow_team_2')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('步骤 3 / 3'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_player_search')),
        '前锋',
      );
      expect(find.byKey(const ValueKey('player_10')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player_10')));
      await tester.tap(find.byKey(const ValueKey('onboarding_previous')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('onboarding_team_search')),
            )
            .controller!
            .text,
        '超级联赛',
      );
      expect(controller.state.followTeamIds, {1, 2});
      await tester.tap(find.byKey(const ValueKey('onboarding_previous')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('onboarding_main_team_search')),
            )
            .controller!
            .text,
        '英格兰',
      );
      expect(controller.state.mainTeamId, 1);
      expect(find.byKey(const ValueKey('onboarding_next')), findsOneWidget);
    },
  );

  testWidgets(
    'ONB-11 submit busy prevents duplicate and success redirects once',
    (tester) async {
      final save = Completer<SavedPreferences>();
      final repository = _OnboardingRepository(
        options: _options(),
        savePending: save,
      );
      final auth = AuthController(
        _AuthRepository(
          user: _needsOnboardingUser,
          currentUserResult: _readyUser,
        ),
      );
      await auth.initialize();
      final controller = OnboardingController(repository, auth);
      final router = GoRouter(
        initialLocation: '/onboarding',
        redirect: (_, state) =>
            authRedirect(auth.state.status, state.matchedLocation),
        refreshListenable: controller,
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingPage(),
          ),
          GoRoute(path: '/app/home', builder: (_, _) => const Text('首页')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((_) => auth),
            onboardingControllerProvider.overrideWith((_) => controller),
            onboardingRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_submit')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('onboarding_submit')));
      await tester.pump();
      expect(repository.saveCalls, 1);
      expect(find.byKey(const ValueKey('onboarding_submit')), findsOneWidget);
      save.complete(_savedPreferences);
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
    },
  );

  testWidgets('ONB-13 onboarding fits 360/412px at 1.4x text', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 915);
      await _pumpOnboarding(
        tester,
        _controller(_OnboardingRepository(options: _options())),
        _OnboardingRepository(options: _options()),
        textScale: 1.4,
      );
      expect(
        find.byKey(const ValueKey('onboarding_bottom_actions')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

OnboardingController _controller(_OnboardingRepository repository) {
  final auth = AuthController(_AuthRepository());
  return OnboardingController(repository, auth);
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  OnboardingController controller,
  _OnboardingRepository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((_) => controller),
        onboardingRepositoryProvider.overrideWithValue(repository),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(theme: AppTheme.light, home: const OnboardingPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

OnboardingOptions _options({int teamCount = 3}) => OnboardingOptions(
  teams: [
    TeamOption(
      id: 1,
      name: '英格兰主队',
      leagueName: '英格兰超级联赛',
      country: '英格兰',
      followed: false,
    ),
    if (teamCount > 1)
      const TeamOption(
        id: 2,
        name: '北岸队',
        leagueName: '超级联赛',
        country: '中国',
        followed: false,
      ),
    for (var id = 3; id <= teamCount; id++)
      TeamOption(id: id, name: '球队$id', followed: false),
  ],
  players: const [
    PlayerOption(
      id: 10,
      name: '前锋球员',
      position: '前锋',
      teamName: '北岸队',
      followed: false,
    ),
    PlayerOption(id: 11, name: '中场球员', followed: false),
  ],
);

final class _OnboardingRepository implements OnboardingRepositoryContract {
  _OnboardingRepository({
    this.options,
    this.pending = const [],
    this.loadErrors = const [],
    this.saveErrors = const [],
    this.savePending,
  });

  final OnboardingOptions? options;
  final List<Completer<OnboardingOptions>> pending;
  final List<Object> loadErrors;
  final List<Object> saveErrors;
  final Completer<SavedPreferences>? savePending;
  int loadCalls = 0;
  int saveCalls = 0;
  int? savedMainTeam;
  Set<int> savedTeams = {};

  @override
  Future<OnboardingOptions> loadOptions() async {
    loadCalls++;
    if (pending.isNotEmpty) return pending.removeAt(0).future;
    if (loadErrors.isNotEmpty) throw loadErrors.removeAt(0);
    return options ?? _options();
  }

  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) async {
    saveCalls++;
    savedMainTeam = mainTeamId;
    savedTeams = {...followTeamIds, mainTeamId};
    if (saveErrors.isNotEmpty) throw saveErrors.removeAt(0);
    if (savePending != null) return savePending!.future;
    return _savedPreferences;
  }
}

final class _AuthRepository implements AuthRepositoryContract {
  _AuthRepository({
    this.currentUserError,
    this.user = _readyUser,
    this.currentUserResult,
  });
  final AppNetworkException? currentUserError;
  final AuthUser user;
  final AuthUser? currentUserResult;

  @override
  Future<AuthUser> currentUser() async {
    if (currentUserError != null) throw currentUserError!;
    return currentUserResult ?? user;
  }

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
  Future<String?> storedToken() async => 'stored';
}

const _readyUser = AuthUser(
  id: 1,
  username: 'onboarding_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);

const _needsOnboardingUser = AuthUser(
  id: 1,
  username: 'onboarding_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: false,
);

const _savedPreferences = SavedPreferences(
  completed: true,
  mainTeamId: 1,
  followTeamCount: 1,
  followPlayerCount: 0,
);
