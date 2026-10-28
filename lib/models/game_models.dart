class ClueItem {
  final String display;
  final String answer;
  final String hint;
  bool isFound;
  int colorIndex;

  ClueItem({
    required this.display,
    required this.answer,
    required this.hint,
    this.isFound = false,
    this.colorIndex = -1,
  });

  ClueItem copyWith({
    String? display,
    String? answer,
    String? hint,
    bool? isFound,
    int? colorIndex,
  }) {
    return ClueItem(
      display: display ?? this.display,
      answer: answer ?? this.answer,
      hint: hint ?? this.hint,
      isFound: isFound ?? this.isFound,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}

class GridCellCoord {
  final int row;
  final int col;

  const GridCellCoord(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCellCoord &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

class PlacedWord {
  final String word;
  final List<GridCellCoord> cells;
  final int colorIndex;

  PlacedWord({
    required this.word,
    required this.cells,
    required this.colorIndex,
  });
}

class LevelProgress {
  final String mode;
  final int level;
  final int stars;
  final int bestTime;
  final bool completed;

  LevelProgress({
    required this.mode,
    required this.level,
    this.stars = 0,
    this.bestTime = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'level': level,
        'stars': stars,
        'bestTime': bestTime,
        'completed': completed,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        mode: json['mode'] as String,
        level: json['level'] as int,
        stars: json['stars'] as int? ?? 0,
        bestTime: json['bestTime'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
