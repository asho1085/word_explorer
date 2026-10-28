import 'dart:math';
import 'package:characters/characters.dart';
import '../models/game_models.dart';

class GridDirection {
  final int dr;
  final int dc;
  final String name;

  const GridDirection(this.dr, this.dc, this.name);
}

class GridGeneratorService {
  // Strict directions:
  // - Horizontal words must ALWAYS start from left to right (dr: 0, dc: 1)
  // - Vertical words retain standard top-to-bottom flow (dr: 1, dc: 0)
  // - Diagonal words retain standard top-left to bottom-right flow (dr: 1, dc: 1)
  static const List<GridDirection> directions = [
    GridDirection(0, 1, 'right'),
    GridDirection(1, 0, 'down'),
    GridDirection(1, 1, 'down-right'),
  ];

  static const String englishAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String hindiAlphabet =
      'अआइईउऊऋएऐओऔकखगघचछजझटठडढणतथदधनपफबभमयरलवशषसह';

  final Random _random = Random();

  Map<String, dynamic> generateGrid({
    required List<String> words,
    required int rows,
    required int cols,
    required bool isHindi,
  }) {
    // Initialize empty grid with empty strings
    List<List<String?>> grid = List.generate(
      rows,
      (_) => List<String?>.filled(cols, null),
    );

    final Map<String, List<GridCellCoord>> placements = {};
    final sortedWords = List<String>.from(words)
      ..sort((a, b) => b.characters.length.compareTo(a.characters.length));

    for (final word in sortedWords) {
      final cells = _placeWord(grid, word, rows, cols);
      if (cells != null) {
        placements[word] = cells;
      } else {
        final fallbackCells = _placeWordFallback(grid, word, rows, cols);
        if (fallbackCells != null) {
          placements[word] = fallbackCells;
        }
      }
    }

    // Fill remaining cells
    final alphabet = isHindi ? hindiAlphabet : englishAlphabet;
    final alphabetChars = alphabet.characters.toList();
    final finalGrid = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => grid[r][c] ?? alphabetChars[_random.nextInt(alphabetChars.length)],
      ),
    );

    return {
      'grid': finalGrid,
      'placements': placements,
    };
  }

  List<GridCellCoord>? _placeWord(
    List<List<String?>> grid,
    String word,
    int rows,
    int cols, {
    int maxAttempts = 200,
  }) {
    final shuffledDirs = List<GridDirection>.from(directions)..shuffle(_random);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final dir = shuffledDirs[attempt % shuffledDirs.length];
      final startRow = _random.nextInt(rows);
      final startCol = _random.nextInt(cols);

      if (_canPlace(grid, word, startRow, startCol, dir, rows, cols)) {
        return _doPlace(grid, word, startRow, startCol, dir);
      }
    }
    return null;
  }

  List<GridCellCoord>? _placeWordFallback(
    List<List<String?>> grid,
    String word,
    int rows,
    int cols,
  ) {
    final wordLen = word.characters.length;

    // Try right direction across all rows and cols
    const right = GridDirection(0, 1, 'right');
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c <= cols - wordLen; c++) {
        if (_canPlace(grid, word, r, c, right, rows, cols)) {
          return _doPlace(grid, word, r, c, right);
        }
      }
    }

    // Try down direction across all rows and cols
    const down = GridDirection(1, 0, 'down');
    for (int r = 0; r <= rows - wordLen; r++) {
      for (int c = 0; c < cols; c++) {
        if (_canPlace(grid, word, r, c, down, rows, cols)) {
          return _doPlace(grid, word, r, c, down);
        }
      }
    }

    return null;
  }

  bool _canPlace(
    List<List<String?>> grid,
    String word,
    int startRow,
    int startCol,
    GridDirection dir,
    int rows,
    int cols,
  ) {
    // Strict horizontal constraint: Horizontal words must ALWAYS be left-to-right (dr: 0, dc: 1)
    if (dir.dr == 0 && dir.dc != 1) return false;

    final chars = word.characters.toList();
    for (int i = 0; i < chars.length; i++) {
      final r = startRow + i * dir.dr;
      final c = startCol + i * dir.dc;

      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
      if (grid[r][c] != null && grid[r][c] != chars[i]) return false;
    }
    return true;
  }

  List<GridCellCoord> _doPlace(
    List<List<String?>> grid,
    String word,
    int startRow,
    int startCol,
    GridDirection dir,
  ) {
    final cells = <GridCellCoord>[];
    final chars = word.characters.toList();
    for (int i = 0; i < chars.length; i++) {
      final r = startRow + i * dir.dr;
      final c = startCol + i * dir.dc;
      grid[r][c] = chars[i];
      cells.add(GridCellCoord(r, c));
    }
    return cells;
  }

  List<List<String>> shuffleNonWordCells(
    List<List<String>> currentGrid,
    Map<String, List<GridCellCoord>> placements,
    bool isHindi,
  ) {
    final int rows = currentGrid.length;
    final int cols = currentGrid[0].length;
    final Set<GridCellCoord> wordCells = {};

    for (final cells in placements.values) {
      wordCells.addAll(cells);
    }

    final alphabet = isHindi ? hindiAlphabet : englishAlphabet;
    final alphabetChars = alphabet.characters.toList();
    final newGrid = List.generate(
      rows,
      (r) => List<String>.from(currentGrid[r]),
    );

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final coord = GridCellCoord(r, c);
        if (!wordCells.contains(coord)) {
          newGrid[r][c] = alphabetChars[_random.nextInt(alphabetChars.length)];
        }
      }
    }

    return newGrid;
  }
}
