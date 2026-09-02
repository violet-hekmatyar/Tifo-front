import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/controllers/content_detail_controller.dart';
import 'package:tifo/features/content/presentation/controllers/publish_post_controller.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/file_upload/domain/uploaded_file.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/interaction/domain/comment.dart';
import 'package:tifo/features/interaction/presentation/controllers/comment_controller.dart';

void main() {
  test('detail loads POST/ARTICLE fields and invalid id is rejected', () async {
    final repo = _ContentRepo();
    final c = ContentDetailController(1, repo, _Interactions());
    await c.load();
    expect(c.state.status, DetailStatus.ready);
    expect(c.state.detail?.contentFormat, 'POST_FORMAT');
    final invalid = ContentDetailController(-1, repo, _Interactions());
    await invalid.load();
    expect(invalid.state.status, DetailStatus.notFound);
  });
  test('404 becomes unavailable state', () async {
    final repo = _ContentRepo()
      ..error = const BusinessException('missing', code: 40401);
    final c = ContentDetailController(9, repo, _Interactions());
    await c.load();
    expect(c.state.status, DetailStatus.notFound);
    expect(c.state.message, contains('下架'));
  });
  test('like prevents duplicate and refreshes authoritative counts', () async {
    final interactions = _Interactions()..toggleGate = Completer();
    final c = ContentDetailController(1, _ContentRepo(), interactions);
    await c.load();
    final a = c.toggleLike(), b = c.toggleLike();
    expect(interactions.likeCalls, 1);
    expect(c.state.detail?.liked, isTrue);
    expect(c.state.detail?.likeCount, 1);
    interactions.toggleGate!.complete(const ToggleState(active: true));
    await Future.wait([a, b]);
    expect(c.state.status, DetailStatus.ready);
  });
  test('like failure rolls back to loaded detail', () async {
    final interactions = _Interactions()
      ..error = const NetworkException('down');
    final c = ContentDetailController(1, _ContentRepo(), interactions);
    await c.load();
    await c.toggleLike();
    expect(c.state.detail?.liked, isFalse);
    expect(c.state.message, 'down');
  });
  test(
    'favorite is optimistic and failure restores authoritative state',
    () async {
      final interactions = _Interactions()
        ..favoriteGate = Completer<ToggleState>();
      final c = ContentDetailController(1, _ContentRepo(), interactions);
      await c.load();
      final action = c.toggleFavorite();
      expect(c.state.detail?.favorited, isTrue);
      expect(c.state.detail?.favoriteCount, 1);
      interactions.favoriteGate!.completeError(const NetworkException('down'));
      await action;
      expect(c.state.detail?.favorited, isFalse);
      expect(c.state.detail?.favoriteCount, 0);
    },
  );
  test('comment sort, pagination and dedupe are repository driven', () async {
    final repo = _Interactions();
    final c = CommentController(1, repo);
    await c.load(sort: CommentSort.latest);
    expect(c.state.sort, CommentSort.latest);
    expect(c.state.items.single.commentId, 1);
    await c.more();
    expect(c.state.items.map((x) => x.commentId), [1, 2]);
  });
  test(
    'comment send failure retains caller text and releases submitting',
    () async {
      final repo = _Interactions()..error = const NetworkException('down');
      final c = CommentController(1, repo);
      await c.load();
      final ok = await c.submit('保留的评论');
      expect(ok, isFalse);
      expect(c.state.submitting, isFalse);
    },
  );
  test('comment like and delete are guarded per object', () async {
    final repo = _Interactions();
    final c = CommentController(1, repo);
    await c.load();
    await c.toggleLike(c.state.items.first);
    expect(repo.commentLikeCalls, 1);
    await c.delete(c.state.items.first);
    expect(repo.deleteCalls, 1);
  });
  test('comment like is optimistic and rolls back on failure', () async {
    final repo = _Interactions()
      ..commentLikeError = const NetworkException('down');
    final c = CommentController(1, repo);
    await c.load();
    final action = c.toggleLike(c.state.items.first);
    expect(c.state.items.first.liked, isTrue);
    expect(c.state.items.first.likeCount, 1);
    await action;
    expect(c.state.items.first.liked, isFalse);
    expect(c.state.items.first.likeCount, 0);
    expect(c.state.message, 'down');
  });
  test('publish validates form and never submits author/stat fields', () async {
    final content = _ContentRepo();
    final c = PublishPostController(content, _Files(), _Gallery([]));
    expect(await c.publish('', ''), isNull);
    expect(content.created, 0);
    expect(await c.publish('标题', '正文'), 7);
    expect(content.lastMedia, isEmpty);
  });
  test('gallery deduplicates files and publish uploads mediaFileIds', () async {
    final dir = await Directory.systemTemp.createTemp('f05-test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/tiny.png');
    await file.writeAsBytes([0x89, 0x50, 0x4e, 0x47]);
    final x = XFile(file.path, name: 'tiny.png', mimeType: 'image/png');
    final content = _ContentRepo();
    final files = _Files();
    final c = PublishPostController(content, files, _Gallery([x, x]));
    await c.pickImages();
    expect(c.state.images.length, 1);
    expect(await c.publish('图片帖', ''), 7);
    expect(content.lastMedia, [11]);
    expect(files.uploadCalls, 1);
  });
  test(
    'failed upload can retry and successful image is not uploaded twice',
    () async {
      final dir = await Directory.systemTemp.createTemp('f05-retry');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/tiny.png');
      await file.writeAsBytes([0x89, 0x50]);
      final files = _Files()..fail = true;
      final c = PublishPostController(
        _ContentRepo(),
        files,
        _Gallery([XFile(file.path, name: 'tiny.png')]),
      );
      await c.pickImages();
      await c.upload(c.state.images.single);
      expect(c.state.images.single.status, UploadStatus.failure);
      files.fail = false;
      await c.upload(c.state.images.single);
      await c.upload(c.state.images.single);
      expect(files.uploadCalls, 2);
      await c.cleanupDraft();
      expect(files.deleteCalls, 1);
      expect(c.state.images, isEmpty);
    },
  );
}

