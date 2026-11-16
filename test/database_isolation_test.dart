import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot([Map<String, Object> values = const {}]) async {
    await DatabaseService.instance.setActiveUser(null);
    SharedPreferences.setMockInitialValues(values);
    await DatabaseService.instance.init();
  }

  setUp(() async {
    await boot();
  });

  test('accounts on the same device never share coins, stars or levels',
      () async {
    final db = DatabaseService.instance;

    await db.setActiveUser('account_a');
    await db.setCoins(500);
    await db.saveLevelProgress('english', 1, 3, 40, 10);
    await db.saveLevelProgress('english', 2, 2, 45, 10);

    expect(db.getCoins(), 520);
    expect(db.getTotalStars(), 5);
    expect(db.getTotalCompletedLevels(), 2);
    expect(db.isLevelUnlocked('english', 2), isTrue);

    await db.setActiveUser('account_b');
    expect(db.getCoins(), 0);
    expect(db.getTotalStars(), 0);
    expect(db.getTotalCompletedLevels(), 0);
    expect(db.isLevelUnlocked('english', 2), isFalse);
    expect(db.getProgress('english', 1), isNull);
    expect(db.isWelcomeBonusClaimed(), isFalse);

    await db.setActiveUser('account_a');
    expect(db.getCoins(), 520);
    expect(db.getTotalStars(), 5);
    expect(db.isLevelUnlocked('english', 2), isTrue);
  });

  test('daily and welcome bonuses are tracked per account', () async {
    final db = DatabaseService.instance;

    await db.setActiveUser('account_a');
    expect(db.isWelcomeBonusClaimed(), isFalse);
    expect(await db.claimDailyBonus(), isTrue);
    await db.setWelcomeBonusClaimed();
    expect(db.getCoins(), DatabaseService.dailyBonusCoins);

    await db.setActiveUser('account_b');
    expect(db.canClaimDailyBonus(), isTrue);
    expect(db.isWelcomeBonusClaimed(), isFalse);
    expect(db.getCoins(), 0);

    expect(await db.claimDailyBonus(), isTrue);
    expect(db.getCoins(), DatabaseService.dailyBonusCoins);
  });

  test('legacy single-player data migrates to the first account only', () async {
    await boot({
      'total_coins': 275,
      'welcome_bonus_claimed': true,
      'last_daily_bonus_date': '2026-01-01',
      'progress_english_1':
          '{"mode":"english","level":1,"stars":3,"bestTime":30,"completed":true}',
    });

    final db = DatabaseService.instance;
    await db.setActiveUser('legacy_owner');

    expect(db.getCoins(), 275);
    expect(db.getTotalStars(), 3);
    expect(db.isWelcomeBonusClaimed(), isTrue);
    expect(db.canClaimDailyBonus(), isTrue);
    expect(db.prefs!.getInt('total_coins'), isNull);

    await db.setActiveUser('new_player');
    expect(db.getCoins(), 0);
    expect(db.getTotalStars(), 0);
    expect(db.isWelcomeBonusClaimed(), isFalse);
    expect(db.getProgress('english', 1), isNull);
  });

  test('reset clears only the active account and keeps sign-in data', () async {
    final db = DatabaseService.instance;

    await db.setActiveUser('account_a');
    await db.setCoins(300);
    await db.saveLevelProgress('hindi', 1, 3, 20, 5);

    await db.setActiveUser('account_b');
    await db.setCoins(90);
    await db.prefs!.setString('registered_accounts_db', '{"b@example.com":{}}');

    await db.resetAll();
    expect(db.getCoins(), 0);
    expect(db.getTotalStars(), 0);
    expect(db.prefs!.getString('registered_accounts_db'), isNotNull);

    await db.setActiveUser('account_a');
    expect(db.getCoins(), 305);
    expect(db.getTotalStars(), 3);
    expect(db.getProgress('hindi', 1)?.completed, isTrue);
  });

  test('theme mode defaults to dark and toggles to light/white mode properly',
      () async {
    final db = DatabaseService.instance;
    expect(db.isDarkMode(), isTrue);
    expect(DatabaseService.themeModeNotifier.value, ThemeMode.dark);

    await db.setIsDarkMode(false);
    expect(db.isDarkMode(), isFalse);
    expect(DatabaseService.themeModeNotifier.value, ThemeMode.light);

    await db.setIsDarkMode(true);
    expect(DatabaseService.themeModeNotifier.value, ThemeMode.dark);
  });
}
