import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/screens/mode_selection_screen.dart';
import 'package:word_explorer/screens/level_selection_screen.dart';
import 'package:word_explorer/screens/login_screen.dart';
import 'package:word_explorer/services/auth_service.dart';
import 'package:word_explorer/services/database_service.dart';
import 'package:word_explorer/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'welcome_bonus_claimed': true});
    await DatabaseService.instance.init();
    await AuthService.instance.logout();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size logicalSize,
    required bool dark,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = logicalSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: AppTheme.lightThemeData,
        darkTheme: AppTheme.darkThemeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ModeSelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  const sizes = <Size>[
    Size(320, 480),
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
    Size(531, 558),
    Size(540, 1200),
    Size(800, 400),
  ];

  for (final size in sizes) {
    for (final dark in [true, false]) {
      testWidgets(
        'home fits ${size.width.toInt()}x${size.height.toInt()} dark=$dark',
        (tester) async {
          await pumpHome(tester, logicalSize: size, dark: dark);
          expect(find.text('English Mode'), findsOneWidget);
          expect(find.text('Hindi Mode'), findsOneWidget);
          expect(find.text('Duo Mode'), findsOneWidget);
          expect(find.text('Leaderboard'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final tab in ['coins', 'profile']) {
    for (final dark in [true, false]) {
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(800, 400),
      ]) {
        testWidgets('$tab fits $size dark=$dark with large text', (
          tester,
        ) async {
          await pumpHome(tester, logicalSize: size, dark: dark, textScale: 1.3);
          await tester.tap(find.byKey(ValueKey('nav-$tab')));
          await tester.pumpAndSettle();
          expect(
            find.text(tab == 'coins' ? 'My Coins' : 'My Profile'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(
            tab == 'profile'
                ? find.byTooltip('Back to Home')
                : find.byKey(const ValueKey('nav-home')),
          );
          await tester.pumpAndSettle();
          expect(find.text('SELECT MODE'), findsOneWidget);
        });
      }
    }
  }

  testWidgets('daily bonus can be cancelled and claimed only once', (
    tester,
  ) async {
    await AuthService.instance.continueAsGuest();
    await DatabaseService.instance.setWelcomeBonusClaimed();
    await DatabaseService.instance.setCoins(100);
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
    await tester.tap(find.byKey(const ValueKey('nav-coins')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Bonus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(DatabaseService.instance.getCoins(), 100);
    await tester.tap(find.text('Daily Bonus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claim +50'));
    await tester.pumpAndSettle();
    expect(DatabaseService.instance.getCoins(), 150);
    expect(find.text('Claimed today. Come back tomorrow!'), findsOneWidget);
    await tester.tap(find.text('Daily Bonus'));
    await tester.pumpAndSettle();
    expect(find.text('Claim +50'), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Watch Ad'), findsNothing);
    expect(DatabaseService.instance.getCoins(), 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile saves avatar and validates edited player name', (
    tester,
  ) async {
    await AuthService.instance.continueAsGuest();
    await DatabaseService.instance.setWelcomeBonusClaimed();
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-avatar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar-1')));
    await tester.pumpAndSettle();
    expect(
      AuthService.instance.currentUser?.avatar,
      AuthService.predefinedAvatars[1],
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Username must be at least 3 characters.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'New Explorer');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(AuthService.instance.currentUser?.username, 'New Explorer');
    expect(find.text('New Explorer'), findsOneWidget);
    await tester.ensureVisible(find.text('My Progress'));
    await tester.tap(find.text('My Progress'));
    await tester.pumpAndSettle();
    expect(find.text('English Mode: 0/50'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Back to Home'));
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('New Explorer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a guest account clears authenticated navigation', (
    tester,
  ) async {
    await AuthService.instance.continueAsGuest();
    await DatabaseService.instance.setWelcomeBonusClaimed();
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log In / Sign Up'));
    await tester.tap(find.text('Log In / Sign Up'));
    await tester.pumpAndSettle();
    expect(AuthService.instance.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ModeSelectionScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard tab and device back return to home', (tester) async {
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
    await tester.tap(find.byKey(const ValueKey('nav-leaderboard')));
    await tester.pumpAndSettle();
    expect(find.text('Star Leaderboard'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('SELECT MODE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-coins')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('SELECT MODE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all mode cards still open their level selection', (
    tester,
  ) async {
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
    for (final title in ['English Mode', 'Hindi Mode', 'Duo Mode']) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byType(LevelSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(LevelSelectionScreen))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'settings toggles persist and reset button is not present',
    (tester) async {
      await DatabaseService.instance.setCoins(125);
      await pumpHome(tester, logicalSize: const Size(390, 844), dark: true);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Light mode').hitTestable());
      await tester.pumpAndSettle();
      expect(DatabaseService.instance.isDarkMode(), isFalse);
      await tester.tap(find.byTooltip('Dark mode'));
      await tester.pumpAndSettle();
      expect(DatabaseService.instance.isDarkMode(), isTrue);
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();
      expect(DatabaseService.instance.getSoundEnabled(), isFalse);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      expect(DatabaseService.instance.getVibrationEnabled(), isFalse);
      expect(find.text('Reset Game Data'), findsNothing);
      expect(DatabaseService.instance.getCoins(), 125);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home fits with large accessibility text', (tester) async {
    await pumpHome(
      tester,
      logicalSize: const Size(360, 740),
      dark: true,
      textScale: 1.3,
    );
    expect(find.text('Duo Mode'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home does not scroll on common phone sizes', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 40);
    addTearDown(tester.view.resetPadding);
    for (final size in const [Size(390, 844), Size(412, 915)]) {
      await pumpHome(tester, logicalSize: size, dark: true);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(
        scrollable.position.maxScrollExtent,
        0,
        reason: 'home scrolls at ${size.width.toInt()}x${size.height.toInt()}',
      );
    }
  });

  testWidgets('privacy policy and version live in settings', (
    tester,
  ) async {
    await pumpHome(tester, logicalSize: const Size(390, 844), dark: false);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'opening settings');

    expect(find.text('About'), findsNothing);
    expect(find.text('Write a Review'), findsNothing);
    expect(find.text('Reset Game Data'), findsNothing);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.1'), findsOneWidget);

    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'opening privacy');
    expect(find.text('Privacy Policy & Data Safety'), findsOneWidget);
    expect(find.text('What We Collect'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'closing privacy');

    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fits with large accessibility text', (tester) async {
    await pumpHome(
      tester,
      logicalSize: const Size(360, 740),
      dark: true,
      textScale: 1.3,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsNothing);
    expect(find.text('Write a Review'), findsNothing);
    expect(find.text('Reset Game Data'), findsNothing);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('1.0.1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
