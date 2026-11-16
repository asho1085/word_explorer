import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/screens/login_screen.dart';
import 'package:word_explorer/screens/mode_selection_screen.dart';
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

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkThemeData,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signing up from the login screen opens the home screen',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));

    await tester.enterText(fields.at(0), 'FlowPlayer');
    await tester.enterText(fields.at(1), 'flow@example.com');
    await tester.enterText(fields.at(2), 'StrongPass1');

    await tester.tap(find.text('Create Account'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(AuthService.instance.currentUser?.username, 'FlowPlayer');
    expect(find.byType(ModeSelectionScreen), findsOneWidget);
  });

  testWidgets('logging in with an existing account opens the home screen',
      (tester) async {
    await AuthService.instance.registerWithUsername(
      username: 'ReturningPlayer',
      email: 'returning@example.com',
      password: 'StrongPass1',
    );
    await AuthService.instance.logout();

    await pumpLogin(tester);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'ReturningPlayer');
    await tester.enterText(fields.at(1), 'StrongPass1');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(AuthService.instance.currentUser?.username, 'ReturningPlayer');
    expect(find.byType(ModeSelectionScreen), findsOneWidget);
  });

  testWidgets('wrong credentials keep the user on the login screen',
      (tester) async {
    await AuthService.instance.registerWithUsername(
      username: 'ReturningPlayer',
      email: 'returning@example.com',
      password: 'StrongPass1',
    );
    await AuthService.instance.logout();

    await pumpLogin(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ReturningPlayer');
    await tester.enterText(fields.at(1), 'WrongPass123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(AuthService.instance.isLoggedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Invalid username/email or password.'), findsOneWidget);
  });

  testWidgets('guest login opens the home screen', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Skip for now · Play as Guest'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(AuthService.instance.isLoggedIn, isTrue);
    expect(AuthService.instance.currentUser?.isGuest, isTrue);
    expect(find.byType(ModeSelectionScreen), findsOneWidget);
  });
}
