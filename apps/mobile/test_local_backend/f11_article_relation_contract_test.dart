import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/content/data/content_api.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/controllers/article_editor_controller.dart';
import 'package:tifo/features/content/presentation/controllers/publish_post_controller.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/search/data/search_api.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  test(
    'real ARTICLE create read update read with relations',
    () async {
      if (!enabled) {
        markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true explicitly.');
        return;
      }
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final client = ApiClient(config, dio);
      final auth = AuthRepository(AuthApi(client), storage);
      final contents = ContentRepository(ContentApi(client));
      final files = FileUploadRepository(client, config: config);
      final search = SearchApi(client);
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f11_${suffix.substring(suffix.length - 12)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      await auth.register(
        username: username,
        phone: '138${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      final user = await auth.login(username: username, password: password);

      final relations = <ContentRelationInput>[];
      for (final type in const [
        SearchEntityType.team,
        SearchEntityType.player,
        SearchEntityType.match,
      ]) {
        final page = await search.entities(
          keyword: '曼',
          entityType: type,
          pageNum: 1,
          pageSize: 1,
        );
        relations.add(
          ContentRelationInput(
            type: type.wireValue,
            id: page.records.single.entityId!,
          ),
        );
      }

      final dir = await Directory.systemTemp.createTemp('f11-real');
      try {
        final image = File('${dir.path}/article.png');
        await image.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
        );
        final cover = await files.upload(image.path, 'cover.png');
        final inline = await files.upload(image.path, 'inline.png');
        final created = await contents.createArticle(
          ArticleRequest(
            title: 'F11 真实文章 $suffix',
            summary: '创建摘要',
            coverFileId: cover.fileId,
            blocks: [
              const ArticleBlockInput(
                blockType: 'TEXT',
                text: '创建正文',
                sortOrder: 1,
              ),
              ArticleBlockInput(
                blockType: 'IMAGE',
                mediaFileId: inline.fileId,
                sortOrder: 2,
              ),
            ],
            relations: relations,
          ),
        );
        final first = await contents.detail(created.contentId);
        expect(first.contentType, 'ARTICLE');
        expect(first.contentFormat, anyOf('ARTICLE_FORMAT', 'ARTICLE_BLOCKS'));
        expect(first.blocks.map((block) => block.type), [
          ArticleBlockType.text,
          ArticleBlockType.image,
        ]);
        expect(first.relations.map((relation) => relation.type).toSet(), {
          'TEAM',
          'PLAYER',
          'MATCH',
        });

        final editor = ArticleEditorController(
          contentId: created.contentId,
          currentUserId: user.id,
          contents: contents,
          files: files,
          picker: const DeviceGalleryPicker(),
        );
        await editor.load();
        final textBlock = editor.state.blocks.firstWhere(
          (block) => block.type == ArticleBlockType.text,
        );
        editor.updateText(textBlock.key, '编辑后的正文');
        final updatedId = await editor.submit('F11 已编辑文章 $suffix', '编辑摘要');
        expect(updatedId, created.contentId, reason: editor.state.message);
        final second = await contents.detail(created.contentId);
        expect(second.title, 'F11 已编辑文章 $suffix');
        expect(second.blocks.first.text, '编辑后的正文');
        expect(second.blocks.map((block) => block.sortOrder), [1, 2]);
        expect(second.relations, hasLength(3));
        expect(second.coverUrl, isNotNull);
      } finally {
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
