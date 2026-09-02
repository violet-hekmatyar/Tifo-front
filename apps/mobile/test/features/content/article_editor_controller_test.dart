import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/controllers/article_editor_controller.dart';
import 'package:tifo/features/content/presentation/controllers/publish_post_controller.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/search/domain/search_models.dart';

void main() {
  test(
    'create uploads cover/image, orders blocks and deduplicates relations',
    () async {
      final contents = _Contents();
      final files = _Files();
      final picker = _Picker([
        [
          XFile.fromData(Uint8List.fromList(const [1]), name: 'block.png'),
        ],
        [
          XFile.fromData(Uint8List.fromList(const [2]), name: 'cover.png'),
        ],
      ]);
      final controller = ArticleEditorController(
        contentId: null,
        contents: contents,
        files: files,
        picker: picker,
      );
      controller.updateText(1, '第一段');
      await controller.addImageBlocks();
      await controller.pickCover();
      controller.setRelations([
        _entity(SearchEntityType.team, 9),
        _entity(SearchEntityType.team, 9),
        _entity(SearchEntityType.player, 10),
        _entity(SearchEntityType.content, 11),
      ]);

      final id = await controller.submit('标题', '摘要');
      final request = contents.created!;
      expect(id, 77);
      expect(request.coverFileId, isNotNull);
      expect(request.blocks.map((block) => block.blockType), ['TEXT', 'IMAGE']);
      expect(request.blocks.map((block) => block.sortOrder), [1, 2]);
      expect(request.blocks.last.mediaFileId, isNotNull);
      expect(request.relations.map((relation) => relation.type), [
        'TEAM',
        'PLAYER',
      ]);
      expect(files.uploads, 2);
    },
  );

  test('edit loads ARTICLE and surfaces backend permission failure', () async {
    final contents = _Contents(
      detailValue: _article,
      error: const BusinessException('无权编辑', code: 40301),
    );
    final controller = ArticleEditorController(
      contentId: 42,
      currentUserId: 1,
      contents: contents,
      files: _Files(),
      picker: _Picker(const []),
    );
    await controller.load();
    expect(controller.state.status, ArticleEditorStatus.ready);
    expect(controller.state.title, '原文章');
    expect(controller.state.blocks.single.text, '原正文');

    controller.updateText(controller.state.blocks.single.key, '修改正文');
    expect(await controller.submit('原文章', ''), isNull);
    expect(controller.state.message, '无权编辑');
    expect(controller.state.hasDraft, isTrue);
  });

  test('partial upload failure remains owned by draft cleanup', () async {
    final files = _Files(failOnUpload: 2);
    final picker = _Picker([
      [
        XFile.fromData(Uint8List.fromList(const [1]), name: 'inline.png'),
      ],
      [
        XFile.fromData(Uint8List.fromList(const [2]), name: 'cover.png'),
      ],
    ]);
    final controller = ArticleEditorController(
      contentId: null,
      contents: _Contents(),
      files: files,
      picker: picker,
    );
    controller.updateText(1, '正文');
    await controller.addImageBlocks();
    await controller.pickCover();

    expect(await controller.submit('标题', ''), isNull);
    await controller.cleanupDraft();
    expect(files.deleted, [101]);
  });

  test('edit rebinds existing cover and legacy image URLs', () async {
    final contents = _Contents(detailValue: _articleWithRemoteMedia);
    final files = _Files();
    final controller = ArticleEditorController(
      contentId: 42,
      currentUserId: 1,
      contents: contents,
      files: files,
      picker: _Picker(const []),
    );
    await controller.load();
    controller.updateText(controller.state.blocks.first.key, '新正文');

    expect(await controller.submit('原文章', ''), 42);
    expect(files.remoteCopies, ['/cover.jpg', '/inline.jpg']);
    expect(contents.updated?.coverFileId, 201);
    expect(contents.updated?.blocks.last.mediaFileId, 202);
  });

  test('edit reuses file ids from public media URLs without copying', () async {
    final contents = _Contents(detailValue: _articleWithPublicMedia);
    final files = _Files();
    final controller = ArticleEditorController(
      contentId: 42,
      currentUserId: 1,
      contents: contents,
      files: files,
      picker: _Picker(const []),
    );
    await controller.load();
    controller.updateText(controller.state.blocks.first.key, '新正文');

    expect(await controller.submit('原文章', ''), 42);
    expect(files.remoteCopies, isEmpty);
    expect(contents.updated?.coverFileId, 301);
    expect(contents.updated?.blocks.last.mediaFileId, 302);
  });

  test('admin edit copies another author public media before update', () async {
    final contents = _Contents(detailValue: _articleWithPublicMedia);
    final files = _Files();
    final controller = ArticleEditorController(
      contentId: 42,
      currentUserId: 99,
      contents: contents,
      files: files,
      picker: _Picker(const []),
    );
    await controller.load();
    controller.updateText(controller.state.blocks.first.key, '管理员修改');

    expect(await controller.submit('原文章', ''), 42);
    expect(files.remoteCopies, [
      '/api/public/files/301?preview=true',
      'http://localhost:8080/api/public/files/302',
    ]);
    expect(contents.updated?.coverFileId, 201);
    expect(contents.updated?.blocks.last.mediaFileId, 202);
  });

  test('unknown loaded block is blocked with a clear local message', () async {
    final controller = ArticleEditorController(
      contentId: 42,
      contents: _Contents(detailValue: _articleWithUnknownBlock),
      files: _Files(),
      picker: _Picker(const []),
    );
    await controller.load();

    expect(await controller.submit('原文章', ''), isNull);
    expect(controller.state.message, contains('暂不支持'));
  });
}

