import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/word_repository.dart';
import '../models/game_models.dart';
import '../services/database_service.dart';
import '../services/grid_generator_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/level_complete_dialog.dart';
import '../widgets/nature_leaf_background.dart';
import '../widgets/word_highlighter_painter.dart';

class GameScreen extends StatefulWidget {
  final String mode;
  final int level;

  const GameScreen({super.key, required this.mode, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  /// Shared by the clue chips and the board so both read at the same size.
  static const double _boardFontSize = 20.0;

  final GridGeneratorService _gridService = GridGeneratorService();
  late int _currentLevel;
  late int _gridDim;
  late List<List<String>> _grid;
  late Map<String, List<GridCellCoord>> _placements;
  late List<ClueItem> _clues;

  // Selection & Found states (Pill-shaped highlighter animations)
  final List<GridCellCoord> _selectedCells = [];
  final List<WordHighlightItem> _wordHighlights = [];
  Set<GridCellCoord> _hintCells = {};
  Timer? _hintTimer;

  // Animation Controllers
  late AnimationController _highlightAnimController;
  late AnimationController _pulseAnimController;

  // Timer & Stats
  int _secondsElapsed = 0;
  final ValueNotifier<int> _elapsedTime = ValueNotifier(0);
  Timer? _gameTimer;
  int _hintsUsed = 0;
  int _coins = 0;
  bool _isCompleted = false;

  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level;

    _highlightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _highlightAnimController.addListener(_updateHighlightProgress);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initLevel();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _hintTimer?.cancel();
    _highlightAnimController.removeListener(_updateHighlightProgress);
    _highlightAnimController.dispose();
    _pulseAnimController.dispose();
    _elapsedTime.dispose();
    super.dispose();
  }

  /// Single listener drives the draw-in animation of the most recent word.
  /// The grid's [AnimatedBuilder] repaints on every controller tick, so no
  /// extra setState is required here.
  void _updateHighlightProgress() {
    if (_wordHighlights.isEmpty) return;
    _wordHighlights.last.progress = Curves.easeOutCubic
        .transform(_highlightAnimController.value)
        .clamp(0.0, 1.0);
  }

  void _initLevel() {
    _gameTimer?.cancel();
    _hintTimer?.cancel();

    _secondsElapsed = 0;
    _elapsedTime.value = 0;
    _hintsUsed = 0;
    _isCompleted = false;
    _selectedCells.clear();
    _wordHighlights.clear();
    _hintCells.clear();
    _coins = DatabaseService.instance.getCoins();

    _gridDim = WordRepository.getGridDimension(_currentLevel);
    _clues = WordRepository.getClues(widget.mode, _currentLevel);

    final gridWords = WordRepository.getGridWords(widget.mode, _currentLevel);
    final result = _gridService.generateGrid(
      words: gridWords,
      rows: _gridDim,
      cols: _gridDim,
      isHindi: widget.mode == 'hindi',
    );

    _grid = result['grid'] as List<List<String>>;
    _placements = result['placements'] as Map<String, List<GridCellCoord>>;

    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _elapsedTime.value = ++_secondsElapsed;
      }
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Touch and Drag Calculation
  GridCellCoord? _getCellAtOffset(Offset globalPosition) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;

    // Generous edge tolerance for natural finger/mouse dragging
    if (localPosition.dx < -25 ||
        localPosition.dx > size.width + 25 ||
        localPosition.dy < -25 ||
        localPosition.dy > size.height + 25) {
      return null;
    }

    final clampedX = localPosition.dx.clamp(0.0, size.width - 0.001);
    final clampedY = localPosition.dy.clamp(0.0, size.height - 0.001);

    final cellWidth = size.width / _gridDim;
    final cellHeight = size.height / _gridDim;

    final col = (clampedX / cellWidth).floor().clamp(0, _gridDim - 1);
    final row = (clampedY / cellHeight).floor().clamp(0, _gridDim - 1);

    return GridCellCoord(row, col);
  }

