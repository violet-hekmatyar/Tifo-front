import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import 'api_response.dart';
import 'dio_exception_mapper.dart';
import 'network_exceptions.dart';

final class ApiClient {
  const ApiClient(this._config, this._dio);

  final AppConfig _config;
  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decode,
  }) => _request(
    path,
    method: 'GET',
    queryParameters: queryParameters,
    decode: decode,
  );

  Future<T> post<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
  }) => _request(path, method: 'POST', body: body, decode: decode);

  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
  }) => _request(path, method: 'PUT', body: body, decode: decode);

  Future<T> patch<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
  }) => _request(path, method: 'PATCH', body: body, decode: decode);

  Future<T> delete<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
  }) => _request(path, method: 'DELETE', body: body, decode: decode);

  Future<T> _request<T>(
    String path, {
    required String method,
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decode,
  }) async {
    final baseUrl = Uri.parse(_config.requireApiBaseUrl());
    final requestUrl = baseUrl.resolve(path).toString();
    try {
      final response = await _dio.request<Object?>(
        requestUrl,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return ApiResponse<T>.fromRaw(response.data, decode).data;
    } on AppNetworkException {
      rethrow;
    } on DioException catch (error) {
      throw mapDioException(error);
    } catch (error) {
      throw UnknownException('An unexpected API error occurred.', cause: error);
    }
  }
}
