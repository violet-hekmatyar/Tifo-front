import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/app.dart';
import 'package:tifo/core/auth/auth_providers.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';

void main() {
  testWidgets('shows the F03 login form after bootstrap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoTokenRepository()),
        ],
        child: const TifoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('南看台'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '用户名'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _NoTokenRepository implements AuthRepositoryContract {
  static const user = AuthUser(
    id: 1,
    username: 'user',
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
