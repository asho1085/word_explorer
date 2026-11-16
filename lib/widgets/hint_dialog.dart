import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class HintDialog extends StatelessWidget {
  final ClueItem clue;
  final int coins;
  final int cost;
  final VoidCallback onReveal;

  const HintDialog({
    super.key,
    required this.clue,
    required this.coins,
    required this.cost,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final canAfford = coins >= cost;
    final isSameWord =
        clue.display.trim().toUpperCase() == clue.answer.trim().toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E38) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: isDark ? 0.22 : 0.12),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Close button aligned right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: mutedColor,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Hero Glowing Icon Badge
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF085), Color(0xFFF59E0B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFF78350F),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  'Get a Word Hint',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),

                // Subtitle explanation
                Text(
                  'Highlights this word on the puzzle board for 7 seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: mutedColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Word Spotlight Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF091428)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.emerald.withValues(
                        alpha: isDark ? 0.35 : 0.25,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: isSameWord
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'HIDDEN WORD',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.emerald,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              clue.answer.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: AppTheme.emerald,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${clue.answer.length} letters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'CLUE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    clue.display,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.gold.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'FIND',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: AppTheme.emerald,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    clue.answer,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.emerald,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                if (clue.hint.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clue.hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Cost & Balance Indicator Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0C172E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppTheme.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cost: $cost Coins',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      Row(
                        children: [
                          Text(
                            'Balance: $coins',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: canAfford
                                  ? textColor
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!canAfford) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You need ${cost - coins} more coins to unlock this hint',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons: Cancel and Use Hint
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: canAfford
                            ? () {
                                Navigator.of(context).pop();
                                onReveal();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford
                              ? AppTheme.gold
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0)),
                          foregroundColor: Colors.black,
                          disabledForegroundColor:
                              isDark ? Colors.white38 : Colors.black38,
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: canAfford ? 3 : 0,
                          shadowColor: AppTheme.gold.withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 18,
                              color: canAfford
                                  ? Colors.black
                                  : (isDark
                                      ? Colors.white38
                                      : Colors.black38),
                            ),
                            const SizedBox(width: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                canAfford
                                    ? 'Use Hint ($cost Coins)'
                                    : 'Need Coins',
                                style: TextStyle(
                                  color: canAfford
                                      ? Colors.black
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
