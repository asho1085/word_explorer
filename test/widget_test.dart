import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/main.dart';
import 'package:word_explorer/screens/game_screen.dart';
import 'package:word_explorer/screens/login_screen.dart';
import 'package:word_explorer/services/ad_service.dart';
import 'package:word_explorer/services/database_service.dart';
import 'package:word_explorer/widgets/banner_ad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.init();
  });

  test('AdService is disabled for ad-free release', () {
    expect(AdService.adsEnabled, isFalse);
  });

  testWidgets('BannerAdWidget renders empty box in ad-free release', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BannerAdWidget(),
        ),
      ),
    );
    expect(find.byType(BannerAdWidget), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('Test Ad'), findsNothing);
    expect(find.text('Google AdMob Banner'), findsNothing);
  });

  testWidgets('WordSearchExplorerApp loads login screen when logged out', (WidgetTester tester) async {
    // Set viewport large enough for cards
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const WordSearchExplorerApp());
    expect(find.text('WORD SEARCH'), findsOneWidget);

    // Advance time past the splash screen transition
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    // Google login is hidden from the screen for this release
    expect(find.text('Continue with Google (Gmail)'), findsNothing);
    expect(find.text('Skip for now · Play as Guest'), findsOneWidget);

    // Ensure no ad widgets or text appear
    expect(find.text('Test Ad'), findsNothing);
    expect(find.text('Google AdMob Banner'), findsNothing);
  });

  testWidgets('GameScreen hint uses coins without watch ad option', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await DatabaseService.instance.setCoins(200);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(mode: 'english', level: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap hint button
    final hintBtn = find.text('Hint (30🪙)');
    expect(hintBtn, findsOneWidget);
    await tester.tap(hintBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify hint confirmation dialog shows coins option and NO watch ad
    expect(find.text('Get a Word Hint'), findsOneWidget);
    expect(find.text('Watch Video Ad'), findsNothing);
    expect(find.text('FREE Hint + 50 Bonus Coins 🎉'), findsNothing);
    expect(find.text('Use Hint (30 Coins)'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
