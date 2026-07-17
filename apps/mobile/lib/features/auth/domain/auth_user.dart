import '../../../core/network/network_exceptions.dart';

final class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.roleType,
    required this.status,
    required this.onboardingCompleted,
    this.nickname,
    this.avatarUrl,
    this.mainTeamId,
  });

  factory AuthUser.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! num ||
        raw['username'] is! String ||
        raw['roleType'] is! String ||
        raw['status'] is! String ||
        raw['onboardingCompleted'] is! bool) {
      throw const ParseException('Invalid authenticated user response.');
    }
    return AuthUser(
      id: (raw['id'] as num).toInt(),
      username: raw['username'] as String,
      nickname: raw['nickname'] as String?,
      avatarUrl: raw['avatarUrl'] as String?,
      roleType: raw['roleType'] as String,
      status: raw['status'] as String,
      onboardingCompleted: raw['onboardingCompleted'] as bool,
      mainTeamId: (raw['mainTeamId'] as num?)?.toInt(),
    );
  }

  final int id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final String roleType;
  final String status;
  final bool onboardingCompleted;
  final int? mainTeamId;

  AuthUser completeOnboarding(int mainTeamId) => AuthUser(
    id: id,
    username: username,
    nickname: nickname,
    avatarUrl: avatarUrl,
    roleType: roleType,
    status: status,
    onboardingCompleted: true,
    mainTeamId: mainTeamId,
  );
}
