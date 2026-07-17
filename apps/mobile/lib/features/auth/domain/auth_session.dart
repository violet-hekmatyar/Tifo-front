import '../../../core/network/network_exceptions.dart';
import 'auth_user.dart';

final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['accessToken'] is! String ||
        raw['tokenType'] is! String ||
        raw['expiresIn'] is! num) {
      throw const ParseException('Invalid login response.');
    }
    return AuthSession(
      accessToken: raw['accessToken'] as String,
      tokenType: raw['tokenType'] as String,
      expiresIn: (raw['expiresIn'] as num).toInt(),
      user: AuthUser.fromJson(raw['user']),
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;
}
