import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../domain/content_detail.dart';
import 'content_api.dart';

abstract interface class ContentRepositoryContract {
  Future<ContentDetail> detail(int id);
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  });
  Future<CreatedPost> createArticle(ArticleRequest request);
  Future<ContentDetail> updateArticle(int id, ArticleRequest request);
}

final contentRepositoryProvider = Provider<ContentRepositoryContract>(
  (ref) => ContentRepository(ContentApi(ref.watch(apiClientProvider))),
);

final class ContentRepository implements ContentRepositoryContract {
  const ContentRepository(this.api);
  final ContentApi api;
  @override
  Future<ContentDetail> detail(int id) => api.detail(id);
  @override
  Future<CreatedPost> createPost({
    required String title,
    required String body,
    required List<int> mediaFileIds,
  }) => api.createPost(title: title, body: body, mediaFileIds: mediaFileIds);

  @override
  Future<CreatedPost> createArticle(ArticleRequest request) =>
      api.createArticle(request);

  @override
  Future<ContentDetail> updateArticle(int id, ArticleRequest request) =>
      api.updateArticle(id, request);
}
