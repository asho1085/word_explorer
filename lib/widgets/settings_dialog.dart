import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onReset;

  const SettingsDialog({super.key, required this.onReset});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _sound;
  late bool _vibration;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _sound = DatabaseService.instance.getSoundEnabled();
    _vibration = DatabaseService.instance.getVibrationEnabled();
    _isDark = DatabaseService.instance.isDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDark(context);
    final cardColor = AppTheme.getCard(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDarkMode ? 128 : 25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings, color: AppTheme.emerald, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: mutedColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Dark / White Mode Switcher
            _buildSettingToggle(
              icon: _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: _isDark ? AppTheme.gold : AppTheme.orange,
              title: _isDark ? 'Dark Mode' : 'White Mode',
              subtitle: _isDark ? 'Switch to Light/White theme' : 'Switch to Dark theme',
              value: _isDark,
              onChanged: (val) async {
                setState(() => _isDark = val);
                await DatabaseService.instance.setIsDarkMode(val);
              },
            ),
            const SizedBox(height: 12),

            // 2. Sound Effects Switcher
            _buildSettingToggle(
              icon: Icons.volume_up_rounded,
              iconColor: AppTheme.blue,
              title: 'Sound Effects',
              subtitle: 'Audio cues & effects',
              value: _sound,
              onChanged: (val) async {
                setState(() => _sound = val);
                await DatabaseService.instance.setSoundEnabled(val);
              },
            ),
            const SizedBox(height: 12),

            // 3. Haptic Feedback Switcher
            _buildSettingToggle(
              icon: Icons.vibration_rounded,
              iconColor: AppTheme.purple,
              title: 'Haptic Feedback',
              subtitle: 'Vibrate on word match',
              value: _vibration,
              onChanged: (val) async {
                setState(() => _vibration = val);
                await DatabaseService.instance.setVibrationEnabled(val);
              },
            ),
            const SizedBox(height: 24),

            // Reset Game Data Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cardColor,
                    title: Text('Reset All Progress?', style: TextStyle(color: textColor)),
                    content: Text(
                      'This will reset all your completed levels, stars, and coins back to default.',
                      style: TextStyle(color: mutedColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel', style: TextStyle(color: mutedColor)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reset', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseService.instance.resetAll();
                  if (context.mounted) {
                    setState(() {
                      _sound = true;
                      _vibration = true;
                      _isDark = true;
                    });
                    Navigator.of(context).pop();
                    widget.onReset();
                  }
                }
              },
              icon: const Icon(Icons.refresh, color: AppTheme.red),
              label: const Text('Reset Game Data', style: TextStyle(color: AppTheme.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.red.withAlpha(128)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final surfaceColor = AppTheme.getSurface(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppTheme.emerald,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
