import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/router/auth_redirect.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  test('routes bootstrapping and failure to bootstrap page', () {
    expect(authRedirect(AuthStatus.bootstrapping, '/login'), '/bootstrap');
    expect(authRedirect(AuthStatus.failure, '/authenticated'), '/bootstrap');
  });

  test('routes unauthenticated users to login while keeping public routes', () {
    expect(
      authRedirect(AuthStatus.unauthenticated, '/authenticated'),
      '/login',
    );
    expect(authRedirect(AuthStatus.unauthenticated, '/register'), isNull);
  });

  test('routes authenticated users by onboarding completion', () {
    expect(
      authRedirect(AuthStatus.authenticatedNeedsOnboarding, '/login'),
      '/onboarding',
    );
    expect(
      authRedirect(AuthStatus.authenticatedReady, '/onboarding'),
      '/app/home',
    );
    expect(authRedirect(AuthStatus.authenticatedReady, '/app/data'), isNull);
    expect(authRedirect(AuthStatus.authenticatedReady, '/content/42'), isNull);
  });
}
