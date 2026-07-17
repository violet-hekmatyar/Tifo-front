import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/onboarding_repository.dart';
import '../../domain/onboarding_models.dart';

enum OnboardingLoadStatus { loading, ready, empty, failure }

final class OnboardingState {
  const OnboardingState({
    required this.status,
    this.options,
    this.mainTeamId,
    this.followTeamIds = const {},
    this.followPlayerIds = const {},
    this.message,
    this.isSubmitting = false,
  });

  const OnboardingState.loading() : this(status: OnboardingLoadStatus.loading);

  final OnboardingLoadStatus status;
  final OnboardingOptions? options;
  final int? mainTeamId;
  final Set<int> followTeamIds;
  final Set<int> followPlayerIds;
  final String? message;
  final bool isSubmitting;
}

final onboardingControllerProvider =
    ChangeNotifierProvider.autoDispose<OnboardingController>((ref) {
      return OnboardingController(
        ref.watch(onboardingRepositoryProvider),
        ref.watch(authControllerProvider),
      );
    });

final class OnboardingController extends ChangeNotifier {
  OnboardingController(this._repository, this._authController);

  final OnboardingRepositoryContract _repository;
  final AuthController _authController;
  OnboardingState _state = const OnboardingState.loading();

  OnboardingState get state => _state;

  Future<void> load() async {
    _setState(const OnboardingState.loading());
    try {
      final options = await _repository.loadOptions();
      if (options.isEmpty || options.teams.isEmpty) {
        _setState(
          OnboardingState(
            status: OnboardingLoadStatus.empty,
            options: options,
            message: '暂无可选球队，请稍后重试。',
          ),
        );
        return;
      }
      _setState(
        OnboardingState(
          status: OnboardingLoadStatus.ready,
          options: options,
          followTeamIds: options.teams
              .where((item) => item.followed)
              .map((item) => item.id)
              .toSet(),
          followPlayerIds: options.players
              .where((item) => item.followed)
              .map((item) => item.id)
              .toSet(),
        ),
      );
    } on AppNetworkException catch (error) {
      _setState(
        OnboardingState(
          status: OnboardingLoadStatus.failure,
          message: error is NetworkException ? '网络连接失败，请重试。' : error.message,
        ),
      );
    }
  }

  void selectMainTeam(int id) {
    _setState(
      OnboardingState(
        status: _state.status,
        options: _state.options,
        mainTeamId: id,
        followTeamIds: {..._state.followTeamIds, id},
        followPlayerIds: _state.followPlayerIds,
      ),
    );
  }

  void toggleTeam(int id) {
    final selected = {..._state.followTeamIds};
    if (id == _state.mainTeamId) return;
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    _copySelections(followTeamIds: selected);
  }

  void togglePlayer(int id) {
    final selected = {..._state.followPlayerIds};
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    _copySelections(followPlayerIds: selected);
  }

  Future<bool> submit() async {
    if (_state.isSubmitting) return false;
    final mainTeamId = _state.mainTeamId;
    if (mainTeamId == null) {
      _copySelections(message: '请先选择一支主队。');
      return false;
    }
    _copySelections(isSubmitting: true);
    try {
      await _repository.savePreferences(
        mainTeamId: mainTeamId,
        followTeamIds: _state.followTeamIds,
        followPlayerIds: _state.followPlayerIds,
      );
      await _authController.refreshAfterOnboarding();
      return true;
    } on AppNetworkException catch (error) {
      _copySelections(message: error.message);
      return false;
    }
  }

  void _copySelections({
    Set<int>? followTeamIds,
    Set<int>? followPlayerIds,
    String? message,
    bool isSubmitting = false,
  }) {
    _setState(
      OnboardingState(
        status: _state.status,
        options: _state.options,
        mainTeamId: _state.mainTeamId,
        followTeamIds: followTeamIds ?? _state.followTeamIds,
        followPlayerIds: followPlayerIds ?? _state.followPlayerIds,
        message: message,
        isSubmitting: isSubmitting,
      ),
    );
  }

  void _setState(OnboardingState value) {
    _state = value;
    notifyListeners();
  }
}
