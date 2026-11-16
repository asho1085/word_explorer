import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/nature_leaf_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://sites.google.com/view/privacypolicy-shabdkhoj/home';
  static const String _googlePrivacyPolicyUrl =
      'https://policies.google.com/privacy';
  static const String _supportEmail = 'shabdkhoj.support@gmail.com';

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[PrivacyPolicyScreen] Failed to open URL $url: $e');
    }
  }

  Future<void> _openEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject ?? 'Privacy & Data Support - Shabdkhoj',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[PrivacyPolicyScreen] Failed to open email $email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final cardColor = AppTheme.getCard(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: NatureLeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor.withAlpha(200),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.blue.withAlpha(65)),
                      ),
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy & Data Safety',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Shabdkhoj: Word Search Puzzle',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Policy Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Card with Meta & Action Buttons
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isDark
                                      ? const Color(0xFF0D253F)
                                      : const Color(0xFFE8F4FD),
                                  cardColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.blue.withAlpha(70),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    isDark ? 80 : 15,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.emerald.withAlpha(40),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.emerald.withAlpha(80),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.verified_user_rounded,
                                        color: AppTheme.emerald,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PRIVACY POLICY',
                                            style: GoogleFonts.poppins(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Shabdkhoj: Word Search Puzzle',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.emerald,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Published by Vuzen Studio · Last updated: November 14, 2026',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'We respect your privacy and are committed to being transparent about how information is handled when you use the Game.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(
                                      color: AppTheme.blue.withAlpha(120),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _openEmail(_supportEmail),
                                  icon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 16,
                                    color: AppTheme.emerald,
                                  ),
                                  label: const Text(
                                    'Contact Support',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 1: Introduction
                          _buildSectionCard(
                            context,
                            number: '1',
                            title: '1. INTRODUCTION',
                            icon: Icons.info_outline_rounded,
                            iconColor: AppTheme.blue,
                            body:
                                'Welcome to Shabdkhoj: Word Search Puzzle (“Shabdkhoj,” “the Game,” “we,” “our,” or “us”), developed and published by Vuzen Studio.\n\n'
                                'We respect your privacy and are committed to being transparent about how information is handled when you use the Game.\n\n'
                                'This Privacy Policy explains what information may be stored or processed through the Game, how it is used, the services involved, and the privacy choices available to you.\n\n'
                                'Where applicable law requires consent, we will request it separately and appropriately.',
                          ),

                          const SizedBox(height: 14),

                          // Section 2: Information We Store or Process
                          _buildSectionCard(
                            context,
                            number: '2',
                            title: '2. INFORMATION WE STORE OR PROCESS',
                            subtitle: 'What We Collect',
                            icon: Icons.folder_shared_outlined,
                            iconColor: AppTheme.emerald,
                            body:
                                'Depending on whether you play as a guest or sign in, the Game may store or process the following information:\n\n'
                                '• Account Information: Your selected username, avatar emoji, and account identifier associated with your sign-in method.\n\n'
                                '• Game Information: Coin balance, star count, unlocked levels, level progress, daily play streaks, completion timestamps, and sound or haptic preferences.\n\n'
                                '• Authentication Information: Information processed by Firebase Authentication when you sign in using email or Google. We do not store your passwords in plain text.\n\n'
                                '• Guest Information: Game progress and preferences associated with a guest profile stored locally on your device.\n\n'
                                'We do not require you to provide your real name, physical address, or phone number to play the Game.',
                          ),

                          const SizedBox(height: 14),

                          // Section 3: How We Use Information
                          _buildSectionCard(
                            context,
                            number: '3',
                            title: '3. HOW WE USE INFORMATION',
                            icon: Icons.settings_suggest_outlined,
                            iconColor: AppTheme.royalBlue,
                            body:
                                'We use the information described above to:\n\n'
                                '• Operate the Game and save your progress.\n'
                                '• Unlock levels and maintain your achievements.\n'
                                '• Manage coins, stars, usernames, avatars, and daily play streaks.\n'
                                '• Provide account sign-in and restore progress across supported devices.\n'
                                '• Display leaderboard information.\n'
                                '• Respond to support requests and maintain the Game\'s functionality.\n'
                                '• Protect the Game and its users against misuse or unauthorized access.\n\n'
                                'We do not sell your personal information or use your game information for cross-app advertising or tracking.',
                          ),

                          const SizedBox(height: 14),

                          // Section 4: Guest Play and Signed-In Accounts
                          _buildSectionCard(
                            context,
                            number: '4',
                            title: '4. GUEST PLAY AND SIGNED-IN ACCOUNTS',
                            icon: Icons.account_circle_outlined,
                            iconColor: AppTheme.gold,
                            body:
                                '• Guest Play: When you play as a guest, your game progress is stored locally on your device and is not uploaded to our account cloud database. Guest progress may be lost if you clear the Game\'s app storage or uninstall the Game.\n\n'
                                '• Signed-In Accounts: When you sign in, Firebase Authentication manages your authentication, and Google Cloud Firestore stores your cloud game progress. This allows your achievements and progress to be restored across supported devices.',
                          ),

                          const SizedBox(height: 14),

                          // Section 5: Leaderboard and Displayed Information
                          _buildSectionCard(
                            context,
                            number: '5',
                            title: '5. LEADERBOARD AND DISPLAYED INFORMATION',
                            icon: Icons.leaderboard_rounded,
                            iconColor: AppTheme.emerald,
                            body:
                                'The Game features a global leaderboard. Your selected username, avatar emoji, total stars, and completed levels may be visible to other players.\n\n'
                                'Please avoid using personal or sensitive information in your username. You are responsible for the display name you choose.',
                          ),

                          const SizedBox(height: 14),

                          // Section 6: Device Permissions
                          _buildSectionCard(
                            context,
                            number: '6',
                            title: '6. DEVICE PERMISSIONS',
                            icon: Icons.perm_device_information_rounded,
                            iconColor: AppTheme.blue,
                            body:
                                'The Game requests the following Android permissions:\n\n'
                                '• VIBRATE: Provides haptic feedback when matching words. Haptic feedback can be disabled in Settings.\n'
                                '• INTERNET: Allows the Game to synchronize cloud data, daily claims, and leaderboard information for signed-in players.\n'
                                '• ACCESS_NETWORK_STATE: Allows the Game to check network availability and support offline guest play.\n\n'
                                'These permissions support the Game\'s functionality.',
                          ),

                          const SizedBox(height: 14),

                          // Section 7: Third-Party Services
                          _buildSectionCard(
                            context,
                            number: '7',
                            title: '7. THIRD-PARTY SERVICES',
                            icon: Icons.cloud_done_outlined,
                            iconColor: AppTheme.royalBlue,
                            body:
                                'The Game uses services provided by Google LLC to support authentication and cloud functionality:\n\n'
                                '• Firebase Authentication: Used to authenticate users and manage sign-in.\n'
                                '• Google Cloud Firestore: Used to store cloud game progress, streaks, daily claims, and leaderboard data.\n\n'
                                'These services process information according to their applicable privacy policies and terms.\n\n'
                                'Google Privacy Policy:\n$_googlePrivacyPolicyUrl',
                            actionButton: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.blue,
                                side: BorderSide(
                                  color: AppTheme.blue.withAlpha(120),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _openUrl(_googlePrivacyPolicyUrl),
                              icon: const Icon(Icons.link_rounded, size: 16),
                              label: const Text(
                                'Open Google Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Section 8: Data Sharing
                          _buildSectionCard(
                            context,
                            number: '8',
                            title: '8. DATA SHARING',
                            icon: Icons.share_outlined,
                            iconColor: AppTheme.emerald,
                            body:
                                'We do not sell your personal information or share it with third parties for their independent advertising purposes.\n\n'
                                'Information may be processed or disclosed when necessary to:\n'
                                '• Provide authentication and cloud progress features through Firebase.\n'
                                '• Display information on the Game\'s public leaderboard.\n'
                                '• Comply with applicable legal obligations.\n'
                                '• Protect the Game, its users, and our rights against misuse or unauthorized activity.',
                          ),

                          const SizedBox(height: 14),

                          // Section 9: Data Security and Retention
                          _buildSectionCard(
                            context,
                            number: '9',
                            title: '9. DATA SECURITY AND RETENTION',
                            icon: Icons.security_rounded,
                            iconColor: AppTheme.blue,
                            body:
                                'We retain signed-in account information and associated cloud game progress for as long as your account remains active, unless a longer or shorter retention period is required or permitted by applicable law.\n\n'
                                'We use security features provided by Google Firebase and implement appropriate security rules and measures to help protect information stored in our systems.\n\n'
                                'Guest progress remains on your device until you clear the Game\'s app storage or uninstall the Game.',
                          ),

                          const SizedBox(height: 14),

                          // Section 10: Privacy Choices and Data Deletion
                          _buildSectionCard(
                            context,
                            number: '10',
                            title: '10. PRIVACY CHOICES AND DATA DELETION',
                            icon: Icons.delete_forever_rounded,
                            iconColor: AppTheme.red,
                            body:
                                'You can manage your game information and request deletion of your account as described below.\n\n'
                                '• In-App Account Deletion: If available in your version of the Game, you can permanently delete your account by opening Settings → Account → Delete Account. Account deletion removes your authentication record and associated cloud game data, including progress, streaks, and leaderboard information, subject to applicable legal retention requirements.\n\n'
                                '• Email-Based Account Deletion Request: You may request deletion of your account and associated personal data by emailing $_supportEmail from your registered account email address. Please include your username or other account details to help us identify your account. We aim to process deletion requests within 30 days.\n\n'
                                '• Guest Data Removal: You can remove guest progress by clearing the Game\'s app storage through your device settings or uninstalling the Game.',
                            actionButton: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.red,
                                side: BorderSide(
                                  color: AppTheme.red.withAlpha(120),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _openEmail(
                                _supportEmail,
                                subject:
                                    'Account Deletion Request - Shabdkhoj',
                              ),
                              icon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Email Deletion Request',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Section 11: Children's Privacy
                          _buildSectionCard(
                            context,
                            number: '11',
                            title: "11. CHILDREN'S PRIVACY",
                            icon: Icons.family_restroom_rounded,
                            iconColor: AppTheme.emerald,
                            body:
                                'Shabdkhoj is a family-friendly word search game.\n\n'
                                'We do not knowingly collect personal information from children under 13 without the consent required by applicable law. Guest Mode allows players to enjoy the Game without creating an account or providing account registration details.\n\n'
                                'If you believe that personal information has been collected from a child in violation of applicable law, please contact us so we can review and take appropriate action.',
                          ),

                          const SizedBox(height: 14),

                          // Section 12: Contact Us
                          _buildSectionCard(
                            context,
                            number: '12',
                            title: '12. CONTACT US',
                            icon: Icons.contact_support_outlined,
                            iconColor: AppTheme.blue,
                            body:
                                'If you have any questions, requests, or concerns regarding this Privacy Policy or your personal information, please contact us:\n\n'
                                '• Email: $_supportEmail\n'
                                '• Developer: Vuzen Studio\n'
                                '• Game: Shabdkhoj: Word Search Puzzle\n\n'
                                'For your convenience, you can access the online version at any time to review our latest privacy practices.',
                            actionButton: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(
                                      color: AppTheme.emerald.withAlpha(120),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _openEmail(_supportEmail),
                                  icon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 16,
                                    color: AppTheme.emerald,
                                  ),
                                  label: const Text(
                                    'Email Support',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => _openUrl(_privacyPolicyUrl),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: AppTheme.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Online Privacy Policy: $_privacyPolicyUrl',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.blue,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: AppTheme.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bottom Action Button
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                              ),
                              label: const Text(
                                'I Understand · Return to App',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String number,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required String body,
    Widget? actionButton,
  }) {
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);
    final cardColor = AppTheme.getCard(context);
    final borderColor = AppTheme.getBorder(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(AppTheme.isDark(context) ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withAlpha(65)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: mutedColor,
            ),
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 12),
            actionButton,
          ],
        ],
      ),
    );
  }
}
