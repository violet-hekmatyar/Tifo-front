import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/onboarding/data/onboarding_api.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../network/network_providers.dart';
import 'token_storage_provider.dart';

final authRepositoryProvider = Provider<AuthRepositoryContract>(
  (ref) => AuthRepository(
    AuthApi(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
  ),
);

final onboardingRepositoryProvider = Provider<OnboardingRepositoryContract>(
  (ref) => OnboardingRepository(OnboardingApi(ref.watch(apiClientProvider))),
);
