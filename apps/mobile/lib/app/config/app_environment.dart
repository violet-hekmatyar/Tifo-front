import '../../core/network/network_exceptions.dart';

enum AppEnvironment {
  development,
  test,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' => AppEnvironment.development,
      'test' => AppEnvironment.test,
      'production' => AppEnvironment.production,
      _ => throw ConfigException(
        'APP_ENV must be development, test, or production; received "$value".',
      ),
    };
  }
}
