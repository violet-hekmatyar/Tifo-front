import '../../core/network/network_exceptions.dart';
import 'app_environment.dart';

final class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  factory AppConfig.fromValues({
    String appEnv = 'development',
    String apiBaseUrl = '',
  }) {
    final environment = AppEnvironment.parse(appEnv);
    final normalizedUrl = apiBaseUrl.trim();
    if (normalizedUrl.isEmpty) {
      return AppConfig(environment: environment, apiBaseUrl: null);
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ConfigException(
        'API_BASE_URL must be an absolute http(s) URL; received "$apiBaseUrl".',
      );
    }
    return AppConfig(environment: environment, apiBaseUrl: uri);
  }

  factory AppConfig.fromDartDefines() => AppConfig.fromValues(
    appEnv: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    ),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
  );

  final AppEnvironment environment;
  final Uri? apiBaseUrl;

  String requireApiBaseUrl() {
    final value = apiBaseUrl;
    if (value == null) {
      throw const ConfigException(
        'API_BASE_URL is required before an API request can be sent.',
      );
    }
    return value.toString();
  }
}
