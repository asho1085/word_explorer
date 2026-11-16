import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/user_model.dart';
import 'cloud_db.dart';
import 'database_service.dart';

/// Thrown for expected authentication failures with a user-safe message.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication Service.
///
/// Firebase Authentication is the source of truth for cloud accounts. A local
/// profile cache keeps usernames/avatars and allows guest play (and legacy
/// accounts created by older builds) while offline.
///
/// Security notes:
/// * Cloud passwords are handled exclusively by Firebase Auth; only
///   Firebase's hashed credentials are stored.
/// * Legacy local accounts use salted PBKDF2-HMAC-SHA256 hashes and are
///   transparently verified without storing plain text.
/// * Local sessions expire and are validated against the account directory.
/// * Repeated failed legacy logins temporarily lock the account.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  static const String _userKey = 'current_user_profile';
  static const String _registeredUsersKey = 'registered_accounts_db';

  // PBKDF2-HMAC-SHA256 parameters (legacy/offline accounts only).
  static const int passwordHashIterations = 60000;
  static const int _saltBytes = 16;
  static const int _hashBytes = 32;

  // Brute-force protection for legacy local accounts.
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 1);

  // Local session cache lifetime.
  static const Duration sessionLifetime = Duration(days: 30);

  // Web OAuth client from google-services.json, used to request an ID token
  // for Google Sign-In on Android.
  static const String _googleServerClientId =
      '462304291385-99g8j39c4mmnn1luqvldhe3s8ob7nmjs.apps.googleusercontent.com';

  /// Predefined game avatars available for players
  static const List<String> predefinedAvatars = [
    '🦊', // Swift Fox
    '🦁', // Brave Lion
    '🦉', // Wise Owl
    '🐯', // Thunder Tiger
    '🐼', // Zen Panda
    '🐺', // Shadow Wolf
    '🦅', // Sky Eagle
    '🐲', // Mythic Dragon
    '🦄', // Starlight Unicorn
    '🐬', // Wave Dolphin
    '🦈', // Apex Shark
    '🦖', // Primal Dino
    '👑', // Royal Crown
    '🧙', // Mystic Mage
    '🥷', // Silent Ninja
    '⚔️', // Brave Knight
    '🦸', // Super Champion
    '🕵️', // Master Sleuth
    '🚀', // Cosmic Rocket
    '💎', // Diamond Master
    '🪐', // Saturn Explorer
    '⚡', // Thunder Spark
    '🌟', // Golden Star
    '🏆', // Victory Trophy
  ];

  /// Human-friendly display names for each avatar
  static const Map<String, String> avatarNames = {
    '🦊': 'Swift Fox',
    '🦁': 'Brave Lion',
    '🦉': 'Wise Owl',
    '🐯': 'Thunder Tiger',
    '🐼': 'Zen Panda',
    '🐺': 'Shadow Wolf',
    '🦅': 'Sky Eagle',
    '🐲': 'Mythic Dragon',
    '🦄': 'Starlight Unicorn',
    '🐬': 'Wave Dolphin',
    '🦈': 'Apex Shark',
    '🦖': 'Primal Dino',
    '👑': 'Royal Crown',
    '🧙': 'Mystic Mage',
    '🥷': 'Silent Ninja',
    '⚔️': 'Brave Knight',
    '🦸': 'Super Champion',
    '🕵️': 'Master Sleuth',
    '🚀': 'Cosmic Rocket',
    '💎': 'Diamond Master',
    '🪐': 'Saturn Explorer',
    '⚡': 'Thunder Spark',
    '🌟': 'Golden Star',
    '🏆': 'Victory Trophy',
  };

  static bool _cloudAttempted = false;
  static bool _cloudReady = false;

  /// True when Firebase Authentication is initialized and usable.
  static bool get isCloudAvailable => _cloudReady;

  /// True when the app tried to initialize Firebase at startup.
  static bool get cloudInitAttempted => _cloudAttempted;

  final ValueNotifier<UserModel?> userNotifier = ValueNotifier<UserModel?>(null);

  UserModel? get currentUser => userNotifier.value;
  bool get isLoggedIn => userNotifier.value != null;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  /// Initializes Firebase. Call once at startup before [init].
  Future<void> initializeFirebase() async {
    _cloudAttempted = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _cloudReady = true;
      debugPrint('[AuthService] Firebase Authentication ready.');
    } catch (e) {
      _cloudReady = false;
      debugPrint('[AuthService] Firebase initialization failed: $e');
    }
  }

  // ── Validation ───────────────────────────────────────────────

  /// Returns an error message when [value] is not a usable username.
  static String? validateUsername(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Please enter a username.';
    if (clean.length < 3) return 'Username must be at least 3 characters.';
    if (clean.length > 20) return 'Username must be 20 characters or fewer.';
    if (RegExp(r'[\u0000-\u001F\u007F<>"\\/]').hasMatch(clean)) {
      return 'Username contains invalid characters.';
    }
    if (!RegExp(r'^[a-zA-Z0-9 _#\-]+$').hasMatch(clean)) {
      return 'Username can only contain letters, numbers, spaces, and hyphens.';
    }
    if (RegExp(r'(https?://|www\.|\.com|\.net|\.org|\.io|\.xyz)', caseSensitive: false).hasMatch(clean)) {
      return 'Usernames cannot contain website links or URLs.';
    }
    return null;
  }

  /// Returns an error message when [value] is not a valid email address.
  static String? validateEmail(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Please enter an email address.';
    if (clean.length > 254) return 'Email address is too long.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Strong password policy used for new accounts.
  static String? validatePasswordStrength(String value) {
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (value.length > 128) return 'Password must be 128 characters or fewer.';
    final hasLetter = RegExp('[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp('[0-9]').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Password must include at least one letter and one number.';
    }
    return null;
  }

  static String normaliseEmail(String email) => email.trim().toLowerCase();

  // ── Lifecycle ────────────────────────────────────────────────

  /// Initialize and restore a valid session if one is available.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_cloudReady) {
        try {
          final firebaseUser = _auth.currentUser;
          if (firebaseUser != null) {
            final user = _userFromFirebase(firebaseUser, prefs);
            await _persistCloudUser(user, prefs);
            return;
          }
        } catch (e) {
          debugPrint('[AuthService] Firebase session restore error: $e');
        }
      }

      await _restoreLocalSession(prefs);
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
    }
  }

  Future<void> _restoreLocalSession(SharedPreferences prefs) async {
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic>? userMap;
    DateTime? expiresAt;
    var legacySession = false;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['user'] is Map) {
        userMap = Map<String, dynamic>.from(decoded['user'] as Map);
        expiresAt = DateTime.tryParse(decoded['expiresAt']?.toString() ?? '');
      } else if (decoded.containsKey('uid')) {
        userMap = decoded;
        legacySession = true;
      }
    } catch (_) {
      await prefs.remove(_userKey);
      return;
    }

    if (userMap == null) {
      await prefs.remove(_userKey);
      return;
    }

    if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
      await prefs.remove(_userKey);
      return;
    }

    final user = UserModel.fromMap(userMap);
    if (!_isValidSessionUser(user, prefs)) {
      await prefs.remove(_userKey);
      return;
    }

    // A cloud account's cached session is only usable while Firebase still has
    // an active user for it; otherwise the account was signed out remotely.
    if (_cloudReady && !user.isGuest) {
      final account = _loadAccounts(prefs)[user.email];
      final isCloudAccount = account != null &&
          (account['passwordHash'] == null || account['passwordHash'].toString().isEmpty);
      if (isCloudAccount && _auth.currentUser == null) {
        await prefs.remove(_userKey);
        return;
      }
    }

    userNotifier.value = user;
    await DatabaseService.instance.setActiveUser(user.uid);
    if (legacySession) {
      await _saveSession(user, prefs);
    }
  }

  /// A session must belong to an existing account (or be a guest profile).
  bool _isValidSessionUser(UserModel user, SharedPreferences prefs) {
    if (user.isGuest) {
      return user.uid.startsWith('guest_') || _cloudReady;
    }
    if (user.email.isEmpty) return false;
    final account = _loadAccounts(prefs)[user.email];
    return account != null && account['uid']?.toString() == user.uid;
  }

  // ── Registration / Login ─────────────────────────────────────

  /// Register a new account with username, email, and password.
  Future<UserModel> registerWithUsername({
    required String username,
    required String email,
    required String password,
    String avatar = '🦊',
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = normaliseEmail(email);

    final usernameError = validateUsername(cleanUsername);
    if (usernameError != null) throw AuthException(usernameError);

    final emailError = validateEmail(cleanEmail);
    if (emailError != null) throw AuthException(emailError);

    final passwordError = validatePasswordStrength(password);
    if (passwordError != null) throw AuthException(passwordError);

    final safeAvatar = predefinedAvatars.contains(avatar) ? avatar : '🦊';

    final prefs = await SharedPreferences.getInstance();
    final accounts = _loadAccounts(prefs);

    for (final acc in accounts.values) {
      if ((acc['username']?.toString().toLowerCase() ?? '') ==
          cleanUsername.toLowerCase()) {
        throw AuthException('Username "$cleanUsername" is already taken.');
      }
      if ((acc['email']?.toString().toLowerCase() ?? '') == cleanEmail &&
          acc['provider']?.toString() != 'google') {
        throw AuthException('An account with this email already exists.');
      }
    }

    if (_cloudReady) {
      return _registerWithFirebase(
        prefs: prefs,
        username: cleanUsername,
        email: cleanEmail,
        password: password,
        avatar: safeAvatar,
      );
    }

    if (_cloudAttempted) {
      throw const AuthException(
        'Cloud sign-in is unavailable. Check your internet connection and try again.',
      );
    }

    // Offline/local mode (e.g. unit tests or a device without Firebase).
    return _registerLocally(
      prefs: prefs,
      accounts: accounts,
      username: cleanUsername,
      email: cleanEmail,
      password: password,
      avatar: safeAvatar,
    );
  }

  Future<UserModel> _registerWithFirebase({
    required SharedPreferences prefs,
    required String username,
    required String email,
    required String password,
    required String avatar,
  }) async {
    try {
      fb.UserCredential credential;
      final currentFbUser = _auth.currentUser;
      if (currentFbUser != null && currentFbUser.isAnonymous) {
        try {
          final authCred = fb.EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          credential = await currentFbUser.linkWithCredential(authCred);
        } on fb.FirebaseAuthException {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      try {
        await credential.user?.updateDisplayName(username);
      } catch (_) {}

      final user = UserModel(
        uid: credential.user!.uid,
        username: username,
        email: email,
        avatar: avatar,
        isGuest: false,
        provider: 'password',
        createdAt: DateTime.now(),
      );
      await _persistCloudUser(user, prefs);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Firebase register error: ${e.code}');
      throw AuthException(_firebaseMessage(e));
    } catch (e) {
      debugPrint('[AuthService] Register error: $e');
      throw const AuthException(
        'Sign-up failed. Check your internet connection and try again.',
      );
    }
  }

  Future<UserModel> _registerLocally({
    required SharedPreferences prefs,
    required Map<String, Map<String, dynamic>> accounts,
    required String username,
    required String email,
    required String password,
    required String avatar,
  }) async {
    final salt = _generateSalt();
    final user = UserModel(
      uid: _newUid('user'),
      username: username,
      email: email,
      avatar: avatar,
      isGuest: false,
      provider: 'password',
      createdAt: DateTime.now(),
    );

    accounts[email] = {
      ...user.toMap(),
      'passwordHash': _hashPassword(password, salt, passwordHashIterations),
      'passwordSalt': salt,
      'passwordIterations': passwordHashIterations,
      'failedAttempts': 0,
      'lockedUntil': null,
    };
    await _saveAccounts(accounts, prefs);
    await _saveSession(user, prefs);
    return user;
  }

  /// Login with either Username or Email + Password.
  Future<UserModel> loginWithUsernameOrEmail({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) {
      throw const AuthException('Please enter your username or email.');
    }
    if (password.isEmpty) {
      throw const AuthException('Please enter your password.');
    }
    if (cleanId.length > 254) {
      throw const AuthException('Invalid username or email.');
    }

    final cleanLower = cleanId.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final accounts = _loadAccounts(prefs);

    var email = normaliseEmail(cleanId);
    if (!cleanId.contains('@')) {
      final resolved = _findEmailByUsername(accounts, cleanLower);
      if (resolved == null) {
        throw const AuthException(
          'No account on this device matches that username. Please log in with your email address.',
        );
      }
      email = resolved;
    }

    if (_cloudReady) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = _userFromFirebase(credential.user!, prefs);
        await _persistCloudUser(user, prefs);
        return user;
      } on fb.FirebaseAuthException catch (e) {
        debugPrint('[AuthService] Firebase login error: ${e.code}');

        // Offline / legacy fallback: accounts created by older builds are
        // still stored locally with a password hash.
        if (e.code == 'network-request-failed' ||
            e.code == 'user-not-found' ||
            e.code == 'invalid-credential') {
          final localUser = await _verifyLocalAccount(
            identifierLower: cleanLower,
            email: email,
            password: password,
            prefs: prefs,
            accounts: accounts,
            enableLockout: false,
          );
          if (localUser != null) return localUser;
        }
        throw AuthException(_firebaseMessage(e));
      } catch (e) {
        debugPrint('[AuthService] Login error: $e');
        throw const AuthException(
          'Sign-in failed. Check your internet connection and try again.',
        );
      }
    }

    if (_cloudAttempted) {
      final localUser = await _verifyLocalAccount(
        identifierLower: cleanLower,
        email: email,
        password: password,
        prefs: prefs,
        accounts: accounts,
        enableLockout: false,
      );
      if (localUser != null) return localUser;
      throw const AuthException(
        'Cloud sign-in is unavailable right now. Check your internet connection and try again.',
      );
    }

    return _loginLocally(
      identifierLower: cleanLower,
      email: email,
      password: password,
      prefs: prefs,
      accounts: accounts,
    );
  }

  /// Local-only login used when Firebase is not enabled (offline/unit tests).
  Future<UserModel> _loginLocally({
    required String identifierLower,
    required String email,
    required String password,
    required SharedPreferences prefs,
    required Map<String, Map<String, dynamic>> accounts,
  }) async {
    Map<String, dynamic>? matched;
    for (final acc in accounts.values) {
      final accEmail = acc['email']?.toString().toLowerCase() ?? '';
      final accUsername = acc['username']?.toString().toLowerCase() ?? '';
      if (accEmail == email || accUsername == identifierLower) {
        matched = acc;
        break;
      }
    }

    if (matched == null) {
      _hashPassword(password, _dummySalt, passwordHashIterations);
      throw const AuthException('Invalid username/email or password.');
    }

    final now = DateTime.now();
    final lockedUntil = DateTime.tryParse(matched['lockedUntil']?.toString() ?? '');
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      final seconds = lockedUntil.difference(now).inSeconds + 1;
      throw AuthException(
        'Too many failed attempts. Try again in $seconds seconds.',
      );
    }

    final storedHash = matched['passwordHash']?.toString();
    final salt = matched['passwordSalt']?.toString();
    final iterations =
        (matched['passwordIterations'] as num?)?.toInt() ?? passwordHashIterations;

    var verified = false;
    if (storedHash != null && storedHash.isNotEmpty && salt != null && salt.isNotEmpty) {
      final computed = _hashPassword(password, salt, iterations);
      verified = _constantTimeEquals(computed, storedHash);
    } else if (matched['password'] != null) {
      verified = _constantTimeEquals(matched['password'].toString(), password);
      if (verified) {
        final newSalt = _generateSalt();
        matched
          ..['passwordSalt'] = newSalt
          ..['passwordHash'] = _hashPassword(password, newSalt, passwordHashIterations)
          ..['passwordIterations'] = passwordHashIterations
          ..remove('password');
        await _saveAccounts(accounts, prefs);
      }
    }

    if (!verified) {
      final attempts = ((matched['failedAttempts'] as num?)?.toInt() ?? 0) + 1;
      if (attempts >= maxFailedAttempts) {
        matched['failedAttempts'] = 0;
        matched['lockedUntil'] = now.add(lockoutDuration).toIso8601String();
        await _saveAccounts(accounts, prefs);
        throw AuthException(
          'Too many failed attempts. Try again in ${lockoutDuration.inSeconds} seconds.',
        );
      }
      matched['failedAttempts'] = attempts;
      await _saveAccounts(accounts, prefs);
      throw const AuthException('Invalid username/email or password.');
    }

    matched['failedAttempts'] = 0;
    matched['lockedUntil'] = null;
    await _saveAccounts(accounts, prefs);

    final user = UserModel.fromMap(matched);
    await _saveSession(user, prefs);
    return user;
  }

  /// Verifies a legacy local account without throwing. Returns null when the
  /// credentials do not match.
  Future<UserModel?> _verifyLocalAccount({
    required String identifierLower,
    required String email,
    required String password,
    required SharedPreferences prefs,
    required Map<String, Map<String, dynamic>> accounts,
    required bool enableLockout,
  }) async {
    Map<String, dynamic>? matched;
    for (final acc in accounts.values) {
      final accEmail = acc['email']?.toString().toLowerCase() ?? '';
      final accUsername = acc['username']?.toString().toLowerCase() ?? '';
      if (accEmail == email || accUsername == identifierLower) {
        matched = acc;
        break;
      }
    }
    if (matched == null) return null;

    final storedHash = matched['passwordHash']?.toString();
    final salt = matched['passwordSalt']?.toString();
    final iterations =
        (matched['passwordIterations'] as num?)?.toInt() ?? passwordHashIterations;

    var verified = false;
    if (storedHash != null && storedHash.isNotEmpty && salt != null && salt.isNotEmpty) {
      verified = _constantTimeEquals(
        _hashPassword(password, salt, iterations),
        storedHash,
      );
    } else if (matched['password'] != null) {
      verified = _constantTimeEquals(matched['password'].toString(), password);
    }

    if (!verified) return null;

    final user = UserModel.fromMap(matched);
    await _saveSession(user, prefs);
    return user;
  }

  /// Sign in with Google through Firebase Authentication.
  ///
  /// [email] and [username] are only used by the offline/local fallback.
  Future<UserModel> signInWithGoogle({
    String email = '',
    String username = '',
    String avatar = '👑',
    String? photoUrl,
  }) async {
    if (!_cloudReady) {
      if (_cloudAttempted) {
        throw const AuthException(
          'Google sign-in needs an internet connection. Check your network and try again.',
        );
      }
      return _localGoogleSignIn(
        email: email,
        username: username,
        avatar: avatar,
        photoUrl: photoUrl,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    try {
      fb.UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn(
          scopes: const ['email'],
          serverClientId: _googleServerClientId,
        ).signIn();

        if (googleUser == null) {
          throw const AuthException('Google sign-in was cancelled.');
        }

        final googleAuth = await googleUser.authentication;
        final oauthCredential = fb.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        final currentFbUser = _auth.currentUser;
        if (currentFbUser != null && currentFbUser.isAnonymous) {
          try {
            credential = await currentFbUser.linkWithCredential(oauthCredential);
          } catch (_) {
            credential = await _auth.signInWithCredential(oauthCredential);
          }
        } else {
          credential = await _auth.signInWithCredential(oauthCredential);
        }
      }

      final user = _userFromFirebase(credential.user!, prefs);
      await _persistCloudUser(user, prefs);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Firebase Google error: ${e.code}');
      throw AuthException(_firebaseMessage(e));
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Google platform error: ${e.code} ${e.details}');
      throw AuthException(_googlePlatformMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('[AuthService] Google sign-in error: $e');
      throw const AuthException(
        'Google sign-in failed. Check your internet connection and try again.',
      );
    }
  }

  /// Local fallback used by offline development/unit tests.
  Future<UserModel> _localGoogleSignIn({
    required String email,
    required String username,
    required String avatar,
    String? photoUrl,
  }) async {
    final cleanEmail = normaliseEmail(email);
    final emailError = validateEmail(cleanEmail);
    if (emailError != null) throw AuthException(emailError);

    final cleanUsername = username.trim();
    if (cleanUsername.isNotEmpty) {
      final usernameError = validateUsername(cleanUsername);
      if (usernameError != null) throw AuthException(usernameError);
    }

    final prefs = await SharedPreferences.getInstance();
    final accounts = _loadAccounts(prefs);
    final existing = accounts[cleanEmail];

    if (existing != null && existing['provider']?.toString() != 'google') {
      throw const AuthException(
        'This email is already registered with a password. Please log in with your email and password.',
      );
    }

    final finalUsername = cleanUsername.isNotEmpty
        ? cleanUsername
        : (existing?['username']?.toString() ?? cleanEmail.split('@').first);

    for (final entry in accounts.entries) {
      if (entry.key == cleanEmail) continue;
      if ((entry.value['username']?.toString().toLowerCase() ?? '') ==
          finalUsername.toLowerCase()) {
        throw AuthException('Username "$finalUsername" is already taken.');
      }
    }

    final safeAvatar = predefinedAvatars.contains(avatar) ? avatar : '👑';

    final UserModel user;
    if (existing != null) {
      user = UserModel.fromMap(existing).copyWith(
        username: finalUsername,
        avatar: safeAvatar,
        photoUrl: photoUrl ?? existing['photoUrl'] as String?,
      );
    } else {
      user = UserModel(
        uid: _newUid('google'),
        username: finalUsername,
        email: cleanEmail,
        avatar: safeAvatar,
        photoUrl: photoUrl,
        isGuest: false,
        provider: 'google',
        createdAt: DateTime.now(),
      );
    }

    accounts[cleanEmail] = {
      ...?existing,
      ...user.toMap(),
    };
    await _saveAccounts(accounts, prefs);
    await _saveSession(user, prefs);
    return user;
  }

  /// Continue as guest
  Future<UserModel> continueAsGuest({String avatar = '🦊'}) async {
    final safeAvatar = predefinedAvatars.contains(avatar) ? avatar : '🦊';
    final prefs = await SharedPreferences.getInstance();

    if (_cloudReady) {
      try {
        final credential = await _auth.signInAnonymously();
        final suffix = _random.nextInt(900000) + 100000;
        final user = UserModel(
          uid: credential.user!.uid,
          username: 'Explorer #$suffix',
          email: '',
          avatar: safeAvatar,
          isGuest: true,
          provider: 'guest',
          createdAt: DateTime.now(),
        );
        await _persistCloudUser(user, prefs);
        return user;
      } on fb.FirebaseAuthException catch (e) {
        // Anonymous Auth may be disabled in the Firebase console; guests can
        // still play locally.
        debugPrint('[AuthService] Anonymous sign-in unavailable: ${e.code}');
      } catch (e) {
        debugPrint('[AuthService] Anonymous sign-in error: $e');
      }
    }

    final suffix = _random.nextInt(900000) + 100000;
    final user = UserModel(
      uid: 'guest_$suffix',
      username: 'Explorer #$suffix',
      email: '',
      avatar: safeAvatar,
      isGuest: true,
      provider: 'guest',
      createdAt: DateTime.now(),
    );
    await _saveSession(user, prefs);
    return user;
  }

  /// Update the current user's avatar
  Future<void> updateAvatar(String newAvatar) async {
    if (currentUser == null) return;
    if (!predefinedAvatars.contains(newAvatar)) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = currentUser!.copyWith(avatar: newAvatar);
    await _persistCloudUser(updated, prefs);
    DatabaseService.instance.scheduleCloudSync();
  }

  /// Update the current user's username
  Future<void> updateUsername(String newUsername) async {
    final clean = newUsername.trim();
    final error = validateUsername(clean);
    if (error != null) throw AuthException(error);
    if (currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final accounts = _loadAccounts(prefs);

    for (final entry in accounts.entries) {
      if (entry.value['uid']?.toString() == currentUser!.uid) continue;
      if ((entry.value['username']?.toString().toLowerCase() ?? '') ==
          clean.toLowerCase()) {
        throw AuthException('Username "$clean" is already taken.');
      }
    }

    final updated = currentUser!.copyWith(username: clean);
    await _persistCloudUser(updated, prefs);
    DatabaseService.instance.scheduleCloudSync();

    if (_cloudReady && !updated.isGuest) {
      try {
        await _auth.currentUser?.updateDisplayName(clean);
      } catch (e) {
        debugPrint('[AuthService] Could not update display name: $e');
      }
    }
  }

  /// Logout current session
  Future<void> logout() async {
    if (_cloudReady) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('[AuthService] Firebase sign-out error: $e');
      }
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    userNotifier.value = null;
    await DatabaseService.instance.setActiveUser(null);
  }

  /// Permanently deletes the current authenticated user account and all associated cloud records.
  /// Complies with Google Play User Data & Account Deletion policy requirements.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    final uid = user.uid;

    if (_cloudReady && !user.isGuest) {
      // 1. Delete all Firestore records associated with this account
      try {
        final store = cloudDb;
        await Future.wait([
          store.collection('users').doc(uid).delete().catchError((_) {}),
          store.collection('leaderboard').doc(uid).delete().catchError((_) {}),
          store.collection('streaks').doc(uid).delete().catchError((_) {}),
          store.collection('dailyClaims').doc(uid).delete().catchError((_) {}),
          store.collection('playActivity').doc(uid).delete().catchError((_) {}),
        ]);
      } catch (e) {
        debugPrint('[AuthService] Firestore data deletion notice: $e');
      }

      // 2. Delete the Firebase Authentication user credentials
      try {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          await fbUser.delete();
        }
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw const AuthException(
            'For security, please sign out and sign back in before deleting your account.',
          );
        }
        throw AuthException('Failed to delete account: ${e.message}');
      } catch (e) {
        debugPrint('[AuthService] Firebase user delete notice: $e');
      }

      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
    }

    // 3. Clear local storage records for this account
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_profile_$uid');
    await prefs.remove(_userKey);

    final accounts = _loadAccounts(prefs);
    accounts.removeWhere((k, v) => v['uid']?.toString() == uid);
    await _saveAccounts(accounts, prefs);

    // 4. Reset local game progress for this user
    await DatabaseService.instance.resetAll();
    await DatabaseService.instance.setActiveUser(null);
    userNotifier.value = null;
  }

  // ── Cloud profile cache ──────────────────────────────────────

  UserModel _userFromFirebase(fb.User firebaseUser, SharedPreferences prefs) {
    final cached = _readProfile(prefs, firebaseUser.uid);
    final email = firebaseUser.email ?? '';
    final cachedName = cached?['username']?.toString().trim() ?? '';
    final displayName = firebaseUser.displayName?.trim() ?? '';

    final username = cachedName.isNotEmpty
        ? cachedName
        : (displayName.isNotEmpty
            ? displayName
            : (email.isNotEmpty ? email.split('@').first : 'Explorer'));

    final cachedAvatar = cached?['avatar']?.toString() ?? '';
    final avatar = predefinedAvatars.contains(cachedAvatar) ? cachedAvatar : '🦊';

    final createdAt = DateTime.tryParse(cached?['createdAt']?.toString() ?? '') ??
        firebaseUser.metadata.creationTime ??
        DateTime.now();

    return UserModel(
      uid: firebaseUser.uid,
      username: username,
      email: email,
      avatar: avatar,
      photoUrl: firebaseUser.photoURL,
      isGuest: firebaseUser.isAnonymous,
      provider: firebaseUser.isAnonymous ? 'guest' : _providerId(firebaseUser),
      createdAt: createdAt,
    );
  }

  String _providerId(fb.User user) {
    final ids = user.providerData.map((p) => p.providerId).toList();
    if (ids.contains('google.com')) return 'google';
    if (ids.contains('password')) return 'password';
    return ids.isNotEmpty ? ids.first : 'password';
  }

  Map<String, dynamic>? _readProfile(SharedPreferences prefs, String uid) {
    final raw = prefs.getString('auth_profile_$uid');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeProfile(SharedPreferences prefs, UserModel user) async {
    await prefs.setString(
      'auth_profile_${user.uid}',
      jsonEncode({
        'uid': user.uid,
        'username': user.username,
        'email': user.email,
        'avatar': user.avatar,
        'provider': user.provider,
        'createdAt': user.createdAt.toIso8601String(),
      }),
    );
  }

  Future<void> _persistCloudUser(UserModel user, SharedPreferences prefs) async {
    await _writeProfile(prefs, user);

    if (user.email.isNotEmpty) {
      final accounts = _loadAccounts(prefs);
      accounts[user.email] = {
        ...?accounts[user.email],
        ...user.toMap(),
      };
      await _saveAccounts(accounts, prefs);
    }

    await _saveSession(user, prefs);
  }

  String? _findEmailByUsername(
    Map<String, Map<String, dynamic>> accounts,
    String usernameLower,
  ) {
    for (final acc in accounts.values) {
      if ((acc['username']?.toString().toLowerCase() ?? '') == usernameLower) {
        final email = acc['email']?.toString().trim() ?? '';
        if (email.isNotEmpty) return email;
      }
    }
    return null;
  }

  // ── Error messages ───────────────────────────────────────────

  String _firebaseMessage(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with a letter and a number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase. Enable it in Firebase Console → Authentication → Sign-in method.';
      case 'account-exists-with-different-credential':
        return 'This email is linked to a different sign-in method. Log in with your password instead.';
      case 'credential-already-in-use':
        return 'This sign-in credential is already linked to another account.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      case 'popup-closed-by-user':
      case 'web-context-canceled':
        return 'Google sign-in was cancelled.';
      default:
        return 'Sign-in failed (${e.code}). Please try again.';
    }
  }

  String _googlePlatformMessage(PlatformException e) {
    final detail = '${e.code} ${e.message ?? ''} ${e.details ?? ''}';
    if (detail.contains('ApiException: 10') ||
        detail.contains('DEVELOPER_ERROR') ||
        detail.contains('sign_in_failed')) {
      return 'Google sign-in is not configured for this build. Add this app\'s SHA-1 fingerprint in Firebase Console → Project Settings → Your Android app.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  // ── Storage / crypto helpers ─────────────────────────────────

  final Random _random = Random.secure();

  // Fixed salt used only to equalise timing for unknown identifiers.
  final String _dummySalt = base64Encode(
    List<int>.generate(_saltBytes, (i) => (i + 1) * 17 % 256),
  );

  String _newUid(String prefix) {
    final entropy = _random.nextInt(1 << 32);
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$entropy';
  }

  String _generateSalt() {
    final bytes = List<int>.generate(_saltBytes, (_) => _random.nextInt(256));
    return base64Encode(bytes);
  }

  /// PBKDF2-HMAC-SHA256 helper producing a base64-encoded 32-byte key.
  String _hashPassword(String password, String saltBase64, int iterations) {
    final salt = base64Decode(saltBase64);
    final hmac = Hmac(sha256, utf8.encode(password));
    final block = Uint8List(_hashBytes);

    var u = hmac.convert(<int>[...salt, 0, 0, 0, 1]).bytes;
    block.setAll(0, u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < block.length; j++) {
        block[j] ^= u[j];
      }
    }
    return base64Encode(block);
  }

  bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var diff = aBytes.length ^ bBytes.length;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i < bBytes.length ? i : 0];
    }
    return diff == 0;
  }

  Future<void> _saveSession(UserModel user, SharedPreferences prefs) async {
    final now = DateTime.now().toUtc();
    await prefs.setString(
      _userKey,
      jsonEncode({
        'v': 2,
        'user': user.toMap(),
        'issuedAt': now.toIso8601String(),
        'expiresAt': now.add(sessionLifetime).toIso8601String(),
      }),
    );
    userNotifier.value = user;
    await DatabaseService.instance.setActiveUser(user.uid);
  }

  Map<String, Map<String, dynamic>> _loadAccounts(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_registeredUsersKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAccounts(
    Map<String, Map<String, dynamic>> accounts,
    SharedPreferences prefs,
  ) async {
    await prefs.setString(_registeredUsersKey, jsonEncode(accounts));
  }
}
