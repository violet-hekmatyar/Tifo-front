import 'dart:async';

import 'package:dio/dio.dart';

typedef RequestHeadersProvider = FutureOr<Map<String, String>> Function();

InterceptorsWrapper buildRequestHeadersInterceptor(
  RequestHeadersProvider headersProvider,
) {
  var requestSequence = 0;
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      options.headers.addAll(await headersProvider());
      options.headers.putIfAbsent(
        'X-Request-Id',
        () =>
            'mobile-${DateTime.now().microsecondsSinceEpoch}-${requestSequence++}',
      );
      handler.next(options);
    },
  );
}
