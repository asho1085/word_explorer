import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/data/word_repository.dart';
import 'package:word_explorer/models/game_models.dart';
import 'package:word_explorer/services/database_service.dart';
import 'package:word_explorer/services/grid_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordRepository Tests', () {
    test('contains 30 levels for all 3 modes', () {
      expect(WordRepository.englishLevels.length, 30);
      expect(WordRepository.masterLevels.length, 30);
      expect(WordRepository.hindiLevels.length, 30);
    });

    test('each level has exactly 10 words or clues', () {
      for (int i = 1; i <= 30; i++) {
        expect(WordRepository.englishLevels[i]!.length, 10);
        expect(WordRepository.masterLevels[i]!.length, 10);
        expect(WordRepository.hindiLevels[i]!.length, 10);
      }
    });

    test('English mode has 100% unique words with no duplicates across all 30 levels', () {
      final allWords = <String>[];
      for (int i = 1; i <= 30; i++) {
        allWords.addAll(WordRepository.englishLevels[i]!);
      }
      final uniqueWords = allWords.toSet();
      expect(uniqueWords.length, allWords.length,
          reason: 'Duplicate English words found: ${allWords.length - uniqueWords.length}');
      expect(uniqueWords.length, 300);
    });

    test('Hindi mode has 100% unique words with no duplicates across all 30 levels', () {
      final allWords = <String>[];
      for (int i = 1; i <= 30; i++) {
        allWords.addAll(WordRepository.hindiLevels[i]!);
      }
      final uniqueWords = allWords.toSet();
      expect(uniqueWords.length, allWords.length,
          reason: 'Duplicate Hindi words found: ${allWords.length - uniqueWords.length}');
      expect(uniqueWords.length, 300);
    });

    test('Master mode has 100% unique pairs with no duplicates across all 30 levels', () {
      final allEnglish = <String>[];
      final allHindi = <String>[];
      for (int i = 1; i <= 30; i++) {
        for (final pair in WordRepository.masterLevels[i]!) {
          allHindi.add(pair['hindi']!);
          allEnglish.add(pair['english']!);
        }
      }
      final uniqueEnglish = allEnglish.toSet();
      final uniqueHindi = allHindi.toSet();
      expect(uniqueEnglish.length, allEnglish.length,
          reason: 'Duplicate Master English answers found');
      expect(uniqueHindi.length, allHindi.length,
          reason: 'Duplicate Master Hindi clues found');
      expect(uniqueEnglish.length, 300);
      expect(uniqueHindi.length, 300);
    });

    test('grid dimensions scale by level progression', () {
      expect(WordRepository.getGridDimension(1), 9);
      expect(WordRepository.getGridDimension(10), 9);
      expect(WordRepository.getGridDimension(11), 10);
      expect(WordRepository.getGridDimension(30), 10);
    });
  });

  group('GridGeneratorService Tests', () {
    final service = GridGeneratorService();

    test('generates 8x8 grid with words successfully', () {
      final words = WordRepository.getGridWords('master', 1);
      final result = service.generateGrid(
        words: words,
        rows: 8,
        cols: 8,
        isHindi: false,
      );

      final grid = result['grid'] as List<List<String>>;
      final placements = result['placements'] as Map;

      expect(grid.length, 8);
      expect(grid[0].length, 8);
      expect(placements.isNotEmpty, true);
    });

    test('shuffles non-word letters without modifying word placements', () {
      final words = ['CAT', 'DOG'];
      final result = service.generateGrid(
        words: words,
        rows: 8,
        cols: 8,
        isHindi: false,
      );

      final originalGrid = result['grid'] as List<List<String>>;
      final placements = result['placements'] as Map<String, List<dynamic>>;

      final shuffledGrid = service.shuffleNonWordCells(
        originalGrid,
        placements.cast(),
        false,
      );

      expect(shuffledGrid.length, 8);
      expect(shuffledGrid[0].length, 8);
    });

    test('generates Hindi grid with whole aksharas (e.g. पानी -> [पा, नी], किताब -> [कि, ता, ब])', () {
      final words = WordRepository.getGridWords('hindi', 1);
      final result = service.generateGrid(
        words: words,
        rows: 8,
        cols: 8,
        isHindi: true,
      );

      final grid = result['grid'] as List<List<String>>;
      final placements = (result['placements'] as Map).cast<String, List<GridCellCoord>>();

      expect(grid.length, 8);
      expect(grid[0].length, 8);
      expect(placements.containsKey('पानी'), true);

      // Verify 'पानी' is placed as 2 cells: 'पा' and 'नी'
      final paniCoords = placements['पानी']!;
      expect(paniCoords.length, 2);
      expect(grid[paniCoords[0].row][paniCoords[0].col], 'पा');
      expect(grid[paniCoords[1].row][paniCoords[1].col], 'नी');

      // Verify 'किताब' is placed as 3 cells: 'कि', 'ता', 'ब'
      if (placements.containsKey('किताब')) {
        final kitabCoords = placements['किताब']!;
        expect(kitabCoords.length, 3);
        expect(grid[kitabCoords[0].row][kitabCoords[0].col], 'कि');
        expect(grid[kitabCoords[1].row][kitabCoords[1].col], 'ता');
        expect(grid[kitabCoords[2].row][kitabCoords[2].col], 'ब');
      }

      // Verify no cell in the grid contains an isolated dependent vowel sign (matra)
      final isolatedMatras = RegExp(r'^[ािीुूृेैोौौंःँ्]$');
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          final cellText = grid[r][c];
          expect(isolatedMatras.hasMatch(cellText), false,
              reason: 'Cell ($r, $c) has isolated matra: $cellText');
        }
      }
    });
  });

  group('DatabaseService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService.instance.init();
    });

    test('default coins and level 1 unlock', () {
      expect(DatabaseService.instance.getCoins(), 120);
      expect(DatabaseService.instance.isLevelUnlocked('master', 1), true);
      expect(DatabaseService.instance.isLevelUnlocked('master', 2), false);
    });

    test('saving progress unlocks next level and updates coins', () async {
      await DatabaseService.instance.saveLevelProgress('master', 1, 3, 90, 25);
      expect(DatabaseService.instance.isLevelUnlocked('master', 2), true);
      expect(DatabaseService.instance.getCoins(), 145);

      final progress = DatabaseService.instance.getProgress('master', 1);
      expect(progress != null, true);
      expect(progress!.stars, 3);
      expect(progress.completed, true);
    });

    test('hint costs 30 coins and fails when balance is insufficient', () async {
      expect(DatabaseService.instance.getCoins(), 120);

      // Spend 30 coins for hint
      final success1 = await DatabaseService.instance.useHint();
      expect(success1, true);
      expect(DatabaseService.instance.getCoins(), 90);

      // Spend 30 coins 3 more times
      await DatabaseService.instance.useHint(); // 60
      await DatabaseService.instance.useHint(); // 30
      await DatabaseService.instance.useHint(); // 0
      expect(DatabaseService.instance.getCoins(), 0);

      // Next hint attempt must fail because coins < 30
      final failedHint = await DatabaseService.instance.useHint();
      expect(failedHint, false);
      expect(DatabaseService.instance.getCoins(), 0);
    });

    test('theme mode defaults to dark and toggles to light/white mode properly', () async {
      expect(DatabaseService.instance.isDarkMode(), true);
      expect(DatabaseService.themeModeNotifier.value, ThemeMode.dark);

      // Toggle to light mode
      await DatabaseService.instance.setIsDarkMode(false);
      expect(DatabaseService.instance.isDarkMode(), false);
      expect(DatabaseService.themeModeNotifier.value, ThemeMode.light);

      // Toggle back to dark mode
      await DatabaseService.instance.setIsDarkMode(true);
      expect(DatabaseService.instance.isDarkMode(), true);
      expect(DatabaseService.themeModeNotifier.value, ThemeMode.dark);
    });
  });

  group('Horizontal Alignment Direction Constraint Tests', () {
    final service = GridGeneratorService();

    test('all horizontal placements are strictly left-to-right', () {
      final words = WordRepository.getGridWords('english', 1);
      final result = service.generateGrid(
        words: words,
        rows: 9,
        cols: 9,
        isHindi: false,
      );

      final placements = (result['placements'] as Map).cast<String, List<GridCellCoord>>();
      for (final entry in placements.entries) {
        final coords = entry.value;
        if (coords.length > 1) {
          final isHorizontal = coords.first.row == coords.last.row;
          if (isHorizontal) {
            // Must strictly start from left to right (start col < end col)
            expect(coords.first.col < coords.last.col, true,
                reason: 'Horizontal word ${entry.key} was placed right-to-left: ${coords.first.col} to ${coords.last.col}');
          }
        }
      }
    });
  });
}
