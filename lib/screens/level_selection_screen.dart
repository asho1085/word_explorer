import 'package:flutter/material.dart';
import '../data/word_repository.dart';
import '../models/game_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nature_leaf_background.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String mode;
  final String modeTitle;

  const LevelSelectionScreen({
    super.key,
    required this.mode,
    required this.modeTitle,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    DatabaseService.dataRevision.addListener(_loadState);
    _loadState();
  }

  @override
  void dispose() {
    DatabaseService.dataRevision.removeListener(_loadState);
    super.dispose();
  }

  void _loadState() {
    if (!mounted) return;
    setState(() {
      _coins = DatabaseService.instance.getCoins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.getText(context);
    final cardColor = isDark ? const Color(0xFF132244) : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(22) : Colors.black.withAlpha(15);

    return Scaffold(
      body: NatureLeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back & Title
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: textColor,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.modeTitle,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Select Level',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Coins Display Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gold.withAlpha(90)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppTheme.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_coins',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 30 Levels Grid (4 columns matching Web version)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: WordRepository.totalLevels,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isUnlocked = DatabaseService.instance.isLevelUnlocked(widget.mode, level);
                      final progress = DatabaseService.instance.getProgress(widget.mode, level);

                      return _buildLevelCard(
                        level: level,
                        isUnlocked: isUnlocked,
                        progress: progress,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required int level,
    required bool isUnlocked,
    required LevelProgress? progress,
  }) {
    final bool isCompleted = progress?.completed == true;
    final int stars = progress?.stars ?? 0;
    final isDark = AppTheme.isDark(context);
    final cardColor = isDark ? const Color(0xFF132244) : Colors.white;
    final textColor = AppTheme.getText(context);
    final borderColor = isDark ? Colors.white.withAlpha(22) : Colors.black.withAlpha(15);

    // Identify if this is the active current level
    final isCurrent = isUnlocked && !isCompleted && (level == 1 || DatabaseService.instance.getProgress(widget.mode, level - 1)?.completed == true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isUnlocked
            ? () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      mode: widget.mode,
                      level: level,
                    ),
                  ),
                );
                _loadState();
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: cardColor,
                    content: Text(
                      'Complete Level ${level - 1} to unlock Level $level!',
                      style: TextStyle(color: textColor),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isCurrent
                    ? AppTheme.emerald.withAlpha(isDark ? 30 : 20)
                    : (isCompleted ? AppTheme.blue.withAlpha(isDark ? 25 : 15) : cardColor))
                : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(8)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.emerald
                  : (isCompleted ? AppTheme.blue.withAlpha(140) : borderColor),
              width: isCurrent ? 2 : (isCompleted ? 1.5 : 1),
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.emerald.withAlpha(isDark ? 90 : 50),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isUnlocked)
                Icon(
                  Icons.lock_rounded,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 22,
                )
              else ...[
                Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isCurrent
                        ? AppTheme.emerald
                        : (isCompleted ? const Color(0xFF60A5FA) : textColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final earned = i < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        '★',
                        style: TextStyle(
                          fontSize: 11,
                          color: earned
                              ? AppTheme.gold
                              : (isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(25)),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
