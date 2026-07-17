import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/app/config/app_environment.dart';
import 'package:tifo/core/network/network_exceptions.dart';

void main() {
  test('supports development, test, and production environments', () {
    expect(AppConfig.fromValues().environment, AppEnvironment.development);
    expect(
      AppConfig.fromValues(appEnv: 'test').environment,
      AppEnvironment.test,
    );
    expect(
      AppConfig.fromValues(appEnv: 'production').environment,
      AppEnvironment.production,
    );
  });

  test('rejects an invalid APP_ENV', () {
    expect(
      () => AppConfig.fromValues(appEnv: 'staging'),
      throwsA(isA<ConfigException>()),
    );
  });

  test('allows a missing base URL until a request needs it', () {
    final config = AppConfig.fromValues();
    expect(config.apiBaseUrl, isNull);
    expect(config.requireApiBaseUrl, throwsA(isA<ConfigException>()));
  });

  test('rejects an invalid base URL', () {
    expect(
      () => AppConfig.fromValues(apiBaseUrl: 'localhost:8080'),
      throwsA(isA<ConfigException>()),
    );
  });
}
