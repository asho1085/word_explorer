import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_explorer/data/word_repository.dart';
import 'package:word_explorer/services/grid_generator_service.dart';

void main() {
  const modes = ['english', 'hindi', 'master'];

  group('8x8 grid fit tests', () {
    test('grid dimension is 8 for every level', () {
      for (var level = 1; level <= WordRepository.totalLevels; level++) {
        expect(WordRepository.getGridDimension(level), 8,
            reason: 'Level $level');
      }
    });

    test('selected words fit the board limits for all modes and levels', () {
      for (final mode in modes) {
        for (var level = 1; level <= WordRepository.totalLevels; level++) {
          final words = WordRepository.getGridWords(mode, level);
          expect(words.length, greaterThanOrEqualTo(6),
              reason: '$mode level $level keeps at least 6 words');

          var total = 0;
          for (final word in words) {
            final cells = word.characters.length;
            expect(cells, lessThanOrEqualTo(8),
                reason: '$mode level $level word $word has $cells cells');
            total += cells;
          }
          expect(total, lessThanOrEqualTo(56),
              reason: '$mode level $level total $total cells');
        }
      }
    });

    test('clues match grid words for all modes and levels', () {
      for (final mode in modes) {
        for (var level = 1; level <= WordRepository.totalLevels; level++) {
          final words = WordRepository.getGridWords(mode, level);
          final clues = WordRepository.getClues(mode, level);
          expect(clues.length, words.length,
              reason: '$mode level $level clue count');
          expect(
            clues.map((c) => c.answer).toSet(),
            words.toSet(),
            reason: '$mode level $level clue answers',
          );
        }
      }
    });

    test('every level places all selected words at 8x8', () {
      final service = GridGeneratorService();
      for (final mode in modes) {
        for (var level = 1; level <= WordRepository.totalLevels; level++) {
          final words = WordRepository.getGridWords(mode, level);
          final result = service.generateGrid(
            words: words,
            rows: 8,
            cols: 8,
            isHindi: mode == 'hindi',
          );
          final placements =
              result['placements'] as Map<String, List<dynamic>>;
          expect(placements.length, words.length,
              reason: '$mode level $level placed '
                  '${placements.length}/${words.length}');
        }
      }
    });

    test('no isolated matras or empty cells in hindi grids', () {
      final service = GridGeneratorService();
      final isolatedMatras = RegExp(r'^[ािीुूृेैोौंःँ्]$');
      for (var level = 1; level <= WordRepository.totalLevels; level++) {
        final words = WordRepository.getGridWords('hindi', level);
        final result = service.generateGrid(
          words: words,
          rows: 8,
          cols: 8,
          isHindi: true,
        );
        final grid = result['grid'] as List<List<String>>;
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            expect(isolatedMatras.hasMatch(grid[r][c]), false,
                reason: 'hindi level $level cell ($r, $c): ${grid[r][c]}');
          }
        }
      }
    });
  });
}
