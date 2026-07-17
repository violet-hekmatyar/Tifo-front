import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/app/app.dart';

void main() {
  testWidgets('starts the F01 mobile skeleton', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TifoApp()));

    expect(find.text('南看台'), findsWidgets);
    expect(find.text('Flutter mobile initialized'), findsOneWidget);
    expect(find.text('F01 基础骨架'), findsOneWidget);
  });
}