  void _onPanStart(DragStartDetails details) {
    final cell = _getCellAtOffset(details.globalPosition);
    if (cell != null) {
      setState(() {
        _selectedCells.clear();
        _selectedCells.add(cell);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cell = _getCellAtOffset(details.globalPosition);
    if (cell == null || _selectedCells.isEmpty) return;

    final start = _selectedCells.first;
    final dr = cell.row - start.row;
    final dc = cell.col - start.col;

    // Check if along a straight line: horizontal, vertical, or diagonal
    final bool isHorizontal = dr == 0;
    final bool isVertical = dc == 0;
    final bool isDiagonal = dr.abs() == dc.abs();

    if (isHorizontal || isVertical || isDiagonal) {
      final steps = dr.abs() > dc.abs() ? dr.abs() : dc.abs();
      if (steps == 0) {
        if (_selectedCells.length > 1) {
          setState(() {
            _selectedCells.clear();
            _selectedCells.add(start);
          });
        }
        return;
      }

      final stepR = dr == 0 ? 0 : dr ~/ dr.abs();
      final stepC = dc == 0 ? 0 : dc ~/ dc.abs();

      final newSelection = <GridCellCoord>[];
      for (int i = 0; i <= steps; i++) {
        newSelection.add(
          GridCellCoord(start.row + i * stepR, start.col + i * stepC),
        );
      }

      setState(() {
        _selectedCells.clear();
        _selectedCells.addAll(newSelection);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedCells.isEmpty) return;

    // Read selected letters
    final forwardWord = _selectedCells.map((c) => _grid[c.row][c.col]).join();
    final reverseWord = _selectedCells.reversed
        .map((c) => _grid[c.row][c.col])
        .join();

    final isHorizontal = _selectedCells.first.row == _selectedCells.last.row;
    final isLeftToRight = _selectedCells.first.col <= _selectedCells.last.col;

    // Check against clues
    for (int i = 0; i < _clues.length; i++) {
      final clue = _clues[i];
      if (clue.isFound) continue;

      bool matched = false;
      GridCellCoord? start;
      GridCellCoord? end;

      if (isHorizontal) {
        // Strict horizontal constraint: ONLY left-to-right allowed
        if (isLeftToRight && clue.answer == forwardWord) {
          matched = true;
          start = _selectedCells.first;
          end = _selectedCells.last;
        }
      } else {
        if (clue.answer == forwardWord) {
          matched = true;
          start = _selectedCells.first;
          end = _selectedCells.last;
        } else if (clue.answer == reverseWord) {
          matched = true;
          start = _selectedCells.last;
          end = _selectedCells.first;
        }
      }

      if (matched && start != null && end != null) {
        final color = AppTheme.wordColors[i % AppTheme.wordColors.length];
        final newHighlight = WordHighlightItem(
          word: clue.answer,
          start: start,
          end: end,
          color: color,
          progress: 0.0,
        );

        setState(() {
          clue.isFound = true;
          clue.colorIndex = i % AppTheme.wordColors.length;
          // Snap any in-flight highlight to full before animating the new one.
          for (final highlight in _wordHighlights) {
            highlight.progress = 1.0;
          }
          _wordHighlights.add(newHighlight);
        });

        _highlightAnimController.forward(from: 0);

        if (DatabaseService.instance.getVibrationEnabled()) {
          HapticFeedback.mediumImpact();
        }

        _checkLevelComplete();
        break;
      }
    }

    setState(() {
      _selectedCells.clear();
    });
  }

  void _checkLevelComplete() {
    final allFound = _clues.every((c) => c.isFound);
    if (allFound && !_isCompleted) {
      _isCompleted = true;
      _gameTimer?.cancel();

      // Calculate Stars
      int stars = 3;
      if (_secondsElapsed > 300) {
        stars = 1;
      } else if (_secondsElapsed > 180) {
        stars = 2;
      }
      if (_hintsUsed > 2 && stars > 1) {
        stars--;
      }

      // Calculate Coins
      int earnedCoins = 10 + (stars * 5);
      if (_secondsElapsed < 120) earnedCoins += 10;
      if (_secondsElapsed < 180) earnedCoins += 5;

      DatabaseService.instance.saveLevelProgress(
        widget.mode,
        _currentLevel,
        stars,
        _secondsElapsed,
        earnedCoins,
      );

      _coins = DatabaseService.instance.getCoins();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => LevelCompleteDialog(
            level: _currentLevel,
            stars: stars,
            timeTakenSeconds: _secondsElapsed,
            wordsFound: _clues.length,
            totalWords: _clues.length,
            coinsEarned: earnedCoins,
            onNextLevel: () {
              if (_currentLevel < WordRepository.totalLevels) {
                setState(() {
                  _currentLevel++;
                });
                _initLevel();
              } else {
                Navigator.of(context).pop();
              }
            },
            onHome: () {
              Navigator.of(context).pop();
            },
          ),
        );
      });
    }
  }

  // Shuffle action
  void _onShuffle() {
    setState(() {
      _grid = _gridService.shuffleNonWordCells(
        _grid,
        _placements,
        widget.mode == 'hindi',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.getCard(context),
        content: Text(
          'Filler letters shuffled! Target words remain in place.',
          style: TextStyle(color: AppTheme.getText(context)),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  // Hint action (Single clean dialog with responsive Reveal button)
  void _onHint() async {
    final unfoundClues = _clues.where((c) => !c.isFound).toList();
    if (unfoundClues.isEmpty) return;

    final targetClue = unfoundClues.first;
    final currentCoins = DatabaseService.instance.getCoins();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => HintDialog(
        clue: targetClue,
        coins: currentCoins,
        cost: DatabaseService.hintCost,
        onReveal: () async {
          final used = await DatabaseService.instance.useHint();
          if (used) {
            _hintsUsed++;
            if (mounted) {
              setState(() {
                _coins = DatabaseService.instance.getCoins();
              });
              _revealHintOnGrid(targetClue);
            }
          }
        },
      ),
    );
  }

  void _revealHintOnGrid(ClueItem targetClue) {
    final cells = _placements[targetClue.answer];
    if (cells != null && cells.isNotEmpty) {
      setState(() {
        _hintCells = Set.from(cells);
      });
      _hintTimer?.cancel();
      // Keep hint active for 7 seconds so player has ample time to trace it
      _hintTimer = Timer(const Duration(seconds: 7), () {
        if (mounted) {
          setState(() {
            _hintCells.clear();
          });
        }
      });

      if (DatabaseService.instance.getVibrationEnabled()) {
        HapticFeedback.mediumImpact();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hint: "${targetClue.answer}" is glowing on the board!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        ),
      );
    }
  }

  // Clear action
  void _onClear() {
    setState(() {
      _selectedCells.clear();
      _hintCells.clear();
    });
  }

  String get _modeTitle {
    switch (widget.mode) {
      case 'english':
        return 'English - Level $_currentLevel Aa';
      case 'hindi':
        return 'Hindi - Level $_currentLevel अ';
      case 'master':
        return 'Duo - Level $_currentLevel 👑';
      default:
        return 'Level $_currentLevel';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureLeafBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final compact = constraints.maxHeight < 620;
              final inset = compact ? 8.0 : 16.0;
              final gap = compact ? 2.0 : 10.0;
              final width = constraints.maxWidth - inset * 2;
              final height = constraints.maxHeight - (compact ? 8 : 16);
              final infoHeight = math.max(
                20.0,
                MediaQuery.textScalerOf(context).scale(12) * 1.2 + 2,
              );
              final controlsHeight = compact ? 48.0 : 72.0;
              final headerHeight = compact ? 44.0 : 52.0;
              final chromeHeight =
                  headerHeight + infoHeight + controlsHeight + gap * 3;
              var clues = _measureClues(width, false);
              var denseClues = false;
              if (height - chromeHeight - clues.height < 220) {
                denseClues = true;
                clues = _measureClues(width, true);
                while (height - chromeHeight - clues.height < 176 &&
                    clues.fontSize > 10) {
                  clues = _measureClues(
                    width,
                    true,
                    fontSize: clues.fontSize - 0.5,
                  );
                }
              }

              Widget panel(double panelWidth, _ClueLayout metrics, bool dense) {
                return SizedBox(
                  width: panelWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: _buildHeader(panelWidth),
                      ),
                      SizedBox(
                        height: infoHeight,
                        child: _buildInfo(panelWidth),
                      ),
                      SizedBox(height: gap),
                      _buildClues(metrics, dense),
                      if (landscape) const Spacer(),
                      if (!landscape) ...[
                        SizedBox(height: gap),
                        Expanded(child: Center(child: _buildBoard())),
                      ],
                      SizedBox(height: gap),
                      SizedBox(
                        height: controlsHeight,
                        child: _buildControls(compact),
                      ),
                    ],
                  ),
                );
              }

              Widget content;
              if (landscape) {
                final maxSide = math.min(height, width - 228 - gap);
                var side = maxSide;
                var panelWidth = width - side - gap;
                var metrics = _measureClues(panelWidth, false);
                var dense = false;
                while (metrics.height + chromeHeight > height && side > 176) {
                  side -= 4;
                  panelWidth = width - side - gap;
                  metrics = _measureClues(panelWidth, false);
                }
                if (metrics.height + chromeHeight > height) {
                  dense = true;
                  side = maxSide;
                  panelWidth = width - side - gap;
                  metrics = _measureClues(panelWidth, true);
                  while (metrics.height + chromeHeight > height && side > 176) {
                    side -= 4;
                    panelWidth = width - side - gap;
                    metrics = _measureClues(panelWidth, true);
                  }
                }
                content = Row(
                  children: [
                    panel(panelWidth, metrics, dense),
                    SizedBox(width: gap),
                    SizedBox(
                      width: side,
                      child: Center(child: _buildBoard()),
                    ),
                  ],
                );
              } else {
                content = panel(width, clues, denseClues);
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: inset,
                  vertical: compact ? 4 : 8,
                ),
                child: content,
              );
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 16}) {
    final dark = AppTheme.isDark(context);
    return BoxDecoration(
      color: dark ? const Color(0xFF132244) : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppTheme.getBorder(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildHeader(double width) {
    final narrow = width < 280;
    final textColor = AppTheme.getText(context);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            _modeTitle.replaceFirst(' - ', '\n'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: narrow ? 12 : 14,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: IconButton(
            tooltip: 'Toggle theme',
            onPressed: () async {
              await DatabaseService.instance.setIsDarkMode(
                !DatabaseService.instance.isDarkMode(),
              );
            },
            icon: Icon(
              AppTheme.isDark(context)
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: textColor,
              size: 20,
            ),
          ),
        ),
        if (!narrow) _buildCoins(),
      ],
    );
  }

  Widget _buildCoins() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: AppTheme.gold,
            size: 16,
          ),
          const SizedBox(width: 3),
          Text(
            '$_coins',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.getText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(double width) {
    final foundCount = _clues.where((clue) => clue.isFound).length;
    final style = GoogleFonts.poppins(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: AppTheme.getMuted(context),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _elapsedTime,
          builder: (context, seconds, _) => Text(
            _formatTime(seconds),
            key: const ValueKey('game-timer'),
            style: style,
          ),
        ),
        if (width >= 280)
          Text(
            width >= 360 ? 'WORDS TO FIND' : 'FIND WORDS',
            style: style.copyWith(fontSize: 10),
          ),
        if (width < 280) _buildCoins(),
        Text(
          '$foundCount/${_clues.length}',
          key: const ValueKey('game-progress'),
          semanticsLabel: '$foundCount of ${_clues.length} words found',
          style: style,
        ),
      ],
    );
  }

