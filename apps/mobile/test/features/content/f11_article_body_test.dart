import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/widgets/content_media_gallery.dart';

void main() {
  testWidgets(
    'ARTICLE renders blocks by stable sortOrder and degrades unknown',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArticleBody(detail: _detail, mediaUrls: []),
          ),
        ),
      );

      final first = tester.getTopLeft(find.text('第一段')).dy;
      final second = tester.getTopLeft(find.text('第二段')).dy;
      expect(first, lessThan(second));
      expect(
        find.byKey(const ValueKey('unknown_article_block_3')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

const _detail = ContentDetail(
  contentId: 1,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_FORMAT',
  title: '文章',
  body: '',
  author: ContentAuthor(userId: 1, nickname: '作者'),
  media: [],
  blocks: [
    ArticleBlock(blockId: 2, rawType: 'TEXT', text: '第二段', sortOrder: 2),
    ArticleBlock(blockId: 1, rawType: 'TEXT', text: '第一段', sortOrder: 1),
    ArticleBlock(blockId: 3, rawType: 'POLL', sortOrder: 2),
  ],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 0,
  liked: false,
  favorited: false,
);
