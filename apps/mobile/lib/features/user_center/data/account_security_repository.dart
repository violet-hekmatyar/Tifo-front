import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json_value.dart';
import '../../../core/network/network_providers.dart';

abstract interface class AccountSecurityRepositoryContract {
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
  Future<String?> changePhone(String phone);
  Future<void> deactivateAccount();
}

final accountSecurityRepositoryProvider =
    Provider<AccountSecurityRepositoryContract>(
      (ref) => AccountSecurityRepository(ref.watch(apiClientProvider)),
    );

final class AccountSecurityRepository
    implements AccountSecurityRepositoryContract {
  const AccountSecurityRepository(this._client);
  final ApiClient _client;

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _client.put<void>(
    '/api/app/users/me/password',
    body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    decode: (_) {},
  );

  @override
  Future<String?> changePhone(String phone) => _client.put<String?>(
    '/api/app/users/me/phone',
    body: {'phone': phone},
    decode: (raw) {
      final map = jsonMap(raw);
      return map == null ? null : jsonString(map['phoneMasked']);
    },
  );

  @override
  Future<void> deactivateAccount() =>
      _client.delete<void>('/api/app/users/me', decode: (_) {});
}
