import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/word_repository.dart';
import '../models/game_models.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/grid_generator_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/level_complete_dialog.dart';
import '../widgets/word_highlighter_painter.dart';

class GameScreen extends StatefulWidget {
  final String mode;
  final int level;

  const GameScreen({
    super.key,
    required this.mode,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
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
  Timer? _gameTimer;
  int _hintsUsed = 0;
  int _coins = 120;
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
    _highlightAnimController.dispose();
    _pulseAnimController.dispose();
    super.dispose();
  }

  void _initLevel() {
    _gameTimer?.cancel();
    _hintTimer?.cancel();

    _secondsElapsed = 0;
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
        setState(() {
          _secondsElapsed++;
        });
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
        newSelection.add(GridCellCoord(start.row + i * stepR, start.col + i * stepC));
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
    final reverseWord = _selectedCells.reversed.map((c) => _grid[c.row][c.col]).join();

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
          _wordHighlights.add(newHighlight);
        });

        _highlightAnimController.reset();
        final anim = CurvedAnimation(
          parent: _highlightAnimController,
          curve: Curves.easeOutCubic,
        );
        anim.addListener(() {
          if (mounted) {
            setState(() {
              newHighlight.progress = anim.value.clamp(0.0, 1.0);
            });
          }
        });
        _highlightAnimController.forward();

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
              AdService.instance.showInterstitialAd(
                context: context,
                onDismissed: () {
                  if (_currentLevel < WordRepository.totalLevels) {
                    setState(() {
                      _currentLevel++;
                    });
                    _initLevel();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
            onHome: () {
              AdService.instance.showInterstitialAd(
                context: context,
                onDismissed: () => Navigator.of(context).pop(),
              );
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
      const SnackBar(
        backgroundColor: AppTheme.bgCard,
        content: Text('Grid letters shuffled!', style: TextStyle(color: Colors.white)),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  // Hint action (Watch Ad or use 30 coins)
  void _onHint() async {
    final unfoundClues = _clues.where((c) => !c.isFound).toList();
    if (unfoundClues.isEmpty) return;

    final targetClue = unfoundClues.first;
    final currentCoins = DatabaseService.instance.getCoins();
    final hasEnoughCoins = currentCoins >= DatabaseService.hintCost;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lightbulb_rounded, color: AppTheme.gold, size: 28),
            SizedBox(width: 8),
            Text(
              'Get a Word Hint',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you want to unlock this hint for "${targetClue.display}":',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Option 1: Watch Ad (Free + 50 Coins)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(ctx).pop();
                _watchAdForHint(targetClue);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.emerald.withAlpha(80), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.emerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Watch Video Ad',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'FREE Hint + 50 Bonus Coins 🎉',
                            style: TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Use 30 Coins
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: hasEnoughCoins
                  ? () async {
                      Navigator.of(ctx).pop();
                      final used = await DatabaseService.instance.useHint();
                      if (used) {
                        _hintsUsed++;
                        if (mounted) {
                          setState(() {
                            _coins = DatabaseService.instance.getCoins();
                          });
                          _revealHint(targetClue);
                        }
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasEnoughCoins ? AppTheme.gold.withAlpha(20) : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasEnoughCoins ? AppTheme.gold.withAlpha(70) : Colors.white.withAlpha(20),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasEnoughCoins ? AppTheme.gold : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use 30 Coins',
                            style: TextStyle(
                              color: hasEnoughCoins ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasEnoughCoins
                                ? 'Current balance: $currentCoins coins'
                                : 'Not enough coins ($currentCoins / 30)',
                            style: TextStyle(
                              color: hasEnoughCoins ? AppTheme.gold : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  void _watchAdForHint(ClueItem targetClue) {
    AdService.instance.showRewardedAd(
      context: context,
      onUserEarnedReward: (reward) async {
        await DatabaseService.instance.addCoins(50);
        await DatabaseService.instance.useHint();
        if (mounted) {
          setState(() {
            _coins = DatabaseService.instance.getCoins();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.emerald,
              content: Text(
                '🎉 Ad reward received! +50 Coins earned.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              duration: Duration(seconds: 2),
            ),
          );
          _revealHint(targetClue);
        }
      },
      onFailedToShow: () {
        _simulateWatchAd(targetClue);
      },
    );
  }

  void _simulateWatchAd(ClueItem targetClue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.tv_rounded, color: AppTheme.gold, size: 48),
              SizedBox(height: 16),
              Text(
                'Watching Rewarded Ad...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                color: AppTheme.emerald,
                backgroundColor: AppTheme.bgMedium,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // Grant 50 coins and use 30 for the hint (net +20 or free hint + bonus coins)
      await DatabaseService.instance.addCoins(50);
      await DatabaseService.instance.useHint();

      if (mounted) {
        setState(() {
          _coins = DatabaseService.instance.getCoins();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.emerald,
            content: Text('🎉 Ad reward received! +50 Coins earned.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            duration: Duration(seconds: 2),
          ),
        );
        _revealHint(targetClue);
      }
    });
  }

  void _revealHint(ClueItem targetClue) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => HintDialog(
        clue: targetClue,
        onHighlightWord: () {
          final cells = _placements[targetClue.answer];
          if (cells != null) {
            setState(() {
              _hintCells = Set.from(cells);
            });
            _hintTimer?.cancel();
            _hintTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _hintCells.clear();
                });
              }
            });
          }
        },
      ),
    );
  }

  // Clear action
  void _onClear() {
    setState(() {
      _selectedCells.clear();
      _hintCells.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final cardColor = AppTheme.getCard(context);
    final borderColor = AppTheme.getBorder(context);
    final foundCount = _clues.where((c) => c.isFound).length;

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    AppTheme.bgDark,
                    AppTheme.bgMedium,
                    AppTheme.bgSurface,
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Header Bar (Level, Timer, Coins, Theme)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'LEVEL $_currentLevel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: textColor,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, color: mutedColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(_secondsElapsed),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final currentDark = DatabaseService.instance.isDarkMode();
                            await DatabaseService.instance.setIsDarkMode(!currentDark);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: isDark ? AppTheme.gold : AppTheme.orange,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.gold.withAlpha(80)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 60 : 15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: AppTheme.gold, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                '$_coins',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Clues / Words Found Section (Matching image chips)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.mode == 'master' ? 'HINDI CLUES' : 'WORDS TO FIND',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: mutedColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$foundCount / ${_clues.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Words Wrap Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 90),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _clues.map((clue) {
                        final isFound = clue.isFound;
                        final color = isFound
                            ? AppTheme.wordColors[clue.colorIndex]
                            : cardColor;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFound ? color.withAlpha(50) : color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFound ? color : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFound) ...[
                                Icon(Icons.check_circle_rounded, color: color, size: 14),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                clue.display,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isFound ? color : textColor,
                                  decoration: isFound ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Word Search Grid Area
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 100 : 20),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final side = constraints.biggest.shortestSide;
                            return Center(
                              child: SizedBox(
                                key: _gridKey,
                                width: side,
                                height: side,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  child: Stack(
                                    children: [
                                      // Continuous rounded highlighter capsules (matching reference image)
                                      Positioned.fill(
                                        child: AnimatedBuilder(
                                          animation: Listenable.merge([
                                            _highlightAnimController,
                                            _pulseAnimController,
                                          ]),
                                          builder: (context, _) {
                                            return CustomPaint(
                                              size: Size(side, side),
                                              painter: WordHighlighterPainter(
                                                gridDim: _gridDim,
                                                highlights: _wordHighlights,
                                                selectedCells: _selectedCells,
                                                hintCells: _hintCells,
                                                animationValue: _pulseAnimController.value,
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Letters Grid (Clean, sharp, sitting directly on top in exact rows & cols)
                                      Positioned.fill(
                                        child: Column(
                                          children: List.generate(_gridDim, (row) {
                                            return Expanded(
                                              child: Row(
                                                children: List.generate(_gridDim, (col) {
                                                  return Expanded(
                                                    child: _buildCell(
                                                      letter: _grid[row][col],
                                                      isDark: isDark,
                                                      textColor: textColor,
                                                    ),
                                                  );
                                                }),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Bottom Controls Bar (Shuffle, Hint, Clear)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.shuffle_rounded,
                        label: 'Shuffle',
                        color: AppTheme.blue,
                        onTap: _onShuffle,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.lightbulb_rounded,
                        label: 'Hint (30💰)',
                        color: AppTheme.gold,
                        onTap: _onHint,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.clear_all_rounded,
                        label: 'Clear',
                        color: AppTheme.red,
                        onTap: _onClear,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required String letter,
    required bool isDark,
    required Color textColor,
  }) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: _gridDim > 9 ? 16 : 19,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : textColor,
              height: 1.0,
              shadows: isDark
                  ? const [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(80), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
