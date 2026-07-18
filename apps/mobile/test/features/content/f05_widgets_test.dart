import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/features/content/domain/content_detail.dart';
import 'package:tifo/features/content/presentation/widgets/content_media_gallery.dart';

void main() {
  testWidgets('post gallery has no gap without media', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          Text('before'),
          ContentMediaGallery(mediaUrls: []),
          Text('after'),
        ],
      ),
    );
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi image gallery shows page indicator and fallback', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 300,
        child: ContentMediaGallery(
          mediaUrls: ['http://127.0.0.1:1/a.png', 'http://127.0.0.1:1/b.png'],
        ),
      ),
    );
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('article fallback preserves body before media', (tester) async {
    await _pump(tester, const ArticleBody(detail: _article, mediaUrls: []));
    expect(find.text('第一段真实正文'), findsOneWidget);
  });

  testWidgets('visual primitives survive Pixel 8 and 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ArticleBody(detail: _article, mediaUrls: []),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  ),
);

const _article = ContentDetail(
  contentId: 2,
  contentType: 'ARTICLE',
  contentFormat: 'ARTICLE_FORMAT',
  title: '文章',
  body: '第一段真实正文',
  author: ContentAuthor(userId: 1, nickname: '编辑'),
  media: [],
  relations: [],
  likeCount: 0,
  commentCount: 0,
  favoriteCount: 0,
  viewCount: 1,
  liked: false,
  favorited: false,
);
