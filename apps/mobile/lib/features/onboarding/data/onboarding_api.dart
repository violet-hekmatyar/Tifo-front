import '../../../core/network/api_client.dart';
import '../domain/onboarding_models.dart';

final class OnboardingApi {
  const OnboardingApi(this._client);

  final ApiClient _client;

  Future<OnboardingOptions> options() => _client.get<OnboardingOptions>(
    '/api/app/onboarding/options',
    decode: OnboardingOptions.fromJson,
  );

  Future<SavedPreferences> savePreferences({
    required int mainTeamId,
    required Iterable<int> followTeamIds,
    required Iterable<int> followPlayerIds,
  }) => _client.post<SavedPreferences>(
    '/api/app/onboarding/preferences',
    body: {
      'mainTeamId': mainTeamId,
      'followTeamIds': followTeamIds.toSet().toList(),
      'followPlayerIds': followPlayerIds.toSet().toList(),
    },
    decode: SavedPreferences.fromJson,
  );
}
