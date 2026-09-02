import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/network_providers.dart';
import '../domain/uploaded_file.dart';

abstract interface class FileUploadRepositoryContract {
  Future<UploadedFile> upload(String path, String name);
  Future<UploadedFile> copyRemoteImage(String url);
  Future<void> delete(int id);
}

final fileUploadRepositoryProvider = Provider<FileUploadRepositoryContract>(
  (ref) => FileUploadRepository(
    ref.watch(apiClientProvider),
    config: ref.watch(appConfigProvider),
  ),
);

final class FileUploadRepository implements FileUploadRepositoryContract {
  const FileUploadRepository(this.client, {this.config});
  final ApiClient client;
  final AppConfig? config;
  @override
  Future<UploadedFile> upload(String path, String name) => client.postMultipart(
    '/api/app/files/upload',
    filePath: path,
    fileName: name,
    fields: {'bizType': 'CONTENT_IMAGE'},
    decode: (raw) {
      if (raw is! Map || raw['fileId'] is! num || raw['url'] is! String) {
        throw const ParseException('Invalid upload response.');
      }
      return UploadedFile(
        fileId: (raw['fileId'] as num).toInt(),
        url: raw['url'] as String,
      );
    },
  );

  @override
  Future<UploadedFile> copyRemoteImage(String url) async {
    final appConfig = config;
    if (appConfig == null) {
      throw const ConfigException('Remote media copy is not configured.');
    }
    final source = Uri.tryParse(url.trim());
    if (source == null) throw const ParseException('Invalid media URL.');
    final resolved = source.hasScheme
        ? source
        : appConfig.apiBaseUrl?.resolveUri(source);
    if (resolved == null ||
        (resolved.scheme != 'http' && resolved.scheme != 'https')) {
      throw const ParseException('Invalid media URL.');
    }
    final base = appConfig.apiBaseUrl;
    if (base == null ||
        resolved.scheme != base.scheme ||
        resolved.host != base.host ||
        resolved.port != base.port) {
      throw const ParseException('External media copy is not allowed.');
    }
    final http = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'image/*'},
      ),
    );
    try {
      final response = await http.get<ResponseBody>(
        resolved.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      final declaredLength = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (declaredLength != null && declaredLength > _maxImageBytes) {
        throw const ParseException('Remote media exceeds 10MB.');
      }
      final bytes = <int>[];
      await for (final chunk in response.data!.stream) {
        bytes.addAll(chunk);
        if (bytes.length > _maxImageBytes) {
          throw const ParseException('Remote media exceeds 10MB.');
        }
      }
      if (bytes.isEmpty) throw const ParseException('Remote media is empty.');
      final extension = _imageExtension(bytes);
      if (extension == null) {
        throw const ParseException('Remote media is not a supported image.');
      }
      final directory = await Directory.systemTemp.createTemp('tifo-article');
      final file = File('${directory.path}/existing-media.$extension');
      try {
        await file.writeAsBytes(bytes, flush: true);
        return await upload(file.path, 'existing-media.$extension');
      } finally {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    } finally {
      http.close(force: true);
    }
  }

  @override
  Future<void> delete(int id) =>
      client.delete('/api/app/files/$id', decode: (_) {});
}

const _maxImageBytes = 10 * 1024 * 1024;

String? _imageExtension(List<int> bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'jpg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  return null;
}
