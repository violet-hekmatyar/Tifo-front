import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/features/content/data/content_api.dart';
import 'package:tifo/features/content/domain/content_detail.dart';

void main() {
  const base = 'https://api.test';
  late Dio dio;
  late DioAdapter adapter;
  late ContentApi api;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    api = ContentApi(ApiClient(AppConfig.fromValues(apiBaseUrl: base), dio));
  });

  test(
    'ARTICLE detail sorts blocks stably and preserves unknown blocks',
    () async {
      adapter.onGet(
        '$base/api/app/contents/7',
        (server) => server.reply(
          200,
          _envelope({
            'contentId': 7,
            'contentType': 'ARTICLE',
            'title': '文章',
            'author': {'userId': 1, 'nickname': '作者'},
            'blocks': [
              {
                'blockId': 3,
                'blockType': 'POLL',
                'text': '未知段',
                'sortOrder': 2,
              },
              {
                'blockId': 1,
                'blockType': 'TEXT',
                'text': '第一段',
                'sortOrder': 1,
              },
              {
                'blockId': 2,
                'blockType': 'IMAGE',
                'mediaUrl': '/a.png',
                'sortOrder': 2,
              },
            ],
            'mediaList': [],
            'relationList': [],
          }),
        ),
      );

      final detail = await api.detail(7);
      expect(detail.contentType, 'ARTICLE');
      expect(detail.contentFormat, 'POST_FORMAT');
      expect(detail.blocks.map((block) => block.blockId), [1, 3, 2]);
      expect(detail.blocks[1].type, ArticleBlockType.unknown);
      expect(detail.blocks[2].mediaUrl, '/a.png');
    },
  );

  test('create and update submit the frozen ARTICLE request shape', () async {
    const request = ArticleRequest(
      title: '真实文章',
      summary: '摘要',
      coverFileId: 11,
      blocks: [
        ArticleBlockInput(blockType: 'TEXT', text: '正文', sortOrder: 1),
        ArticleBlockInput(blockType: 'IMAGE', mediaFileId: 12, sortOrder: 2),
      ],
      relations: [ContentRelationInput(type: 'TEAM', id: 13)],
    );
    final data = request.toJson();
    adapter
      ..onPost(
        '$base/api/app/contents/articles',
        (server) =>
            server.reply(200, _envelope({'contentId': 7, 'title': '真实文章'})),
        data: data,
      )
      ..onPut(
        '$base/api/app/contents/7/articles',
        (server) => server.reply(200, _envelope(_detail(7))),
        data: data,
      );

    expect((await api.createArticle(request)).contentId, 7);
    expect(
      (await api.updateArticle(7, request)).contentFormat,
      'ARTICLE_FORMAT',
    );
  });
}

Map<String, Object?> _envelope(Object? data) => {
  'code': 0,
  'message': 'success',
  'data': data,
};

Map<String, Object?> _detail(int id) => {
  'contentId': id,
  'contentType': 'ARTICLE',
  'contentFormat': 'ARTICLE_FORMAT',
  'title': '真实文章',
  'author': {'userId': 1, 'nickname': '作者'},
  'blocks': [],
  'mediaList': [],
  'relationList': [],
};
