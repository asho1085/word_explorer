import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/services/auth_service.dart';

const _accountsKey = 'registered_accounts_db';
const _sessionKey = 'current_user_profile';

const _password = 'Secret12345';

Future<void> _reset() async {
  SharedPreferences.setMockInitialValues({});
  await AuthService.instance.logout();
}

Future<Map<String, dynamic>> _accounts() async {
  final prefs = await SharedPreferences.getInstance();
  return Map<String, dynamic>.from(
    jsonDecode(prefs.getString(_accountsKey) ?? '{}') as Map,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_reset);

  group('registration and login', () {
    test('registers and logs in with email and username', () async {
      final registered = await AuthService.instance.registerWithUsername(
        username: 'WordMaster',
        email: 'player@example.com',
        password: _password,
      );
      expect(registered.username, 'WordMaster');
      expect(AuthService.instance.isLoggedIn, isTrue);

      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      final byEmail = await AuthService.instance.loginWithUsernameOrEmail(
        identifier: 'PLAYER@EXAMPLE.COM',
        password: _password,
      );
      expect(byEmail.uid, registered.uid);

      await AuthService.instance.logout();

      final byUsername = await AuthService.instance.loginWithUsernameOrEmail(
        identifier: 'wordmaster',
        password: _password,
      );
      expect(byUsername.username, 'WordMaster');
    });

    test('rejects wrong passwords and weak signup passwords', () async {
      await expectLater(
        AuthService.instance.registerWithUsername(
          username: 'PlayerOne',
          email: 'one@example.com',
          password: 'short1',
        ),
        throwsA(isA<AuthException>()),
      );

      await expectLater(
        AuthService.instance.registerWithUsername(
          username: 'PlayerOne',
          email: 'one@example.com',
          password: 'onlyletters',
        ),
        throwsA(isA<AuthException>()),
      );

      await AuthService.instance.registerWithUsername(
        username: 'PlayerOne',
        email: 'one@example.com',
        password: _password,
      );

      await expectLater(
        AuthService.instance.loginWithUsernameOrEmail(
          identifier: 'one@example.com',
          password: 'WrongPassword1',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Invalid username/email or password'),
          ),
        ),
      );
    });

    test('never stores the password in plain text', () async {
      await AuthService.instance.registerWithUsername(
        username: 'SecureUser',
        email: 'secure@example.com',
        password: _password,
      );

      final prefs = await SharedPreferences.getInstance();
      final rawAccounts = prefs.getString(_accountsKey) ?? '';
      final rawSession = prefs.getString(_sessionKey) ?? '';

      expect(rawAccounts.contains(_password), isFalse);
      expect(rawSession.contains(_password), isFalse);

      final account = (await _accounts())['secure@example.com'] as Map;
      expect(account['password'], isNull);
      expect(account['passwordHash'], isA<String>());
      expect(account['passwordSalt'], isA<String>());
      expect((account['passwordIterations'] as num).toInt(), greaterThan(1000));
    });

    test('rejects duplicate usernames and emails', () async {
      await AuthService.instance.registerWithUsername(
        username: 'TakenName',
        email: 'first@example.com',
        password: _password,
      );
      await AuthService.instance.logout();

      await expectLater(
        AuthService.instance.registerWithUsername(
          username: 'takenname',
          email: 'second@example.com',
          password: _password,
        ),
        throwsA(isA<AuthException>()),
      );

      await expectLater(
        AuthService.instance.registerWithUsername(
          username: 'OtherName',
          email: 'FIRST@example.com',
          password: _password,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('locks the account after repeated failed attempts', () async {
      await AuthService.instance.registerWithUsername(
        username: 'LockedOut',
        email: 'lock@example.com',
        password: _password,
      );
      await AuthService.instance.logout();

      for (var i = 0; i < AuthService.maxFailedAttempts; i++) {
        await expectLater(
          AuthService.instance.loginWithUsernameOrEmail(
            identifier: 'lock@example.com',
            password: 'WrongPassword1',
          ),
          throwsA(isA<AuthException>()),
        );
      }

      // Even the correct password is rejected while the lock is active.
      await expectLater(
        AuthService.instance.loginWithUsernameOrEmail(
          identifier: 'lock@example.com',
          password: _password,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Too many failed attempts'),
          ),
        ),
      );
    });
  });

  group('Google sign-in', () {
    test('cannot take over an existing password account', () async {
      final original = await AuthService.instance.registerWithUsername(
        username: 'PasswordUser',
        email: 'shared@example.com',
        password: _password,
      );
      await AuthService.instance.logout();

      await expectLater(
        AuthService.instance.signInWithGoogle(
          email: 'shared@example.com',
          username: 'Attacker',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('registered with a password'),
          ),
        ),
      );

      // The original account still logs in after the rejected attempt.
      final user = await AuthService.instance.loginWithUsernameOrEmail(
        identifier: 'shared@example.com',
        password: _password,
      );
      expect(user.uid, original.uid);
      expect(user.username, 'PasswordUser');
    });

    test('keeps the uid and profile of an existing Google account', () async {
      final first = await AuthService.instance.signInWithGoogle(
        email: 'gmail.user@gmail.com',
        username: 'GmailUser',
      );
      await AuthService.instance.logout();

      final second = await AuthService.instance.signInWithGoogle(
        email: 'gmail.user@gmail.com',
        username: '',
      );

      expect(second.uid, first.uid);
      expect(second.username, 'GmailUser');
      expect(second.provider, 'google');
    });

    test('rejects a username already used by another account', () async {
      await AuthService.instance.registerWithUsername(
        username: 'UniqueName',
        email: 'unique@example.com',
        password: _password,
      );
      await AuthService.instance.logout();

      await expectLater(
        AuthService.instance.signInWithGoogle(
          email: 'another@gmail.com',
          username: 'uniquename',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('sessions', () {
    test('restores a valid session after init', () async {
      final user = await AuthService.instance.registerWithUsername(
        username: 'SessionUser',
        email: 'session@example.com',
        password: _password,
      );

      AuthService.instance.userNotifier.value = null;
      await AuthService.instance.init();

      expect(AuthService.instance.currentUser?.uid, user.uid);
    });

    test('rejects an expired session', () async {
      await AuthService.instance.registerWithUsername(
        username: 'ExpiredUser',
        email: 'expired@example.com',
        password: _password,
      );

      final prefs = await SharedPreferences.getInstance();
      final session = jsonDecode(prefs.getString(_sessionKey)!) as Map<String, dynamic>;
      session['expiresAt'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 1))
          .toIso8601String();
      await prefs.setString(_sessionKey, jsonEncode(session));

      AuthService.instance.userNotifier.value = null;
      await AuthService.instance.init();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(prefs.getString(_sessionKey), isNull);
    });

    test('rejects a tampered session', () async {
      await AuthService.instance.registerWithUsername(
        username: 'TamperUser',
        email: 'tamper@example.com',
        password: _password,
      );

      final prefs = await SharedPreferences.getInstance();
      final session = jsonDecode(prefs.getString(_sessionKey)!) as Map<String, dynamic>;
      (session['user'] as Map<String, dynamic>)['uid'] = 'user_forged';
      await prefs.setString(_sessionKey, jsonEncode(session));

      AuthService.instance.userNotifier.value = null;
      await AuthService.instance.init();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(prefs.getString(_sessionKey), isNull);
    });

    test('guest sessions survive init but cannot masquerade as accounts', () async {
      final guest = await AuthService.instance.continueAsGuest();
      expect(guest.isGuest, isTrue);
      expect(guest.username, startsWith('Explorer #'));

      AuthService.instance.userNotifier.value = null;
      await AuthService.instance.init();
      expect(AuthService.instance.currentUser?.uid, guest.uid);

      final prefs = await SharedPreferences.getInstance();
      final session = jsonDecode(prefs.getString(_sessionKey)!) as Map<String, dynamic>;
      (session['user'] as Map<String, dynamic>)['uid'] = 'user_forged';
      await prefs.setString(_sessionKey, jsonEncode(session));

      AuthService.instance.userNotifier.value = null;
      await AuthService.instance.init();
      expect(AuthService.instance.isLoggedIn, isFalse);
    });
  });

  group('migration and profile updates', () {
    test('upgrades a legacy plain-text account on login', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _accountsKey,
        jsonEncode({
          'legacy@example.com': {
            'uid': 'user_legacy',
            'username': 'LegacyUser',
            'email': 'legacy@example.com',
            'avatar': '🦊',
            'isGuest': false,
            'provider': 'password',
            'createdAt': DateTime.now().toIso8601String(),
            'password': 'Legacy12345',
          },
        }),
      );

      final user = await AuthService.instance.loginWithUsernameOrEmail(
        identifier: 'legacy@example.com',
        password: 'Legacy12345',
      );
      expect(user.username, 'LegacyUser');

      final account = (await _accounts())['legacy@example.com'] as Map;
      expect(account['password'], isNull);
      expect(account['passwordHash'], isA<String>());

      // The upgraded account still accepts the same password.
      await AuthService.instance.logout();
      final again = await AuthService.instance.loginWithUsernameOrEmail(
        identifier: 'LegacyUser',
        password: 'Legacy12345',
      );
      expect(again.uid, 'user_legacy');
    });

    test('prevents renaming to an existing username', () async {
      await AuthService.instance.registerWithUsername(
        username: 'FirstPlayer',
        email: 'first@example.com',
        password: _password,
      );
      await AuthService.instance.logout();
      await AuthService.instance.registerWithUsername(
        username: 'SecondPlayer',
        email: 'second@example.com',
        password: _password,
      );

      await expectLater(
        AuthService.instance.updateUsername('firstplayer'),
        throwsA(isA<AuthException>()),
      );

      await AuthService.instance.updateUsername('RenamedPlayer');
      expect(AuthService.instance.currentUser?.username, 'RenamedPlayer');
    });
  });
}
