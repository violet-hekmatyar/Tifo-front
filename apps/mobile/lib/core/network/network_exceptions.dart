sealed class AppNetworkException implements Exception {
  const AppNetworkException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class ConfigException extends AppNetworkException {
  const ConfigException(super.message, {super.cause});
}

final class NetworkException extends AppNetworkException {
  const NetworkException(super.message, {super.cause});
}

final class TimeoutException extends AppNetworkException {
  const TimeoutException(super.message, {super.cause});
}

final class CancelledException extends AppNetworkException {
  const CancelledException(super.message, {super.cause});
}

final class HttpException extends AppNetworkException {
  const HttpException(
    super.message, {
    required this.statusCode,
    this.traceId,
    super.cause,
  });

  final int? statusCode;
  final String? traceId;
}

final class BusinessException extends AppNetworkException {
  const BusinessException(
    super.message, {
    required this.code,
    this.traceId,
    super.cause,
  });

  final int code;
  final String? traceId;
}

final class ParseException extends AppNetworkException {
  const ParseException(super.message, {super.cause});
}

final class UnknownException extends AppNetworkException {
  const UnknownException(super.message, {super.cause});
}
