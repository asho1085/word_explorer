import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_dialog.dart';
import 'level_selection_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  int _coins = 120;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  void _loadCoins() {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title / Branding
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.emerald.withAlpha(120), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.emerald.withAlpha(50),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                      Icons.grid_4x4_rounded,
                                      color: AppTheme.emerald,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'WORD SEARCH',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emerald,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'EXPLORER',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions: Theme Toggle, Coins & Settings
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
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
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
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => SettingsDialog(
                                    onReset: _loadCoins,
                                  ),
                                ).then((_) => _loadCoins());
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(Icons.settings, color: isDark ? Colors.white70 : AppTheme.textDarkMuted, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Header text
                    Text(
                      'Choose Your Mode',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a game mode to start exploring words',
                      style: TextStyle(
                        fontSize: 14,
                        color: mutedColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Mode Cards List
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildModeCard(
                              mode: 'master',
                              title: 'Master Mode',
                              tag: 'FEATURED',
                              subtitle: 'Hindi Clues → Find English Words',
                              description: 'Read clues in Hindi and find matching English words in the grid.',
                              icon: Icons.psychology_rounded,
                              accentColor: AppTheme.purple,
                              gradientColors: const [Color(0xFF2A164D), Color(0xFF1E1038)],
                            ),
                            const SizedBox(height: 16),
                            _buildModeCard(
                              mode: 'english',
                              title: 'English Mode',
                              tag: 'CLASSIC',
                              subtitle: 'Find English Words',
                              description: 'Classic word search puzzle with English vocabulary.',
                              icon: Icons.spellcheck_rounded,
                              accentColor: AppTheme.emerald,
                              gradientColors: const [Color(0xFF0F352E), Color(0xFF0A241F)],
                            ),
                            const SizedBox(height: 16),
                            _buildModeCard(
                              mode: 'hindi',
                              title: 'Hindi Mode',
                              tag: 'DEVANAGARI',
                              subtitle: 'हिन्दी शब्द खोजें',
                              description: 'Explore Hindi words in a complete Devanagari grid.',
                              icon: Icons.translate_rounded,
                              accentColor: AppTheme.orange,
                              gradientColors: const [Color(0xFF381F0E), Color(0xFF241308)],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildModeCard({
    required String mode,
    required String title,
    required String tag,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
  }) {
    // Get unlocked level for this mode
    int highestUnlocked = 1;
    for (int l = 1; l <= 20; l++) {
      if (DatabaseService.instance.isLevelUnlocked(mode, l)) {
        highestUnlocked = l;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LevelSelectionScreen(mode: mode, modeTitle: title),
              ),
            );
            _loadCoins();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentColor.withAlpha(100)),
                            ),
                            child: Icon(icon, color: accentColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withAlpha(60)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Level $highestUnlocked / 20 Unlocked',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(120),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
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
