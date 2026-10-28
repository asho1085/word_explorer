import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LevelCompleteDialog extends StatelessWidget {
  final int level;
  final int stars;
  final int timeTakenSeconds;
  final int wordsFound;
  final int totalWords;
  final int coinsEarned;
  final VoidCallback onNextLevel;
  final VoidCallback onHome;

  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.stars,
    required this.timeTakenSeconds,
    required this.wordsFound,
    required this.totalWords,
    required this.coinsEarned,
    required this.onNextLevel,
    required this.onHome,
  });

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardColor = AppTheme.getCard(context);
    final surfaceColor = AppTheme.getSurface(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 160 : 30),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy badge
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFFFDE047), Color(0xFFD97706)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              'LEVEL COMPLETED!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Level $level Mastered',
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Stars row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final earned = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 38,
                    color: earned
                        ? AppTheme.gold
                        : (isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(25)),
                    shadows: earned
                        ? [
                            BoxShadow(
                              color: AppTheme.gold.withAlpha(120),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Stats Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.timer_outlined,
                    label: 'Time',
                    value: _formatTime(timeTakenSeconds),
                    color: AppTheme.blue,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  Container(width: 1, height: 36, color: borderColor),
                  _buildStatItem(
                    icon: Icons.check_circle_outline,
                    label: 'Words',
                    value: '$wordsFound/$totalWords',
                    color: AppTheme.emerald,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  Container(width: 1, height: 36, color: borderColor),
                  _buildStatItem(
                    icon: Icons.monetization_on,
                    label: 'Reward',
                    value: '+$coinsEarned',
                    color: AppTheme.gold,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            // Action Buttons
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.home_rounded, color: textColor, size: 26),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onHome();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNextLevel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NEXT LEVEL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: mutedColor,
          ),
        ),
      ],
    );
  }
}
