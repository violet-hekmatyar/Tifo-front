import '../../features/auth/presentation/controllers/auth_controller.dart';

String? authRedirect(AuthStatus status, String location) {
  const publicLocations = {'/login', '/register'};
  final isProtectedLocation =
      location.startsWith('/app') ||
      location == '/search' ||
      location == '/publish' ||
      location.startsWith('/content/') ||
      location.startsWith('/match/');
  return switch (status) {
    AuthStatus.bootstrapping ||
    AuthStatus.failure => location == '/bootstrap' ? null : '/bootstrap',
    AuthStatus.unauthenticated =>
      publicLocations.contains(location) ? null : '/login',
    AuthStatus.authenticatedNeedsOnboarding =>
      location == '/onboarding' ? null : '/onboarding',
    AuthStatus.authenticatedReady => isProtectedLocation ? null : '/app/home',
  };
}
