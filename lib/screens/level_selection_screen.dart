import 'package:flutter/material.dart';
import '../data/word_repository.dart';
import '../models/game_models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
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
  int _coins = 120;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    setState(() {
      _coins = DatabaseService.instance.getCoins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final cardColor = AppTheme.getCard(context);
    final borderColor = AppTheme.getBorder(context);

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.modeTitle,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Select Level',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          const Icon(Icons.monetization_on, color: AppTheme.gold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$_coins',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 30 Levels Grid (4 columns)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: WordRepository.totalLevels,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
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
    final cardColor = AppTheme.getCard(context);
    final cardLightColor = AppTheme.getCardLight(context);
    final textColor = AppTheme.getText(context);
    final borderColor = AppTheme.getBorder(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                final cardColor = AppTheme.getCard(context);
                final textColor = AppTheme.getText(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: cardColor,
                    content: Text(
                      'Complete Level ${level - 1} to unlock Level $level!',
                      style: TextStyle(color: textColor),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isCompleted ? cardLightColor : cardColor)
                : (isDark ? AppTheme.bgDark.withAlpha(120) : Colors.black.withAlpha(12)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? (isCompleted ? AppTheme.emerald.withAlpha(120) : borderColor)
                  : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10)),
              width: isCompleted ? 1.5 : 1,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: isCompleted
                          ? AppTheme.emerald.withAlpha(40)
                          : Colors.black.withAlpha(isDark ? 40 : 15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isUnlocked)
                    Icon(
                      Icons.lock_rounded,
                      color: isDark ? Colors.white30 : Colors.black26,
                      size: 26,
                    )
                  else ...[
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isCompleted ? AppTheme.emerald : textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final earned = i < stars;
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: earned
                              ? AppTheme.gold
                              : (isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(25)),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
