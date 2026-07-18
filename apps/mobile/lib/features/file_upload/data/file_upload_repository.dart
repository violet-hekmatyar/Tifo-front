import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/network_providers.dart';
import '../domain/uploaded_file.dart';

abstract interface class FileUploadRepositoryContract {
  Future<UploadedFile> upload(String path, String name);
  Future<void> delete(int id);
}

final fileUploadRepositoryProvider = Provider<FileUploadRepositoryContract>(
  (ref) => FileUploadRepository(ref.watch(apiClientProvider)),
);

final class FileUploadRepository implements FileUploadRepositoryContract {
  const FileUploadRepository(this.client);
  final ApiClient client;
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
  Future<void> delete(int id) =>
      client.delete('/api/app/files/$id', decode: (_) {});
}
