import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/media_url_resolver.dart';

void main() {
  final config = AppConfig.fromValues(apiBaseUrl: 'http://10.0.2.2:8080/api/');

  test('resolves absolute and root-relative media URLs', () {
    expect(
      resolveMediaUrl(config, '/api/public/files/7'),
      'http://10.0.2.2:8080/api/public/files/7',
    );
    expect(
      resolveMediaUrl(config, 'https://cdn.example.test/a.png'),
      'https://cdn.example.test/a.png',
    );
  });

  test('returns null for empty, malformed, or unavailable media values', () {
    expect(resolveMediaUrl(config, null), isNull);
    expect(resolveMediaUrl(config, '   '), isNull);
    expect(resolveMediaUrl(config, 'http://[invalid'), isNull);
    expect(
      resolveMediaUrl(
        AppConfig.fromValues(apiBaseUrl: ''),
        '/demo/p1-media/cover-stadium.png',
      ),
      isNull,
    );
  });
}