final class _Contents implements ContentRepositoryContract {
  _Contents({this.detailValue = _article, this.error});
  final ContentDetail detailValue;
  AppNetworkException? error;
  ArticleRequest? created;
  ArticleRequest? updated;

  @override
  Future<CreatedPost> createArticle(ArticleRequest request) async {
    created = request;
    return CreatedPost(contentId: 77, title: request.title);
  }

  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) async {
    if (error case final value?) throw value;
    updated = request;
    return detailValue;
  }

  @override
  Future<ContentDetail> detail(int id) async => detailValue;

  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  }) => throw UnimplementedError();
}

final class _Files implements FileUploadRepositoryContract {
  _Files({this.failOnUpload});
  final int? failOnUpload;
  int uploads = 0;
  final List<int> deleted = [];
  final List<String> remoteCopies = [];
  @override
  Future<UploadedFile> copyRemoteImage(String url) async {
    remoteCopies.add(url);
    return UploadedFile(fileId: 200 + remoteCopies.length, url: url);
  }

  @override
  Future<UploadedFile> upload(String path, String name) async {
    uploads++;
    if (uploads == failOnUpload) {
      throw const NetworkException('upload failed');
    }
    return UploadedFile(fileId: 100 + uploads, url: '/$name');
  }

  @override
  Future<void> delete(int id) async => deleted.add(id);
}

final class _Picker implements GalleryPicker {
  _Picker(this.responses);
  final List<List<XFile>> responses;
  int index = 0;
  @override
  Future<List<XFile>> pickImages() async => responses[index++];
}

SearchEntity _entity(SearchEntityType type, int id) => SearchEntity(
  type: type,
  rawType: type.wireValue,
  entityId: id,
  name: '${type.wireValue} $id',
);

const _article = ContentDetail(
  contentId: 42,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_FORMAT',
  title: '原文章',
  body: '',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  blocks: [ArticleBlock(rawType: 'TEXT', text: '原正文', sortOrder: 1)],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 0,
  liked: false,
  favorited: false,
);

const _articleWithRemoteMedia = ContentDetail(
  contentId: 42,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_BLOCKS',
  title: '原文章',
  body: '',
  summary: '',
  coverUrl: '/cover.jpg',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  blocks: [
    ArticleBlock(rawType: 'TEXT', text: '原正文', sortOrder: 1),
    ArticleBlock(rawType: 'IMAGE', mediaUrl: '/inline.jpg', sortOrder: 2),
  ],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 0,
  liked: false,
  favorited: false,
);

const _articleWithPublicMedia = ContentDetail(
  contentId: 42,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_BLOCKS',
  title: '原文章',
  body: '',
  summary: '',
  coverUrl: '/api/public/files/301?preview=true',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  blocks: [
    ArticleBlock(rawType: 'TEXT', text: '原正文', sortOrder: 1),
    ArticleBlock(
      rawType: 'IMAGE',
      mediaUrl: 'http://localhost:8080/api/public/files/302',
      sortOrder: 2,
    ),
  ],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 0,
  liked: false,
  favorited: false,
);

const _articleWithUnknownBlock = ContentDetail(
  contentId: 42,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_BLOCKS',
  title: '原文章',
  body: '',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  blocks: [ArticleBlock(rawType: 'POLL', sortOrder: 1)],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 0,
  liked: false,
  favorited: false,
);
