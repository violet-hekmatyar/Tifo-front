import '../../features/auth/presentation/controllers/auth_controller.dart';

String? authRedirect(AuthStatus status, String location) {
  const publicLocations = {'/login', '/register'};
  final isProtectedLocation =
      location.startsWith('/app') ||
      location == '/search' ||
      location.startsWith('/publish/') ||
      location.startsWith('/contents/') ||
      location.startsWith('/content/') ||
      location.startsWith('/match/') ||
      location.startsWith('/matches/') ||
      location.startsWith('/teams/') ||
      location.startsWith('/players/');
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
