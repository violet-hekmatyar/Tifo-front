import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/auth/domain/auth_user.dart';
import 'package:tifo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tifo/features/onboarding/data/onboarding_repository.dart';
import 'package:tifo/features/onboarding/domain/onboarding_models.dart';
import 'package:tifo/features/onboarding/presentation/controllers/onboarding_controller.dart';

void main() {
  test(
    'SEA-11 loads options and keeps the unbounded local selection model',
    () async {
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
    },
  );

  test('SEA-13 shows load failure and supports retry state', () async {
    final controller = _controller(
      _FakeOnboardingRepository(error: const NetworkException('offline')),
    );
    await controller.load();
    expect(controller.state.status, OnboardingLoadStatus.failure);
    expect(controller.state.message, contains('网络'));
  });

  test(
    'SEA-10 requires main team and auto-follows it without duplicate selections',
    () async {
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
    },
  );

  test(
    'SEA-12 submit failure preserves selections and retry succeeds without duplicate submit',
    () async {
      final repository = _FakeOnboardingRepository(
        options: _options,
        saveError: const NetworkException('save failed'),
      );
      final controller = _controller(repository);
      await controller.load();
      controller.selectMainTeam(1);
      controller.toggleTeam(2);
      expect(await controller.submit(), isFalse);
      expect(controller.state.followTeamIds, {1, 2});
      repository.saveError = null;
      expect(await controller.submit(), isTrue);
      expect(repository.savedMainTeam, 1);
      expect(repository.savedTeams, containsAll(<int>{1, 2}));
    },
  );

  test(
    'SEA-12 in-flight submit is ignored while the first request is pending',
    () async {
      final completer = Completer<SavedPreferences>();
      final repository = _FakeOnboardingRepository(
        options: _options,
        saveCompleter: completer,
      );
      final controller = _controller(repository);
      await controller.load();
      controller.selectMainTeam(1);

      final first = controller.submit();
      expect(controller.state.isSubmitting, isTrue);
      expect(await controller.submit(), isFalse);
      completer.complete(_savedPreferences);
      expect(await first, isTrue);
      expect(repository.saveCalls, 1);
    },
  );
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
  _FakeOnboardingRepository({
    this.options,
    this.error,
    this.saveError,
    this.saveCompleter,
  });
  final OnboardingOptions? options;
  final AppNetworkException? error;
  AppNetworkException? saveError;
  final Completer<SavedPreferences>? saveCompleter;
  int? savedMainTeam;
  Set<int> savedTeams = {};
  int saveCalls = 0;

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
    saveCalls++;
    if (saveError != null) throw saveError!;
    if (saveCompleter != null) return saveCompleter!.future;
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

const _savedPreferences = SavedPreferences(
  completed: true,
  mainTeamId: 1,
  followTeamCount: 1,
  followPlayerCount: 0,
);

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
