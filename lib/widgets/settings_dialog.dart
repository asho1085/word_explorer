import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'nature_leaf_background.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  static const String _appVersion = '1.0.1';

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
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: AppTheme.getBg(context),
        body: NatureLeafBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('App Preferences'),
                      _buildPanel([
                        _buildSettingToggle(
                          icon: Icons.volume_up_rounded,
                          iconColor: AppTheme.emerald,
                          title: 'Sound Effects',
                          subtitle: 'Audio cues & effects',
                          value: _sound,
                          onChanged: (val) async {
                            setState(() => _sound = val);
                            await DatabaseService.instance.setSoundEnabled(val);
                          },
                        ),
                        _buildSettingToggle(
                          icon: Icons.vibration_rounded,
                          iconColor: AppTheme.royalBlue,
                          title: 'Haptic Feedback',
                          subtitle: 'Vibrate on word match',
                          value: _vibration,
                          onChanged: (val) async {
                            setState(() => _vibration = val);
                            await DatabaseService.instance.setVibrationEnabled(
                              val,
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 26),
                      _buildSectionTitle('Legal & Info'),
                      _buildPrivacyPolicyButton(),
                      const SizedBox(height: 12),
                      _buildPanel([
                        _buildLinkTile(
                          icon: Icons.mail_outline_rounded,
                          iconColor: AppTheme.emerald,
                          title: 'Contact Support',
                          subtitle: 'shabdkhoj.support@gmail.com',
                          onTap: _openSupportEmail,
                        ),
                        _buildLinkTile(
                          icon: Icons.new_releases_outlined,
                          iconColor: AppTheme.royalBlue,
                          title: 'Version',
                          subtitle: _appVersion,
                        ),
                      ]),
                      if (AuthService.instance.currentUser != null &&
                          !AuthService.instance.currentUser!.isGuest) ...[
                        const SizedBox(height: 26),
                        _buildSectionTitle('Account'),
                        _buildPanel([
                          _buildLinkTile(
                            icon: Icons.delete_forever_rounded,
                            iconColor: AppTheme.red,
                            title: 'Delete Account',
                            subtitle:
                                'Permanently delete your account & cloud data',
                            onTap: _confirmDeleteAccount,
                          ),
                        ], destructive: true),
                      ],
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

  Widget _buildHeader() {
    const cyan = Color(0xFF23DBEC);
    return Column(
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getCard(context).withAlpha(180),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.blue.withAlpha(65)),
              ),
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.getText(context),
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getText(context),
                ),
              ),
            ),
            IconButton(
              tooltip: _isDark ? 'Light mode' : 'Dark mode',
              onPressed: () async {
                setState(() => _isDark = !_isDark);
                await DatabaseService.instance.setIsDarkMode(_isDark);
              },
              icon: Icon(
                _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: SizedBox(
            width: 160,
            height: 70,
            child: CustomPaint(
              painter: _SettingsLaurelPainter(),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.getCardLight(context),
                        AppTheme.getBg(context),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cyan.withAlpha(120)),
                    boxShadow: [
                      BoxShadow(color: cyan.withAlpha(55), blurRadius: 20),
                      BoxShadow(
                        color: AppTheme.gold.withAlpha(25),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: cyan,
                    size: 38,
                    shadows: [Shadow(color: cyan, blurRadius: 18)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Customize your app experience',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppTheme.getMuted(context)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 23,
            decoration: BoxDecoration(
              color: AppTheme.emerald,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.getText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(List<Widget> rows, {bool destructive = false}) {
    final accent = destructive ? AppTheme.red : AppTheme.blue;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withAlpha(destructive ? 180 : 85)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            destructive
                ? Color.alphaBlend(
                    AppTheme.red.withAlpha(28),
                    AppTheme.getCard(context),
                  )
                : AppTheme.getCardLight(context).withAlpha(225),
            AppTheme.getCard(context).withAlpha(215),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: AppTheme.getBorder(context),
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final cardColor = AppTheme.getCard(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppTheme.getBorder(ctx)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Account?',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete your account, saved cloud progress, stars, coins, daily streaks, and leaderboard rank.\n\nThis action cannot be undone.',
          style: TextStyle(color: mutedColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: mutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AuthService.instance.deleteAccount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account and game data have been deleted.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }



  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'shabdkhoj.support@gmail.com',
      queryParameters: {'subject': 'Support - Shabdkhoj Word Search'},
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SettingsDialog] Could not launch support email: $e');
    }
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildPreferenceRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      adaptiveControl: true,
      trailing: Semantics(
        label: title,
        child: Switch(
          value: value,
          activeTrackColor: AppTheme.emerald,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final content = _buildPreferenceRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppTheme.getText(context),
            ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool adaptiveControl = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Give enlarged labels room instead of squeezing them beside a switch.
          final stackControl =
              adaptiveControl &&
              (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22);
          final label = Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [iconColor.withAlpha(48), iconColor.withAlpha(20)],
                  ),
                  border: Border.all(color: iconColor.withAlpha(65)),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getText(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppTheme.getMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null && !stackControl) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          );
          if (!stackControl || trailing == null) return label;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label,
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: trailing),
            ],
          );
        },
      ),
    );
  }



  void _openPrivacyPolicyScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Widget _buildPrivacyPolicyButton() {
    final textColor = AppTheme.getText(context);
    final cardColor = AppTheme.getCard(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF0F2B48) : const Color(0xFFE3F2FD),
            cardColor,
          ],
        ),
        border: Border.all(color: AppTheme.blue.withAlpha(110), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withAlpha(isDark ? 40 : 25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openPrivacyPolicyScreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.blue.withAlpha(60),
                        AppTheme.blue.withAlpha(25),
                      ],
                    ),
                    border: Border.all(color: AppTheme.blue.withAlpha(90)),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to read policy on full screen',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.getMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.blue.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsLaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.gold.withAlpha(130);
    for (var side = 0; side < 2; side++) {
      canvas.save();
      canvas.scale(size.width / 190, size.height / 94);
      if (side == 1) {
        canvas.translate(190, 0);
        canvas.scale(-1, 1);
      }
      final stem = Path()
        ..moveTo(49, 88)
        ..quadraticBezierTo(12, 56, 35, 14);
      canvas.drawPath(
        stem,
        Paint()
          ..color = AppTheme.gold.withAlpha(90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      for (final point in const [
        Offset(43, 81),
        Offset(34, 70),
        Offset(28, 58),
        Offset(26, 46),
        Offset(28, 34),
        Offset(32, 22),
      ]) {
        canvas.drawPath(
          Path()
            ..moveTo(point.dx, point.dy)
            ..quadraticBezierTo(
              point.dx - 14,
              point.dy - 1,
              point.dx - 12,
              point.dy - 14,
            )
            ..quadraticBezierTo(point.dx - 1, point.dy - 10, point.dx, point.dy)
            ..moveTo(point.dx, point.dy)
            ..quadraticBezierTo(
              point.dx + 12,
              point.dy - 1,
              point.dx + 10,
              point.dy - 12,
            )
            ..quadraticBezierTo(point.dx + 1, point.dy - 8, point.dx, point.dy),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SettingsLaurelPainter oldDelegate) => false;
}
