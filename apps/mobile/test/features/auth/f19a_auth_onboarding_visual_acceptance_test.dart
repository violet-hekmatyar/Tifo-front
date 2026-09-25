import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/auth/auth_providers.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/auth/presentation/pages/bootstrap_page.dart';
import 'package:tifo/features/auth/presentation/pages/login_page.dart';
import 'package:tifo/features/auth/presentation/pages/register_page.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:tifo/shared/widgets/app_player_avatar.dart';
import 'package:tifo/shared/widgets/app_entity_avatar.dart';
import 'package:tifo/shared/widgets/app_selection_card.dart';
import 'package:tifo/shared/widgets/app_team_logo.dart';

void main() {
  testWidgets(
    'R14A-01/02 ready onboarding uses the prototype hierarchy and semantic hearts',
    (tester) async {
      await _pumpOnboarding(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding_green_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding_results_panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding_bottom_actions')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);

      final card = find.byKey(const ValueKey('main_team_1'));
      expect(
        tester.getSemantics(card).flagsCollection.isSelected ==
            ui.Tristate.isTrue,
        isFalse,
      );
      await tester.tap(card);
      await tester.pump();
      expect(
        tester.getSemantics(card).flagsCollection.isSelected ==
            ui.Tristate.isTrue,
        isTrue,
      );
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

      final panel = tester.getRect(
        find.byKey(const ValueKey('onboarding_results_panel')),
      );
      final actions = tester.getRect(
        find.byKey(const ValueKey('onboarding_bottom_actions')),
      );
      expect(panel.top, lessThan(actions.top));
      expect(actions.bottom, lessThanOrEqualTo(915));
    },
  );

  testWidgets(
    'R14A-03 each step restores its real scroll offset and Android back state',
    (tester) async {
      await _pumpOnboarding(tester);
      final mainList = find.byKey(
        const PageStorageKey('onboarding_step_1'),
        skipOffstage: false,
      );
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.drag(mainList, const Offset(0, -500));
      await tester.pump();
      final mainOffset = _offset(tester, mainList);
      expect(mainOffset, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pump();
      final followList = find.byKey(
        const PageStorageKey('onboarding_step_2'),
        skipOffstage: false,
      );
      await tester.drag(followList, const Offset(0, -400));
      await tester.pump();
      final followOffset = _offset(tester, followList);
      expect(followOffset, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pump();
      final playerList = find.byKey(
        const PageStorageKey('onboarding_step_3'),
        skipOffstage: false,
      );
      await tester.drag(playerList, const Offset(0, -350));
      await tester.pump();
      final playerOffset = _offset(tester, playerList);
      expect(playerOffset, greaterThan(0));

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('关注的球队'), findsOneWidget);
      expect(_offset(tester, followList), closeTo(followOffset, .1));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('我的主队'), findsOneWidget);
      expect(_offset(tester, mainList), closeTo(mainOffset, .1));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('onboarding_main_team_search')),
            )
            .controller!
            .text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'R14A-04 independent searches support fields, trim, clear, and local empty',
    (tester) async {
      await _pumpOnboarding(tester);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_main_team_search')),
        '  LEAGUE 2  ',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('main_team_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('main_team_1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('onboarding_search_clear')));
      await tester.pump();
      expect(find.byKey(const ValueKey('main_team_1')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('onboarding_main_team_search')),
        'not-a-team',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('onboarding_local_empty')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('onboarding_next')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('onboarding_search_clear')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('main_team_1')));
      await tester.tap(find.byKey(const ValueKey('onboarding_next')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_team_search')),
        'country 2',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('follow_team_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('follow_team_1')), findsNothing);
    },
  );

  testWidgets(
    'R14A-05 relative, missing, failed media and nullable long labels degrade safely',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(
              children: [
                AppTeamLogo(
                  identity: 'team:relative',
                  name: '超长球队名称超长球队名称超长球队名称',
                  imageUrl: '/media/team.png',
                ),
                AppPlayerAvatar(identity: 'player:missing', name: '球员'),
                AppPlayerAvatar(
                  identity: 'player:failed',
                  name: '失败头像',
                  imageUrl: 'invalid://avatar',
                ),
                AppSelectionCard(
                  title: '超长标题超长标题超长标题超长标题',
                  subtitle: '超长副标题 · 超长副标题 · 超长副标题',
                  selected: false,
                  onTap: _noop,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppEntityAvatar), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'R14A-09 agreement can be cancelled and closing the sheet does not resubmit',
    (tester) async {
      final auth = _AuthRepository();
      final controller = AuthController(auth);
      await _pumpAuth(tester, const LoginPage(), controller);
      await tester.enterText(
        find.byKey(const ValueKey('login_username')),
        'user',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password')),
        'password',
      );
      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth_agreement_accept')));
      await tester.pumpAndSettle();
      expect(auth.loginCalls, 1);
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('auth_agreement_checkbox')),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('auth_agreement_checkbox')));
      await tester.pump();
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('auth_agreement_checkbox')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('auth_agreement_sheet')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(auth.loginCalls, 1);
    },
  );

  testWidgets(
    'R14A-06/07 onboarding and auth key rectangles stay reachable at 360/412 and 1.4x',
    (tester) async {
      for (final width in [360.0, 412.0]) {
        await _setViewport(tester, width);
        await _pumpOnboarding(tester, textScale: 1.4);
        for (final step in [0, 1, 2]) {
          final header = tester.getRect(
            find.byKey(const ValueKey('onboarding_green_header')),
          );
          final search = tester.getRect(
            find.byKey(
              ValueKey(
                step == 0
                    ? 'onboarding_main_team_search'
                    : step == 1
                    ? 'onboarding_team_search'
                    : 'onboarding_player_search',
              ),
            ),
          );
          final panel = tester.getRect(
            find.byKey(const ValueKey('onboarding_results_panel')),
          );
          final actions = tester.getRect(
            find.byKey(const ValueKey('onboarding_bottom_actions')),
          );
          expect(header.left, greaterThanOrEqualTo(0));
          expect(header.right, lessThanOrEqualTo(width));
          expect(search.bottom, lessThanOrEqualTo(header.bottom));
          expect(panel.top, greaterThanOrEqualTo(header.top));
          expect(actions.right, lessThanOrEqualTo(width));
          expect(actions.bottom, lessThanOrEqualTo(915));
          if (step < 2) {
            if (step == 0) {
              await tester.tap(find.byKey(const ValueKey('main_team_1')));
            }
            await tester.tap(find.byKey(const ValueKey('onboarding_next')));
            await tester.pump();
          }
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'R14A-07/08 Login Register Bootstrap and agreement remain reachable with keyboard',
    (tester) async {
      await _setViewport(tester, 360);
      final auth = _AuthRepository();
      final controller = AuthController(auth);
      await _pumpAuth(tester, const RegisterPage(), controller, textScale: 1.4);
      await tester.showKeyboard(
        find.byKey(const ValueKey('register_confirmation')),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('register_submit')));
      expect(
        tester.getRect(find.byKey(const ValueKey('register_submit'))).bottom,
        lessThanOrEqualTo(915),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((_) => controller)],
          child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('login_username')),
        'user',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password')),
        'password',
      );
      await tester.showKeyboard(find.byKey(const ValueKey('login_password')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('login_submit')));
      await tester.tap(find.byKey(const ValueKey('login_submit')));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(
        find.byKey(const ValueKey('auth_agreement_sheet')),
      );
      expect(sheet.left, greaterThanOrEqualTo(0));
      expect(sheet.right, lessThanOrEqualTo(360));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('auth_agreement_accept')))
            .bottom,
        lessThanOrEqualTo(915),
      );
      await tester.tap(find.byKey(const ValueKey('auth_agreement_decline')));
      await tester.pumpAndSettle();
      expect(auth.loginCalls, 0);

      tester.testTextInput.hide();
      await tester.pump();
      final bootstrapAuth = _AuthRepository(token: 'token');
      final bootstrapController = AuthController(bootstrapAuth);
      await bootstrapController.retryBootstrap();
      expect(bootstrapController.state.status, AuthStatus.failure);
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authControllerProvider.overrideWith((_) => bootstrapController),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: BootstrapPage(key: UniqueKey()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('bootstrap_failure_message')))
            .right,
        lessThanOrEqualTo(360),
      );
      expect(find.byKey(const ValueKey('bootstrap_retry')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

double _offset(WidgetTester tester, Finder finder) =>
    tester.widget<ListView>(finder).controller!.position.pixels;

void _noop() {}

Future<void> _setViewport(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 915);
  tester.view.devicePixelRatio = 1;
  await tester.pump();
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  double textScale = 1,
}) async {
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
        home: OnboardingPage(key: UniqueKey()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpAuth(
  WidgetTester tester,
  Widget page,
  AuthController controller, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((_) => controller)],
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

final class _OnboardingRepository implements OnboardingRepositoryContract {
  @override
  Future<OnboardingOptions> loadOptions() async => OnboardingOptions(
    teams: List.generate(
      12,
      (index) => TeamOption(
        id: index + 1,
        name: '球队 ${index + 1}',
        leagueName: 'League ${index + 1}',
        country: 'Country ${index + 1}',
        followed: false,
        logoUrl: null,
      ),
    ),
    players: List.generate(
      10,
      (index) => PlayerOption(
        id: index + 1,
        name: '球员 ${index + 1}',
        teamName: '球队 ${index + 1}',
        position: index.isEven ? 'Goalkeeper' : 'Forward',
        followed: false,
        avatarUrl: index == 2 ? 'invalid://avatar' : null,
      ),
    ),
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
  _AuthRepository({this.token});

  final String? token;
  int loginCalls = 0;

  @override
  Future<AuthUser> currentUser() async => _user;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    return _user;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> register({
    required String username,
    required String phone,
    required String password,
  }) async => _user;

  @override
  Future<AuthUser> restore() async =>
      throw const BusinessException('恢复失败，请稍后重试。', code: 50001, traceId: null);

  @override
  Future<String?> storedToken() async => token;
}

const _user = AuthUser(
  id: 1,
  username: 'visual-test',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);
