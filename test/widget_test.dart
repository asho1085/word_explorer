import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/main.dart';
import 'package:word_explorer/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.init();
  });

  testWidgets('WordSearchExplorerApp loads mode selection screen', (WidgetTester tester) async {
    // Set viewport large enough for cards
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const WordSearchExplorerApp());
    expect(find.text('WORD SEARCH'), findsOneWidget);

    // Advance time past the splash screen transition
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Master Mode'), findsOneWidget);
    expect(find.text('English Mode'), findsOneWidget);
    expect(find.text('Hindi Mode'), findsOneWidget);
  });
}
