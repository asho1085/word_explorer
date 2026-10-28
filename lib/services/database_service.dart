import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = isDarkMode();
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('DatabaseService must be initialized before use.');
    }
    return _prefs!;
  }

  // Coins
  int getCoins() {
    return prefs.getInt('total_coins') ?? 120;
  }

  Future<void> addCoins(int amount) async {
    final current = getCoins();
    await prefs.setInt('total_coins', current + amount);
  }

  Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current < amount) return false;
    await prefs.setInt('total_coins', current - amount);
    return true;
  }

  // Hints
  static const int hintCost = 30;

  Future<bool> useHint() async {
    // Hint costs 30 coins
    return await spendCoins(hintCost);
  }

  // Settings
  bool getSoundEnabled() {
    return prefs.getBool('setting_sound') ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    await prefs.setBool('setting_sound', value);
  }

  bool getVibrationEnabled() {
    return prefs.getBool('setting_vibration') ?? true;
  }

  Future<void> setVibrationEnabled(bool value) async {
    await prefs.setBool('setting_vibration', value);
  }

  bool isDarkMode() {
    return prefs.getBool('setting_dark_mode') ?? true;
  }

  Future<void> setIsDarkMode(bool isDark) async {
    await prefs.setBool('setting_dark_mode', isDark);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Progress
  String _progressKey(String mode, int level) => 'progress_${mode}_$level';

  LevelProgress? getProgress(String mode, int level) {
    final jsonStr = prefs.getString(_progressKey(mode, level));
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LevelProgress.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  bool isLevelUnlocked(String mode, int level) {
    if (level == 1) return true;
    final prev = getProgress(mode, level - 1);
    return prev?.completed == true;
  }

  Future<void> saveLevelProgress(
    String mode,
    int level,
    int stars,
    int timeTaken,
    int coinsEarned,
  ) async {
    final existing = getProgress(mode, level);
    final bestStars = existing != null && existing.stars > stars ? existing.stars : stars;
    final bestTime = (existing != null && existing.bestTime > 0 && existing.bestTime < timeTaken)
        ? existing.bestTime
        : timeTaken;

    final progress = LevelProgress(
      mode: mode,
      level: level,
      stars: bestStars,
      bestTime: bestTime,
      completed: true,
    );

    await prefs.setString(_progressKey(mode, level), jsonEncode(progress.toJson()));
    await addCoins(coinsEarned);
  }

  Future<void> resetAll() async {
    await prefs.clear();
    await prefs.setInt('total_coins', 120);
    await prefs.setInt('hints_remaining', 3);
    await prefs.setBool('setting_sound', true);
    await prefs.setBool('setting_vibration', true);
    await prefs.setBool('setting_dark_mode', true);
    themeModeNotifier.value = ThemeMode.dark;
  }
}
