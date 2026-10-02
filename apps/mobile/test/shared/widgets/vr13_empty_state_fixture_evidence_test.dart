import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/shared/widgets/app_state_illustration.dart';
import 'package:tifo/shared/widgets/app_state_view.dart';

import 'vr13_test_font.dart';

void main() {
  setUpAll(loadVr13TestFont);

  const fixtures = [
    (AppStateIllustrationType.noFollowing, '暂无关注', '还没有关注任何用户。'),
    (AppStateIllustrationType.noFollowingTeams, '暂无关注球队', '关注球队后，这里会显示最新动态。'),
    (AppStateIllustrationType.noComments, '暂无评论', '还没有评论。'),
    (AppStateIllustrationType.noFavorites, '暂无收藏', '收藏内容后，这里会显示你的收藏。'),
    (AppStateIllustrationType.noData, '暂无数据', '暂时没有可展示的数据。'),
    (AppStateIllustrationType.noMessages, '暂无互动消息', '点赞、评论、回复和关注消息会显示在这里。'),
  ];

  for (final fixture in fixtures) {
    testWidgets('VR13 ${fixture.$1.name} production AppStateView fixture', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(750, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: vr13TestFontFamily),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: RepaintBoundary(
              key: ValueKey('vr13_fixture_${fixture.$1.name}'),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: vr13TestFontFamily,
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xff20232a),
                ),
                child: AppStateView(
                  kind: AppStateKind.empty,
                  title: fixture.$2,
                  message: fixture.$3,
                  illustration: fixture.$1,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppStateView), findsOneWidget);
      expect(find.byType(AppStateIllustration), findsOneWidget);
      expect(find.text(fixture.$2), findsOneWidget);
      expect(find.text(fixture.$3), findsOneWidget);
      expect(
        find.byKey(ValueKey('app_state_illustration_${fixture.$1.name}')),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(ValueKey('vr13_fixture_${fixture.$1.name}')),
        matchesGoldenFile('goldens/vr13_fixtures/${fixture.$1.name}.png'),
      );
    });
  }
}
