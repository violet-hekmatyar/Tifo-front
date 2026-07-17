import '../domain/onboarding_models.dart';
import 'onboarding_api.dart';

abstract interface class OnboardingRepositoryContract {
  Future<OnboardingOptions> loadOptions();

  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  });
}

final class OnboardingRepository implements OnboardingRepositoryContract {
  const OnboardingRepository(this._api);

  final OnboardingApi _api;

  @override
  Future<OnboardingOptions> loadOptions() => _api.options();

  @override
  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) => _api.savePreferences(
    mainTeamId: mainTeamId,
    followTeamIds: {...followTeamIds, mainTeamId},
    followPlayerIds: followPlayerIds.toSet(),
  );
}
