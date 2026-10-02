import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/auth/presentation/pages/login_page.dart';
import 'package:tifo/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('VR12 login hierarchy uses the green hero and full-width panel', (
    tester,
  ) async {
    final controller = await _controller(_Repository());
    await _pump(tester, controller, const Size(412, 915));

    expect(find.byKey(const ValueKey('login_green_header')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_brand_icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_white_panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_username')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_password')), findsOneWidget);
    expect(find.text('手机号'), findsNothing);
    expect(find.text('微信登录'), findsNothing);
    expect(find.text('游客登录'), findsNothing);
    expect(find.text('找回密码'), findsNothing);

    final panel = tester.getRect(
      find.byKey(const ValueKey('login_white_panel')),
    );
    final icon = tester.getRect(find.byKey(const ValueKey('login_brand_icon')));
    expect(panel.top / 915, inInclusiveRange(.48, .54));
    expect(icon.size, const Size(60, 60));
    expect(
      tester.getRect(find.byKey(const ValueKey('login_title'))).center.dx,
      closeTo(206, 2),
    );
  });

  testWidgets(
    'VR12 agreement footer follows actions and uses a compact circle',
    (tester) async {
      final controller = await _controller(_Repository());
      await _pump(tester, controller, const Size(412, 915));

      final register = tester.getRect(
        find.byKey(const ValueKey('login_to_register')),
      );
      final footer = tester.getRect(
        find.byKey(const ValueKey('login_agreement_footer')),
      );
      final indicatorFinder = find.byKey(
        const ValueKey('auth_agreement_checkbox'),
      );
      final indicator = tester.getRect(indicatorFinder);
      final checkbox = tester.widget<Checkbox>(indicatorFinder);

      expect(footer.top, greaterThan(register.bottom));
      expect(footer.center.dy / 915, inInclusiveRange(.90, .95));
      expect(indicator.width, inInclusiveRange(18, 20));
      expect(indicator.height, inInclusiveRange(18, 20));
      expect(checkbox.shape, isA<CircleBorder>());
    },
  );

  testWidgets('VR12 agreement is a centered dialog and decline is inert', (
    tester,
  ) async {
    final repository = _Repository();
    final controller = await _controller(repository);
    await _pump(tester, controller, const Size(412, 915));
    await _fill(tester);
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth_agreement_dialog')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('服务协议及隐私保护'), findsOneWidget);
    final dialog = tester.getRect(
      find.byKey(const ValueKey('auth_agreement_dialog')),
    );
    expect(dialog.width / 412, inInclusiveRange(.70, .76));
    expect(dialog.center.dx, closeTo(206, 8));
    expect(dialog.center.dy, closeTo(915 / 2, 8));

    await tester.tap(find.byKey(const ValueKey('auth_agreement_decline')));
    await tester.pumpAndSettle();
    expect(repository.loginCalls, 0);
  });

  testWidgets('VR12 agreement acceptance submits exactly once and busy locks', (
    tester,
  ) async {
    final repository = _Repository(loginPending: Completer<AuthUser>());
    final controller = await _controller(repository);
    await _pump(tester, controller, const Size(412, 915));
    await _fill(tester);
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth_agreement_accept')));
    await tester.pump();
    expect(repository.loginCalls, 1);
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pump();
    expect(repository.loginCalls, 1);
  });

  testWidgets('VR12 360dp and 140% remain reachable without overflow', (
    tester,
  ) async {
    for (final size in [const Size(360, 915), const Size(412, 915)]) {
      final controller = await _controller(_Repository());
      await _pump(tester, controller, size, textScale: 1.4);
      expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
      await tester.showKeyboard(find.byKey(const ValueKey('login_password')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('login_submit')));
      expect(
        tester.getRect(find.byKey(const ValueKey('login_submit'))).right,
        lessThanOrEqualTo(size.width),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('VR12 real errors retain both fields', (tester) async {
    final controller = await _controller(
      _Repository(loginError: const BusinessException('账号已锁定', code: 40103)),
    );
    await _pump(tester, controller, const Size(412, 915));
    await _fill(tester);
    await tester.tap(find.byKey(const ValueKey('auth_agreement_checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login_error')), findsOneWidget);
    expect(
      tester
          .widget<AppTextField>(find.byKey(const ValueKey('login_username')))
          .controller
          .text,
      'valid_user',
    );
    expect(
      tester
          .widget<AppTextField>(find.byKey(const ValueKey('login_password')))
          .controller
          .text,
      'secret',
    );
  });
}

Future<AuthController> _controller(_Repository repository) async {
  final controller = AuthController(repository);
  await controller.initialize();
  return controller;
}

Future<void> _pump(
  WidgetTester tester,
  AuthController controller,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: ProviderScope(
        overrides: [authControllerProvider.overrideWith((_) => controller)],
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('login_username')),
    'valid_user',
  );
  await tester.enterText(
    find.byKey(const ValueKey('login_password')),
    'secret',
  );
}

final class _Repository implements AuthRepositoryContract {
  _Repository({this.loginError, this.loginPending});

  final AppNetworkException? loginError;
  final Completer<AuthUser>? loginPending;
  int loginCalls = 0;

  @override
  Future<AuthUser> currentUser() async => _user;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return loginPending?.future ?? _user;
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
  Future<AuthUser> restore() async => _user;

  @override
  Future<String?> storedToken() async => null;
}

const _user = AuthUser(
  id: 1,
  username: 'valid_user',
  roleType: 'USER',
  status: 'ACTIVE',
  onboardingCompleted: true,
);
