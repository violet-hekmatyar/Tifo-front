import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/shared/widgets/app_state_illustration.dart';
import 'package:tifo/shared/widgets/app_state_view.dart';

import 'vr13_test_font.dart';

void main() {
  setUpAll(loadVr13TestFont);

  testWidgets(
    'VR13 catalog keeps nine independent illustrations in two columns',
    (tester) async {
      tester.view.physicalSize = const Size(750, 1808);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: vr13TestFontFamily),
          home: RepaintBoundary(
            key: ValueKey('vr13_catalog'),
            child: _Catalog(),
          ),
        ),
      );

      expect(find.byType(AppStateIllustration), findsNWidgets(9));
      for (final label in [
        '搜索无结果',
        '网络故障',
        '暂无关注',
        '暂无关注球队',
        '暂无浏览记录',
        '暂无评论',
        '暂无收藏',
        '暂无数据',
        '暂无消息',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      final search = tester.getRect(
        find.byKey(const ValueKey('app_state_illustration_searchEmpty')),
      );
      final network = tester.getRect(
        find.byKey(const ValueKey('app_state_illustration_networkError')),
      );
      final messages = tester.getRect(
        find.byKey(const ValueKey('app_state_illustration_noMessages')),
      );
      final dpr = tester.view.devicePixelRatio;
      expect(search.width * dpr, 128);
      expect(search.height * dpr, 128);
      expect(search.center.dx * dpr, closeTo(222.5, 6));
      expect(network.center.dx * dpr, closeTo(529.1, 6));
      expect(messages.center.dx * dpr, closeTo(222.5, 6));
      expect(search.top * dpr, closeTo(238, 8));
      for (final item in [
        AppStateIllustrationType.noFollowing,
        AppStateIllustrationType.noHistory,
        AppStateIllustrationType.noFavorites,
        AppStateIllustrationType.noMessages,
      ]) {
        final row = tester.getRect(
          find.byKey(ValueKey('app_state_illustration_${item.name}')),
        );
        expect(
          row.top * dpr - search.top * dpr,
          closeTo(304 * (item.index ~/ 2), 8),
        );
      }
      final label = tester.widget<Text>(find.text('搜索无结果'));
      expect(label.style?.fontSize, 15);
      expect(messages.center.dy, greaterThan(search.center.dy));
      expect(find.byKey(const ValueKey('vr13_back_arrow')), findsOneWidget);

      await expectLater(
        find.byKey(const ValueKey('vr13_catalog')),
        matchesGoldenFile('goldens/vr13_catalog.png'),
      );
    },
  );

  testWidgets(
    'VR13 AppStateView keeps the legacy icon when no illustration is set',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: vr13TestFontFamily),
          home: AppStateView(
            kind: AppStateKind.empty,
            title: '旧空态',
            message: '保持兼容',
          ),
        ),
      );

      expect(find.byType(AppStateIllustration), findsNothing);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    },
  );

  testWidgets('VR13 AppStateView renders the selected illustration and retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: vr13TestFontFamily),
        home: DefaultTextStyle(
          style: const TextStyle(fontFamily: vr13TestFontFamily),
          child: AppStateView(
            kind: AppStateKind.empty,
            title: '暂无评论',
            message: '还没有评论',
            illustration: AppStateIllustrationType.noComments,
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.byType(AppStateIllustration), findsOneWidget);
    expect(find.text('暂无评论'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retries, 1);
  });
}

class _Catalog extends StatelessWidget {
  const _Catalog();

  static const _items = [
    (AppStateIllustrationType.searchEmpty, '搜索无结果'),
    (AppStateIllustrationType.networkError, '网络故障'),
    (AppStateIllustrationType.noFollowing, '暂无关注'),
    (AppStateIllustrationType.noFollowingTeams, '暂无关注球队'),
    (AppStateIllustrationType.noHistory, '暂无浏览记录'),
    (AppStateIllustrationType.noComments, '暂无评论'),
    (AppStateIllustrationType.noFavorites, '暂无收藏'),
    (AppStateIllustrationType.noData, '暂无数据'),
    (AppStateIllustrationType.noMessages, '暂无消息'),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < _items.length; index += 2) {
      rows.add(_row(index));
    }
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: vr13TestFontFamily),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 48),
            SizedBox(
              height: 46,
              child: Row(
                children: [
                  const SizedBox(width: 22),
                  const _BackArrow(),
                  const Expanded(
                    child: Text(
                      '二级页标题',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff20232a),
                      ),
                    ),
                  ),
                  const SizedBox(width: 41),
                ],
              ),
            ),
            const SizedBox(height: 25),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(int index) {
    final children = <Widget>[
      Positioned(left: 46.25, top: 0, child: _item(_items[index])),
    ];
    if (index + 1 < _items.length) {
      children.add(
        Positioned(left: 199.55, top: 0, child: _item(_items[index + 1])),
      );
    }
    return SizedBox(height: 152, child: Stack(children: children));
  }

  Widget _item((AppStateIllustrationType, String) item) => SizedBox(
    width: 130,
    child: Column(
      children: [
        AppStateIllustration(type: item.$1, size: 64),
        const SizedBox(height: 12),
        Text(
          item.$2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Color(0xff6d6d6d)),
        ),
      ],
    ),
  );
}

class _BackArrow extends StatelessWidget {
  const _BackArrow();

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: const ValueKey('vr13_back_arrow'),
    size: const Size(24, 24),
    painter: _BackArrowPainter(),
  );
}

class _BackArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(16, 4)
      ..lineTo(8, 12)
      ..lineTo(16, 20);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
