import 'network_exceptions.dart';

typedef JsonDecoder<T> = T Function(Object? json);

final class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.traceId,
  });

  factory ApiResponse.fromRaw(Object? raw, JsonDecoder<T> decode) {
    try {
      if (raw is! Map) {
        throw const ParseException('API response must be a JSON object.');
      }
      final code = raw['code'];
      final message = raw['message'];
      final traceId = raw['traceId'];
      if (code is! num || message is! String) {
        throw const ParseException(
          'API response requires numeric code and string message fields.',
        );
      }
      if (traceId != null && traceId is! String) {
        throw const ParseException('API response traceId must be a string.');
      }
      final normalizedCode = code.toInt();
      if (normalizedCode != 0) {
        throw BusinessException(
          message,
          code: normalizedCode,
          traceId: traceId as String?,
        );
      }
      return ApiResponse<T>(
        code: normalizedCode,
        message: message,
        data: decode(raw['data']),
        traceId: traceId as String?,
      );
    } on AppNetworkException {
      rethrow;
    } catch (error) {
      throw ParseException('Failed to decode API response data.', cause: error);
    }
  }

  final int code;
  final String message;
  final T data;
  final String? traceId;
}

void decodeVoid(Object? _) {}

List<T> decodeList<T>(Object? raw, JsonDecoder<T> decodeItem) {
  if (raw is! List) {
    throw const ParseException('Expected a JSON array.');
  }
  return raw.map(decodeItem).toList(growable: false);
}
