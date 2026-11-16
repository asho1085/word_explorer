import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import 'cloud_db.dart';
import 'streak_service.dart';

/// Player data store.
///
/// Every value is namespaced by the signed-in account UID, so two accounts
/// used on the same device never share coins, stars, bonuses, or level
/// progress. Signed-in (non-guest) accounts are mirrored to the owner-only
/// `users/{uid}` Firestore document so progress follows the account across
/// devices. Without a network connection the local copy keeps working and the
/// Firestore SDK replays the queued write later.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// Bumped whenever stored player data changes outside the active screen
  /// (account switch, cloud merge, reset) so the UI can refresh.
  static final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

  static const String _dataPrefix = 'pdata_';
  static const String _localScope = 'local';
  static const String _schemaKey = 'pdata_schema_v2';

  // Legacy single-player keys from builds before per-account storage.
  static const String _legacyCoinsKey = 'total_coins';
  static const String _legacyWelcomeKey = 'welcome_bonus_claimed';
  static const String _legacyBonusDateKey = 'last_daily_bonus_date';
  static const String _legacyProgressPrefix = 'progress_';
  static const String _legacyWelcomePrefix = 'welcome_bonus_';

  static const int _maxLevel = 50;
  static const List<String> _modes = ['english', 'hindi', 'master'];

  SharedPreferences? _prefs;
  String? _activeUid;
  Timer? _pushTimer;
  bool _pullInFlight = false;
  bool _pushInFlight = false;

  /// Account whose player data is currently loaded (null when signed out).
  String? get activeUid => _activeUid;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final isDark = isDarkMode();
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('[DatabaseService] Initialization error: $e');
    }
  }

  SharedPreferences? get prefs => _prefs;

  // ── Account scoping ─────────────────────────────────────────

  /// Loads the stored data that belongs to [uid] (null when signed out).
  ///
  /// Legacy single-player data is migrated to the first account that signs in
  /// after the update; later accounts start with a clean slate.
  Future<void> setActiveUser(String? uid) async {
    final next = (uid == null || uid.trim().isEmpty) ? null : uid.trim();
    if (next == _activeUid) return;

    _activeUid = next;
    _pushTimer?.cancel();
    _pushTimer = null;
    StreakService.instance.setUser(next);
    dataRevision.value++;

    if (next == null) return;

    await _ensurePrefs();
    await _migrateLegacyData(next);
    await _pullCloud(next);
  }

  Future<void> _ensurePrefs() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[DatabaseService] SharedPreferences unavailable: $e');
    }
  }

  String get _scope {
    final uid = _activeUid;
    if (uid == null) return '$_dataPrefix${_localScope}_';
    final safe = uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '$_dataPrefix${safe}_';
  }

  String _k(String suffix) => '$_scope$suffix';

  bool _isLegacyKey(String key) {
    return key == _legacyCoinsKey ||
        key == _legacyWelcomeKey ||
        key == _legacyBonusDateKey ||
        key.startsWith(_legacyProgressPrefix) ||
        key.startsWith(_legacyWelcomePrefix);
  }

  Future<void> _migrateLegacyData(String uid) async {
    final prefs = _prefs;
    if (prefs == null || prefs.getBool(_schemaKey) == true) return;

    final legacyKeys = prefs.getKeys().where(_isLegacyKey).toList();
    if (legacyKeys.isEmpty) {
      await prefs.setBool(_schemaKey, true);
      return;
    }

    final claimed = prefs.getBool('$_legacyWelcomePrefix$uid') ??
        prefs.getBool(_legacyWelcomeKey);
    if (claimed != null) {
      await prefs.setBool(_k('welcome_bonus'), claimed);
    }

    var coins = prefs.getInt(_legacyCoinsKey);
    // Older builds seeded 120/150 coins before any bonus was claimed.
    if (coins != null && (coins == 120 || coins == 150) && claimed != true) {
      coins = 0;
    }
    if (coins != null) {
      await prefs.setInt(_k('coins'), coins);
    }

    final bonusDate = prefs.getString(_legacyBonusDateKey);
    if (bonusDate != null) {
      await prefs.setString(_k('daily_date'), bonusDate);
    }

    for (final key in legacyKeys) {
      if (!key.startsWith(_legacyProgressPrefix)) continue;
      final value = prefs.getString(key);
      final scoped = _k(key);
      if (value != null && !prefs.containsKey(scoped)) {
        await prefs.setString(scoped, value);
      }
    }

    for (final key in legacyKeys) {
      await prefs.remove(key);
    }
    // Treat the migrated data as freshest so a stale cloud document cannot
    // overwrite the player's coins on the first cloud merge.
    await prefs.setInt(_k('updated_at'), DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_schemaKey, true);
    debugPrint('[DatabaseService] Migrated legacy progress to account $uid');
  }

  // ── Coins ───────────────────────────────────────────────────

  int getCoins() {
    final prefs = _prefs;
    if (prefs == null) return 0;

    var coins = prefs.getInt(_k('coins'));
    if (coins == null && _activeUid == null) {
      coins = prefs.getInt(_legacyCoinsKey);
      if (coins != null &&
          (coins == 120 || coins == 150) &&
          !isWelcomeBonusClaimed()) {
        coins = 0;
      }
    }
    return coins ?? 0;
  }

  Future<void> setCoins(int amount) async {
    await _ensurePrefs();
    await _prefs?.setInt(_k('coins'), amount < 0 ? 0 : amount);
    await _touch();
  }

  Future<void> addCoins(int amount) async {
    final next = getCoins() + amount;
    await _prefs?.setInt(_k('coins'), next < 0 ? 0 : next);
    await _touch();
  }

  Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current < amount) return false;
    await _prefs?.setInt(_k('coins'), current - amount);
    await _touch();
    return true;
  }

  // ── Bonuses ─────────────────────────────────────────────────

  bool isWelcomeBonusClaimed() {
    final prefs = _prefs;
    if (prefs == null) return false;

    final claimed = prefs.getBool(_k('welcome_bonus'));
    if (claimed != null) return claimed;
    if (_activeUid == null) {
      return prefs.getBool(_legacyWelcomeKey) ?? false;
    }
    return false;
  }

  Future<void> setWelcomeBonusClaimed() async {
    await _ensurePrefs();
    await _prefs?.setBool(_k('welcome_bonus'), true);
    await _touch();
  }

  static const int dailyBonusCoins = 50;
  bool _bonusClaimInProgress = false;

  /// The daily reset happens at 00:00 IST (UTC+05:30). Using a fixed offset
  /// keeps every device on the same day as the server regardless of the
  /// phone's timezone or date setting. Must match `bonusDay()` in
  /// firestore.rules.
  static const Duration _bonusDayOffset = Duration(hours: 5, minutes: 30);
  static const Duration _claimTimeout = Duration(seconds: 8);

  String _bonusDayKey(DateTime instant) {
    final day = instant.toUtc().add(_bonusDayOffset);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  String _todayKey() => _bonusDayKey(DateTime.now());

  bool canClaimDailyBonus() {
    final prefs = _prefs;
    if (prefs == null) return true;

    var last = prefs.getString(_k('daily_date'));
    if (last == null && _activeUid == null) {
      last = prefs.getString(_legacyBonusDateKey);
    }
    return last != _todayKey();
  }

  /// Grants the daily bonus once per server-verified calendar day.
  ///
  /// Signed-in players must pass the Firestore `dailyClaims/{uid}` check, where
  /// `lastClaimAt` is written only by the server (rules require it to equal
  /// `request.time`), so changing the phone date cannot unlock extra claims.
  /// Guests and offline sessions fall back to the local calendar guard.
  Future<bool> claimDailyBonus() async {
    if (_bonusClaimInProgress || !canClaimDailyBonus()) return false;
    _bonusClaimInProgress = true;
    try {
      final uid = _activeUid;
      if (uid != null && _cloudEligible) {
        final granted = await _claimDailyBonusOnServer(uid);
        if (!granted) return false;
      } else {
        await _prefs?.setString(_k('daily_date'), _todayKey());
      }
      await addCoins(dailyBonusCoins);
      return true;
    } finally {
      _bonusClaimInProgress = false;
    }
  }

  Future<bool> _claimDailyBonusOnServer(String uid) async {
    final ref = cloudDb.collection('dailyClaims').doc(uid);

    // 1. Read the server-verified claim day. If the cloud is unreachable, keep
    // the old local-calendar behavior so offline play still grants the bonus.
    try {
      final snapshot = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(_claimTimeout);
      if (_activeUid != uid) return false;

      final last = snapshot.data()?['lastClaimAt'];
      if (last is Timestamp) {
        final lastDay = _bonusDayKey(
          DateTime.fromMillisecondsSinceEpoch(
            last.millisecondsSinceEpoch,
            isUtc: true,
          ),
        );
        await _prefs?.setString(_k('daily_date'), lastDay);
        if (lastDay == _todayKey()) return false;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // dailyClaims rules are not deployed yet: keep the local guard.
        debugPrint(
          '[DatabaseService] Daily claim rules missing; using local guard',
        );
      } else {
        debugPrint('[DatabaseService] Daily claim offline fallback: $e');
      }
      await _prefs?.setString(_k('daily_date'), _todayKey());
      return true;
    } catch (e) {
      debugPrint('[DatabaseService] Daily claim offline fallback: $e');
      await _prefs?.setString(_k('daily_date'), _todayKey());
      return true;
    }

    // 2. Record the claim with a server timestamp. The rules only accept it
    // when the server's own calendar day has advanced past the previous claim.
    try {
      await ref
          .set(
            {
              'uid': uid,
              'lastClaimAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          )
          .timeout(_claimTimeout);
      await _cacheServerClaimDay(ref, uid);
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // The phone date claims a new day but the server does not agree.
        await _cacheServerClaimDay(ref, uid);
        return false;
      }
      debugPrint('[DatabaseService] Daily claim offline fallback: $e');
      await _prefs?.setString(_k('daily_date'), _todayKey());
      return true;
    } catch (e) {
      debugPrint('[DatabaseService] Daily claim offline fallback: $e');
      await _prefs?.setString(_k('daily_date'), _todayKey());
      return true;
    }
  }

  Future<void> _cacheServerClaimDay(
    DocumentReference<Map<String, dynamic>> ref,
    String uid,
  ) async {
    try {
      final snapshot = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(_claimTimeout);
      if (_activeUid != uid) return;

      final last = snapshot.data()?['lastClaimAt'];
      if (last is Timestamp) {
        await _prefs?.setString(
          _k('daily_date'),
          _bonusDayKey(
            DateTime.fromMillisecondsSinceEpoch(
              last.millisecondsSinceEpoch,
              isUtc: true,
            ),
          ),
        );
      }
    } catch (e) {
      // Best effort: the server record stays authoritative for eligibility.
      debugPrint('[DatabaseService] Daily claim cache refresh skipped: $e');
    }
  }

  Future<void> _refreshServerClaimDay(String uid) async {
    final before = _prefs?.getString(_k('daily_date'));
    await _cacheServerClaimDay(
      cloudDb.collection('dailyClaims').doc(uid),
      uid,
    );
    if (_activeUid == uid && _prefs?.getString(_k('daily_date')) != before) {
      dataRevision.value++;
    }
  }

  // ── Hints ───────────────────────────────────────────────────

  static const int hintCost = 30;

  Future<bool> useHint() => spendCoins(hintCost);

  // ── Settings (device-wide) ──────────────────────────────────

  bool getSoundEnabled() => _prefs?.getBool('setting_sound') ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool('setting_sound', value);
  }

  bool getVibrationEnabled() => _prefs?.getBool('setting_vibration') ?? true;

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs?.setBool('setting_vibration', value);
  }

  bool isDarkMode() => _prefs?.getBool('setting_dark_mode') ?? true;

  Future<void> setIsDarkMode(bool isDark) async {
    await _prefs?.setBool('setting_dark_mode', isDark);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Progress ────────────────────────────────────────────────

  String _progressKey(String mode, int level) => _k('progress_${mode}_$level');

  LevelProgress? _parseProgress(String? jsonStr) {
    if (jsonStr == null) return null;
    try {
      return LevelProgress.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  LevelProgress? getProgress(String mode, int level) {
    final prefs = _prefs;
    if (prefs == null) return null;

    var jsonStr = prefs.getString(_progressKey(mode, level));
    if (jsonStr == null && _activeUid == null) {
      jsonStr = prefs.getString('$_legacyProgressPrefix${mode}_$level');
    }
    return _parseProgress(jsonStr);
  }

  bool isLevelUnlocked(String mode, int level) {
    if (level == 1) return true;
    return getProgress(mode, level - 1)?.completed == true;
  }

  Future<void> saveLevelProgress(
    String mode,
    int level,
    int stars,
    int timeTaken,
    int coinsEarned,
  ) async {
    final uid = _activeUid;
    final existing = getProgress(mode, level);
    final bestStars =
        existing != null && existing.stars > stars ? existing.stars : stars;
    final bestTime =
        (existing != null && existing.bestTime > 0 && existing.bestTime < timeTaken)
            ? existing.bestTime
            : timeTaken;

    final progress = LevelProgress(
      mode: mode,
      level: level,
      stars: bestStars,
      bestTime: bestTime,
      completed: true,
    );

    await _prefs?.setString(
      _progressKey(mode, level),
      jsonEncode(progress.toJson()),
    );
    if (_activeUid != uid) return;
    await addCoins(coinsEarned);
    unawaited(StreakService.instance.recordCompletion(uid));
  }

  int getTotalStars() {
    var total = 0;
    for (final mode in _modes) {
      for (var level = 1; level <= _maxLevel; level++) {
        total += getProgress(mode, level)?.stars ?? 0;
      }
    }
    return total;
  }

  int getTotalCompletedLevels() {
    var total = 0;
    for (final mode in _modes) {
      for (var level = 1; level <= _maxLevel; level++) {
        if (getProgress(mode, level)?.completed == true) total++;
      }
    }
    return total;
  }

  /// Clears only the active account's player data. Sign-in sessions, other
  /// accounts on the device, and app settings are preserved.
  Future<void> resetAll() async {
    final prefs = _prefs;
    final scope = _scope;
    if (prefs != null) {
      for (final key in prefs.getKeys().toList()) {
        final isLegacy = _activeUid == null && _isLegacyKey(key);
        if (key.startsWith(scope) || isLegacy) {
          await prefs.remove(key);
        }
      }
      await prefs.setBool('setting_sound', true);
      await prefs.setBool('setting_vibration', true);
      await prefs.setBool('setting_dark_mode', true);
    }
    themeModeNotifier.value = ThemeMode.dark;
    dataRevision.value++;
    _scheduleCloudPush();
  }

  // ── Cloud mirror (Firestore) ────────────────────────────────

  bool get _cloudEligible {
    final uid = _activeUid;
    if (uid == null || Firebase.apps.isEmpty) return false;

    final profile = _readProfile(uid);
    if (profile != null && profile['isGuest'] == true) return false;

    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      return user != null && !user.isAnonymous && user.uid == uid;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _readProfile(String uid) {
    final raw = _prefs?.getString('auth_profile_$uid');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Queues a cloud write for the current account. Called when profile fields
  /// (username/avatar) change or a screen needs an immediate push.
  void scheduleCloudSync() => _scheduleCloudPush();

  Future<void> _touch() async {
    await _prefs?.setInt(_k('updated_at'), DateTime.now().millisecondsSinceEpoch);
    _scheduleCloudPush();
  }

  void _scheduleCloudPush() {
    if (!_cloudEligible) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 1200), () {
      unawaited(_pushCloud());
    });
  }

  Future<void> _pullCloud(String uid) async {
    if (_pullInFlight || !_cloudEligible) return;
    _pullInFlight = true;
    try {
      final snapshot = await cloudDb
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(_claimTimeout);
      if (_activeUid != uid) return;

      final data = snapshot.data();
      if (data != null && data.isNotEmpty) {
        await _mergeCloudData(data);
        dataRevision.value++;
      }
      await _refreshServerClaimDay(uid);
      await _pushCloud();
    } catch (e) {
      // Offline or Firestore not provisioned: keep playing from local data.
      debugPrint('[DatabaseService] Cloud pull skipped: $e');
    } finally {
      _pullInFlight = false;
    }
  }

  Future<void> _mergeCloudData(Map<String, dynamic> data) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final remoteUpdated = _timestampMillis(data['updatedAt']);
    final localUpdated = prefs.getInt(_k('updated_at')) ?? 0;

    // Level results are monotonic: keep the best stars/time from either side.
    final progress = data['progress'];
    if (progress is Map) {
      for (final entry in progress.entries) {
        final remote = entry.value;
        if (remote is! Map) continue;

        final key = entry.key.toString();
        final split = key.lastIndexOf('_');
        if (split <= 0) continue;
        final mode = key.substring(0, split);
        final level = int.tryParse(key.substring(split + 1));
        if (level == null || !_modes.contains(mode)) continue;

        final local = getProgress(mode, level);
        final remoteStars = (remote['stars'] as num?)?.toInt() ?? 0;
        final remoteBest = (remote['bestTime'] as num?)?.toInt() ?? 0;
        final remoteCompleted = remote['completed'] == true;

        final stars = local == null
            ? remoteStars
            : (remoteStars > local.stars ? remoteStars : local.stars);
        final bestTime = local == null
            ? remoteBest
            : _bestTime(local.bestTime, remoteBest);
        final completed = remoteCompleted || (local?.completed ?? false);

        if (local != null &&
            local.stars == stars &&
            local.bestTime == bestTime &&
            local.completed == completed) {
          continue;
        }

        await prefs.setString(
          _progressKey(mode, level),
          jsonEncode(
            LevelProgress(
              mode: mode,
              level: level,
              stars: stars,
              bestTime: bestTime,
              completed: completed,
            ).toJson(),
          ),
        );
      }
    }

    // Coins and bonus flags are not monotonic, so the most recent side wins.
    if (remoteUpdated > localUpdated) {
      final coins = (data['coins'] as num?)?.toInt();
      if (coins != null) {
        await prefs.setInt(_k('coins'), coins < 0 ? 0 : coins);
      }
      final claimed = data['welcomeBonusClaimed'];
      if (claimed is bool) {
        await prefs.setBool(_k('welcome_bonus'), claimed);
      }
      // `lastDailyBonusDate` is client-written and untrusted; eligibility comes
      // from the server-timestamped dailyClaims record instead.
    }

    final mergedUpdated = remoteUpdated > localUpdated ? remoteUpdated : localUpdated;
    if (mergedUpdated > 0) {
      await prefs.setInt(_k('updated_at'), mergedUpdated);
    }
  }

  int _bestTime(int a, int b) {
    if (a <= 0) return b;
    if (b <= 0) return a;
    return a < b ? a : b;
  }

  int _timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return 0;
  }

  String _safeUsername(Object? value) {
    var name = (value ?? '').toString().trim();
    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9 _#\-]'), '');
    if (name.length < 3) return 'Explorer';
    if (name.length > 30) name = name.substring(0, 30);
    if (RegExp(r'(http|www|\.com|\.net|\.org|\.io|\.xyz)', caseSensitive: false).hasMatch(name)) {
      return 'Explorer';
    }
    return name;
  }

  Map<String, dynamic> _progressPayload() {
    final result = <String, dynamic>{};
    for (final mode in _modes) {
      for (var level = 1; level <= _maxLevel; level++) {
        final progress = getProgress(mode, level);
        if (progress == null || !progress.completed) continue;
        result['${mode}_$level'] = {
          'stars': progress.stars,
          'bestTime': progress.bestTime,
          'completed': true,
        };
      }
    }
    return result;
  }

  Future<void> _pushCloud() async {
    if (_pushInFlight || !_cloudEligible) return;
    final uid = _activeUid;
    if (uid == null) return;

    _pushInFlight = true;
    try {
      final profile = _readProfile(uid) ?? const <String, dynamic>{};
      final payload = <String, dynamic>{
        'uid': uid,
        'username': _safeUsername(profile['username']),
        'email': (profile['email'] ?? '').toString(),
        'avatar': (profile['avatar'] ?? '🦊').toString(),
        'stars': getTotalStars(),
        'levelsCompleted': getTotalCompletedLevels(),
        'coins': getCoins(),
        'progress': _progressPayload(),
        'welcomeBonusClaimed': isWelcomeBonusClaimed(),
        'lastDailyBonusDate': _prefs?.getString(_k('daily_date')) ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final doc = cloudDb.collection('users').doc(uid);
      try {
        await doc.set(payload, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // Deployed rules may still reject the progress map; the profile and
        // star/coin totals remain valid with the older schema.
        payload
          ..remove('progress')
          ..remove('welcomeBonusClaimed')
          ..remove('lastDailyBonusDate');
        await doc.set(payload, SetOptions(merge: true));
      }
      await cloudDb.collection('leaderboard').doc(uid).set({
        'username': payload['username'],
        'avatar': payload['avatar'],
        'stars': payload['stars'],
        'levelsCompleted': payload['levelsCompleted'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[DatabaseService] Cloud sync failed: $e');
    } finally {
      _pushInFlight = false;
    }
  }
}
