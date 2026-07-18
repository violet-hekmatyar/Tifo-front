import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/auth/token_storage.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/request_interceptors.dart';
import 'package:tifo/features/auth/data/auth_api.dart';
import 'package:tifo/features/auth/data/auth_repository.dart';
import 'package:tifo/features/content/data/content_api.dart';
import 'package:tifo/features/content/data/content_repository.dart';
import 'package:tifo/features/file_upload/data/file_upload_repository.dart';
import 'package:tifo/features/feed/data/feed_api.dart';
import 'package:tifo/features/feed/data/feed_repository.dart';
import 'package:tifo/features/feed/domain/feed_card.dart';
import 'package:tifo/features/feed/domain/feed_filter.dart';
import 'package:tifo/features/feed/presentation/models/feed_display_sections.dart';
import 'package:tifo/features/interaction/data/interaction_api.dart';
import 'package:tifo/features/interaction/data/interaction_repository.dart';
import 'package:tifo/features/interaction/domain/comment.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_BACKEND_INTEGRATION');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  test(
    'real content upload publish interaction lifecycle',
    () async {
      if (!enabled) markTestSkipped('Set RUN_LOCAL_BACKEND_INTEGRATION=true.');
      final config = AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl);
      final storage = InMemoryTokenStorage();
      final dio = Dio();
      dio.interceptors.add(
        buildRequestHeadersInterceptor(() async {
          final token = await storage.readAccessToken();
          return token == null ? const {} : {'Authorization': 'Bearer $token'};
        }),
      );
      final client = ApiClient(config, dio);
      final auth = AuthRepository(AuthApi(client), storage);
      final content = ContentRepository(ContentApi(client));
      final interaction = InteractionRepository(InteractionApi(client));
      final files = FileUploadRepository(client);
      final feed = FeedRepository(FeedApi(client));
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final username = 'f05_${suffix.substring(suffix.length - 12)}';
      final password = 'T!${suffix.substring(suffix.length - 10)}z';
      await auth.register(
        username: username,
        phone: '135${suffix.substring(suffix.length - 8)}',
        password: password,
      );
      final user = await auth.login(username: username, password: password);
      final existing = await content.detail(20003);
      expect(existing.contentFormat, 'ARTICLE_FORMAT');
      final initialLiked = existing.liked;
      await interaction.toggleLike(existing.contentId);
      final afterLike = await content.detail(existing.contentId);
      expect(afterLike.liked, !initialLiked);
      await interaction.toggleLike(existing.contentId);
      expect((await content.detail(existing.contentId)).liked, initialLiked);
      final initialFavorite = existing.favorited;
      await interaction.toggleFavorite(existing.contentId);
      expect(
        (await content.detail(existing.contentId)).favorited,
        !initialFavorite,
      );
      await interaction.toggleFavorite(existing.contentId);
      expect(
        (await content.detail(existing.contentId)).favorited,
        initialFavorite,
      );
      final dir = await Directory.systemTemp.createTemp('f05-real');
      try {
        final png = File('${dir.path}/f05.png');
        await png.writeAsBytes(_png);
        final uploaded = await files.upload(png.path, 'f05.png');
        final created = await content.createPost(
          title: 'F05 real $suffix',
          body: 'F05 repository integration post.',
          mediaFileIds: [uploaded.fileId],
        );
        final detail = await content.detail(created.contentId);
        expect(detail.media.map((m) => m.mediaUrl), contains(uploaded.url));
        expect(detail.contentFormat, 'POST_FORMAT');
        final visibility = <FeedFilter, int?>{};
        final loadedByFilter = <FeedFilter, List<FeedCard>>{};
        for (final filter in FeedFilter.values) {
          final loaded = <FeedCard>[];
          var pageNum = 1;
          while (pageNum <= 20) {
            final page = await feed.loadFeed(
              filter: filter,
              pageNum: pageNum,
              pageSize: 10,
            );
            loaded.addAll(page.cards);
            if (!page.hasMore) break;
            pageNum++;
          }
          final sections = FeedDisplaySections.fromCards(loaded);
          loadedByFilter[filter] = loaded;
          final found = sections.contents
              .where((card) => card.contentId == created.contentId)
              .firstOrNull;
          visibility[filter] = found == null
              ? null
              : _pageContaining(loaded, created.contentId, 10);
          expect(
            sections.matches.length +
                sections.contents.length +
                sections.compatibility.length,
            sections.cardCount,
          );
          if (found != null) {
            expect(sections.contents, contains(found));
          }
        }
        final realMatch = loadedByFilter.values
            .expand((cards) => cards)
            .whereType<MatchFeedCard>()
            .firstOrNull;
        final filterTeamId = realMatch?.homeTeam.teamId;
        int? teamFilterPage;
        if (filterTeamId != null) {
          final teamCards = <FeedCard>[];
          var pageNum = 1;
          while (pageNum <= 20) {
            final page = await feed.loadFeed(
              filter: FeedFilter.recommend,
              teamId: filterTeamId,
              pageNum: pageNum,
              pageSize: 10,
            );
            teamCards.addAll(page.cards);
            if (!page.hasMore) break;
            pageNum++;
          }
          teamFilterPage = _pageContaining(teamCards, created.contentId, 10);
          if (teamFilterPage == -1) teamFilterPage = null;
        }
        // IDs and page numbers are safe diagnostics; credentials/tokens are not.
        // ignore: avoid_print
        print(
          'F05 feed visibility contentId=${created.contentId} '
          'recommend=${visibility[FeedFilter.recommend] ?? 'absent'} '
          'news=${visibility[FeedFilter.news] ?? 'absent'} '
          'following=${visibility[FeedFilter.following] ?? 'absent'} '
          'team=${filterTeamId ?? 'unavailable'}:'
          '${teamFilterPage ?? 'absent'}',
        );
        final root = await interaction.createComment(
          contentId: created.contentId,
          content: 'F05 root $suffix',
        );
        final reply = await interaction.createComment(
          contentId: created.contentId,
          content: 'F05 reply $suffix',
          parentId: root,
          replyToUserId: user.id,
        );
        final hot = await interaction.comments(
          created.contentId,
          CommentSort.hot,
          1,
        );
        final latest = await interaction.comments(
          created.contentId,
          CommentSort.latest,
          1,
        );
        expect(hot.records.map((x) => x.commentId), contains(root));
        expect(latest.records.map((x) => x.commentId), contains(root));
        final replies = await interaction.replies(root, 1);
        expect(replies.records.map((x) => x.commentId), contains(reply));
        final liked = await interaction.toggleCommentLike(reply);
        expect(liked.active, isTrue);
        expect((await interaction.toggleCommentLike(reply)).active, isFalse);
        await interaction.deleteComment(reply);
        await interaction.deleteComment(root);
        await expectLater(
          interaction.toggleCommentLike(reply),
          throwsA(
            isA<BusinessException>().having((e) => e.code, 'code', 40401),
          ),
        );
        await expectLater(
          interaction.createComment(
            contentId: created.contentId,
            content: 'must fail',
            parentId: root,
          ),
          throwsA(
            isA<BusinessException>().having((e) => e.code, 'code', 40401),
          ),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

int _pageContaining(List<FeedCard> cards, int contentId, int pageSize) {
  final index = cards.indexWhere(
    (card) => card is ContentFeedCard && card.contentId == contentId,
  );
  return index < 0 ? -1 : index ~/ pageSize + 1;
}

const _png = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  4,
  0,
  0,
  0,
  181,
  28,
  12,
  2,
  0,
  0,
  0,
  11,
  73,
  68,
  65,
  84,
  120,
  218,
  99,
  252,
  255,
  31,
  0,
  3,
  3,
  2,
  0,
  239,
  191,
  167,
  219,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
