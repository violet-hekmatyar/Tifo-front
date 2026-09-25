import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/theme/app_theme.dart';
import 'package:tifo/core/network/backend_v1_contract.dart';
import 'package:tifo/features/search/data/search_repository.dart';
import 'package:tifo/features/search/domain/search_models.dart';
import 'package:tifo/features/search/presentation/pages/global_search_page.dart';

void main() {
  testWidgets(
    'VR8 real empty search hides filters and uses dedicated empty view',
    (tester) async {
      tester.view.physicalSize = const Size(360, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchRepositoryProvider.overrideWithValue(_EmptySearch()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const GlobalSearchPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('global_search_input')),
        'vr8-unique-no-result',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_empty')), findsOneWidget);
      expect(find.text('搜索无结果'), findsOneWidget);
      expect(find.byKey(const ValueKey('search_filter_all')), findsNothing);
      expect(find.byKey(const ValueKey('search_filter_TEAM')), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('global_search_input'))).right,
        lessThanOrEqualTo(360),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('VR8-R1 search empty geometry is compact and upper anchored', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(_EmptySearch())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GlobalSearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('global_search_input')),
      'vr8-r1-no-result',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final input = tester.getRect(
      find.byKey(const ValueKey('global_search_input')),
    );
    final illustration = tester.getRect(
      find.byKey(const ValueKey('search_empty_illustration')),
    );
    final label = tester.getRect(find.text('搜索无结果'));
    final emptyView = tester.getRect(
      find.byKey(const ValueKey('search_empty')),
    );
    final visualGroup = Rect.fromLTRB(
      illustration.left,
      illustration.top,
      label.right,
      label.bottom,
    );
    final appBar = tester.getRect(find.byType(AppBar));
    // Prototype 750x1624 is a 2x capture of a 375dp canvas. The test view
    // omits the device status bar, so compare the input to the AppBar bottom.
    // At 360dp the relative top is 8dp and the height is 39.36dp.
    // illustration width = 120 / 2 * .96 = 57.6dp;
    // Empty artwork is measured in its own content-relative group. The
    // prototype's empty group center is about 213.3dp below that view's top.
    expect(input.top - appBar.bottom, closeTo(8, 8 * .08));
    expect(input.height, closeTo(39.36, 39.36 * .08));
    expect(input.left, closeTo(20, 20 * .08));
    expect(input.right, closeTo(340, 340 * .08));
    expect(illustration.width, closeTo(57.6, 57.6 * .08));
    expect(visualGroup.center.dx, closeTo(180, 180 * .08));
    expect(visualGroup.center.dy - emptyView.top, closeTo(213.3, 213.3 * .08));
    expect(tester.takeException(), isNull);
  });

  testWidgets('VR8-R1 non-selection search has no submit arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(_EmptySearch())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GlobalSearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('global_search_submit')), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('global_search_input'))).height,
      lessThanOrEqualTo(52),
    );
  });
}

final class _EmptySearch implements SearchRepositoryContract {
  @override
  Future<SearchPageResult> search({
    required String keyword,
    required int pageNum,
    required int pageSize,
    SearchEntityType? entityType,
  }) async => const SearchPageResult(
    records: [],
    total: 0,
    pageNum: 1,
    pageSize: 20,
    pages: 1,
  );
}
