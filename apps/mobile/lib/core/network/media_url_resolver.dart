import '../../app/config/app_config.dart';

String? resolveMediaUrl(AppConfig config, String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return null;
  if (uri.hasScheme) return uri.toString();
  final base = config.apiBaseUrl;
  return base?.resolveUri(uri).toString();
}
