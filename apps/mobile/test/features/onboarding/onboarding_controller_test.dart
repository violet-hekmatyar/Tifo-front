import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/controllers/onboarding_controller.dart';

void main() {
  test('loads successful and empty options', () async {
    final controller = _controller(
      _FakeOnboardingRepository(options: _options),
    );
    await controller.load();
    expect(controller.state.status, OnboardingLoadStatus.ready);

    final empty = _controller(
      _FakeOnboardingRepository(
        options: const OnboardingOptions(teams: [], players: []),
      ),
    );
    await empty.load();
    expect(empty.state.status, OnboardingLoadStatus.empty);
  });

  test('shows load failure and supports retry state', () async {
    final controller = _controller(
      _FakeOnboardingRepository(error: const NetworkException('offline')),
    );
    await controller.load();
    expect(controller.state.status, OnboardingLoadStatus.failure);
    expect(controller.state.message, contains('网络'));
  });

  test('requires main team and deduplicates selections', () async {
    final repository = _FakeOnboardingRepository(options: _options);
    final controller = _controller(repository);
    await controller.load();
    expect(await controller.submit(), isFalse);
    expect(controller.state.message, contains('主队'));

    controller.selectMainTeam(1);
    controller.toggleTeam(2);
    controller.toggleTeam(2);
    controller.togglePlayer(10);
    controller.togglePlayer(10);
    controller.togglePlayer(10);
    expect(controller.state.followTeamIds, {1});
    expect(controller.state.followPlayerIds, {10});
  });

  test('submits preferences and refreshes authenticated user', () async {
    final repository = _FakeOnboardingRepository(options: _options);
    final controller = _controller(repository);
    await controller.load();
    controller.selectMainTeam(1);
    controller.toggleTeam(2);
    expect(await controller.submit(), isTrue);
    expect(repository.savedMainTeam, 1);
    expect(repository.savedTeams, containsAll(<int>{1, 2}));
  });
}

OnboardingController _controller(_FakeOnboardingRepository repository) {
  return OnboardingController(
    repository,
    AuthController(_ReadyAuthRepository()),
  );
}

const _options = OnboardingOptions(
  teams: [
    TeamOption(id: 1, name: 'One', followed: false),
    TeamOption(id: 2, name: 'Two', followed: false),
  ],
  players: [PlayerOption(id: 10, name: 'Player', followed: false)],
);

final class _FakeOnboardingRepository implements OnboardingRepositoryContract {
  _FakeOnboardingRepository({this.options, this.error});
  final OnboardingOptions? options;
  final AppNetworkException? error;
  int? savedMainTeam;
  Set<int> savedTeams = {};

  @override
  Future<OnboardingOptions> loadOptions() async {
    if (error != null) throw error!;
    return options!;
  }

  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) async {
    savedMainTeam = mainTeamId;
    savedTeams = {...followTeamIds, mainTeamId};
    return SavedPreferences(
      completed: true,
      mainTeamId: mainTeamId,
      followTeamCount: savedTeams.length,
      followPlayerCount: followPlayerIds.toSet().length,
    );
  }
}

final class _ReadyAuthRepository implements AuthRepositoryContract {
  static const user = AuthUser(
    id: 1,
    username: 'user',
    roleType: 'USER',
    status: 'ACTIVE',
    onboardingCompleted: true,
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
