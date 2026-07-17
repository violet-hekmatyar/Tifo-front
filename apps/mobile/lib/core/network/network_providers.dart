import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import 'api_client.dart';
import 'request_interceptors.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromDartDefines(),
);

final requestHeadersProvider = Provider<RequestHeadersProvider>(
  (ref) =>
      () => const <String, String>{},
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: const {'Accept': Headers.jsonContentType},
    ),
  );
  dio.interceptors.add(
    buildRequestHeadersInterceptor(ref.watch(requestHeadersProvider)),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(appConfigProvider), ref.watch(dioProvider)),
);