  TextStyle _clueStyle(bool dense, {double? fontSize}) => GoogleFonts.poppins(
    fontSize: fontSize ?? (dense ? 12 : 13),
    height: 1.2,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppTheme.getText(context),
  );

  _ClueLayout _measureClues(double width, bool dense, {double? fontSize}) {
    final resolvedFontSize = fontSize ?? (dense ? 12.0 : 13.0);
    final padding = dense ? 2.0 : 10.0;
    final gap = dense ? 2.0 : 6.0;
    final innerWidth = width - padding * 2 - 2;
    final sizes = <Size>[];
    var runWidth = 0.0;
    var runHeight = 0.0;
    var height = 0.0;
    for (final clue in _clues) {
      final painter = TextPainter(
        text: TextSpan(
          text: clue.display,
          style: _clueStyle(dense, fontSize: resolvedFontSize),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout(maxWidth: innerWidth - (dense ? 8 : 20));
      final size = Size(
        math.min(innerWidth, painter.width.ceilToDouble() + (dense ? 8 : 20)),
        painter.height.ceilToDouble() + (dense ? 2 : 10),
      );
      painter.dispose();
      sizes.add(size);
      if (runWidth > 0 && runWidth + gap + size.width > innerWidth) {
        height += runHeight + gap;
        runWidth = 0;
        runHeight = 0;
      }
      runWidth += (runWidth == 0 ? 0 : gap) + size.width;
      runHeight = math.max(runHeight, size.height);
    }
    return _ClueLayout(
      sizes,
      height + runHeight + padding * 2 + 2,
      resolvedFontSize,
    );
  }

  Widget _buildClues(_ClueLayout metrics, bool dense) {
    final dark = AppTheme.isDark(context);
    return Container(
      key: const ValueKey('game-clues'),
      width: double.infinity,
      height: metrics.height,
      padding: EdgeInsets.all(dense ? 2 : 10),
      decoration: _cardDecoration(),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: dense ? 2 : 6,
        runSpacing: dense ? 2 : 6,
        children: List.generate(_clues.length, (index) {
          final clue = _clues[index];
          return Semantics(
            label: clue.display,
            value: clue.isFound ? 'Found' : 'Not found',
            excludeSemantics: true,
            child: AnimatedContainer(
              key: ValueKey('game-clue-$index'),
              duration: const Duration(milliseconds: 200),
              width: metrics.sizes[index].width,
              height: metrics.sizes[index].height,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 3 : 9,
                vertical: dense ? 1 : 4,
              ),
              decoration: BoxDecoration(
                color: clue.isFound
                    ? const Color(0x262ECC71)
                    : (dark
                          ? const Color(0x0DFFFFFF)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: clue.isFound
                      ? const Color(0x662ECC71)
                      : AppTheme.getBorder(context),
                ),
              ),
              child: Text(
                clue.display,
                textAlign: TextAlign.center,
                style: _clueStyle(dense, fontSize: metrics.fontSize).copyWith(
                  color: clue.isFound
                      ? AppTheme.emerald
                      : AppTheme.getText(context),
                  decoration: clue.isFound ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.emerald,
                  decorationThickness: 2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: RepaintBoundary(
        key: const ValueKey('game-board'),
        child: Container(
          decoration: _cardDecoration(radius: 22),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.biggest.shortestSide;
              return SizedBox(
                key: _gridKey,
                width: side,
                height: side,
                child: GestureDetector(
                  key: const ValueKey('game-grid'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _highlightAnimController,
                              _pulseAnimController,
                            ]),
                            builder: (context, _) => CustomPaint(
                              painter: WordHighlighterPainter(
                                gridDim: _gridDim,
                                highlights: _wordHighlights,
                                selectedCells: _selectedCells,
                                hintCells: _hintCells,
                                animationValue: _pulseAnimController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: Column(
                            children: List.generate(
                              _gridDim,
                              (row) => Expanded(
                                child: Row(
                                  children: List.generate(
                                    _gridDim,
                                    (col) => Expanded(
                                      child: SizedBox(
                                        key: ValueKey('game-cell-$row-$col'),
                                        child: _buildCell(
                                          letter: _grid[row][col],
                                          isDark: AppTheme.isDark(context),
                                          textColor: AppTheme.getText(context),
                                          fontSize: math.min(
                                            _boardFontSize,
                                            side / _gridDim * 0.65,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls(bool compact) {
    return Row(
      children: [
        _buildWebActionButton(
          icon: Icons.lightbulb_rounded,
          label: 'Hint (30🪙)',
          onTap: _onHint,
          compact: compact,
        ),
        const SizedBox(width: 6),
        _buildWebActionButton(
          icon: Icons.cleaning_services_rounded,
          label: 'Clear',
          onTap: _onClear,
          compact: compact,
        ),
        const SizedBox(width: 6),
        _buildWebActionButton(
          icon: Icons.shuffle_rounded,
          label: 'Shuffle',
          onTap: _onShuffle,
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildCell({
    required String letter,
    required bool isDark,
    required Color textColor,
    required double fontSize,
  }) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        child: Tooltip(
          message: label == 'Hint (30🪙)' ? 'Hint (30 coins)' : label,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: _cardDecoration(radius: 14),
              child: InkWell(
                key: ValueKey(
                  'game-action-${label.split(' ').first.toLowerCase()}',
                ),
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: compact ? 16 : 24,
                            color: AppTheme.gold,
                          ),
                          if (compact && label.startsWith('Hint'))
                            Text(
                              '30',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.getText(context),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: compact ? 0 : 6),
                      Text(
                        compact && label.startsWith('Hint') ? 'Hint' : label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 11 : 12,
                          height: 1,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClueLayout {
  final List<Size> sizes;
  final double height;
  final double fontSize;

  const _ClueLayout(this.sizes, this.height, this.fontSize);
}