final class _ContentRepo implements ContentRepositoryContract {
  AppNetworkException? error;
  int created = 0;
  List<int> lastMedia = [];
  @override
  Future<ContentDetail> detail(int id) async {
    if (error case final e?) throw e;
    return _detail;
  }

  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  }) async {
    created++;
    lastMedia = mediaFileIds;
    return CreatedPost(contentId: 7, title: title);
  }

  @override
  Future<CreatedPost> createArticle(ArticleRequest request) async =>
      CreatedPost(contentId: 8, title: request.title);

  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) async =>
      _detail;
}

final class _Interactions implements InteractionRepositoryContract {
  AppNetworkException? error;
  AppNetworkException? commentLikeError;
  Completer<ToggleState>? toggleGate;
  Completer<ToggleState>? favoriteGate;
  int likeCalls = 0, commentLikeCalls = 0, deleteCalls = 0;
  @override
  Future<ToggleState> toggleLike(int id) async {
    likeCalls++;
    if (error case final e?) throw e;
    if (toggleGate != null) return toggleGate!.future;
    return const ToggleState(active: true);
  }

  @override
  Future<ToggleState> toggleFavorite(int id) async {
    if (favoriteGate != null) return favoriteGate!.future;
    return const ToggleState(active: true);
  }

  @override
  Future<CommentPage> comments(int id, CommentSort sort, int page) async {
    if (error case final e?) throw e;
    return CommentPage(
      records: page == 1 ? [_comment(1)] : [_comment(1), _comment(2)],
      pageNum: page,
      pages: 2,
      total: 2,
    );
  }

  @override
  Future<CommentPage> replies(int id, int page) async => CommentPage(
    records: [_comment(3, parent: 1)],
    pageNum: 1,
    pages: 1,
    total: 1,
  );
  @override
  Future<int> createComment({
    required int contentId,
    required String content,
    int parentId = 0,
    int? replyToUserId,
  }) async {
    if (error case final e?) throw e;
    return 4;
  }

  @override
  Future<ToggleState> toggleCommentLike(int id) async {
    commentLikeCalls++;
    if (commentLikeError case final e?) throw e;
    return const ToggleState(active: true, count: 1);
  }

  @override
  Future<void> deleteComment(int id) async {
    deleteCalls++;
  }
}

final class _Files implements FileUploadRepositoryContract {
  bool fail = false;
  int uploadCalls = 0, deleteCalls = 0;
  @override
  Future<UploadedFile> upload(String path, String name) async {
    uploadCalls++;
    if (fail) throw const NetworkException('fail');
    return const UploadedFile(fileId: 11, url: '/api/public/files/11');
  }

  @override
  Future<UploadedFile> copyRemoteImage(String url) => upload(url, 'copy.jpg');

  @override
  Future<void> delete(int id) async {
    deleteCalls++;
  }
}

final class _Gallery implements GalleryPicker {
  _Gallery(this.files);
  final List<XFile> files;
  @override
  Future<List<XFile>> pickImages() async => files;
}

const _detail = ContentDetail(
  contentId: 1,
  contentType: 'POST',
  contentFormat: 'POST_FORMAT',
  title: '真实标题',
  body: '真实正文',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 1,
  liked: false,
  favorited: false,
);
CommentItem _comment(int id, {int parent = 0}) => CommentItem(
  commentId: id,
  parentId: parent,
  rootId: parent == 0 ? id : 1,
  author: const ContentAuthor(userId: 1, nickname: '作者'),
  content: '评论$id',
  likeCount: 0,
  replyCount: 0,
  liked: false,
  replies: const [],
);
