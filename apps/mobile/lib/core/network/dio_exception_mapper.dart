import 'package:dio/dio.dart';

import 'network_exceptions.dart';

AppNetworkException mapDioException(DioException error) {
  return switch (error.type) {
    DioExceptionType.cancel => CancelledException(
      'The request was cancelled.',
      cause: error,
    ),
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutException(
      'The request timed out.',
      cause: error,
    ),
    DioExceptionType.connectionError => NetworkException(
      'Unable to connect to the server.',
      cause: error,
    ),
    DioExceptionType.badResponse => HttpException(
      'The server returned HTTP ${error.response?.statusCode ?? 'unknown'}.',
      statusCode: error.response?.statusCode,
      traceId: _traceId(error.response?.data),
      cause: error,
    ),
    DioExceptionType.badCertificate => NetworkException(
      'The server certificate is invalid.',
      cause: error,
    ),
    DioExceptionType.unknown => UnknownException(
      'An unexpected request error occurred.',
      cause: error,
    ),
  };
}

String? _traceId(Object? raw) {
  if (raw case {'traceId': final String traceId}) return traceId;
  return null;
}
