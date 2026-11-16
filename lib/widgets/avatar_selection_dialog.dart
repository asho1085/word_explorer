import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'nature_leaf_background.dart';

/// Modal dialog/screen for browsing and choosing a player avatar.
class AvatarSelectionDialog extends StatefulWidget {
  final UserModel? currentUser;

  const AvatarSelectionDialog({super.key, this.currentUser});

  @override
  State<AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late String _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentUser?.avatar ??
        AuthService.predefinedAvatars.first;
  }

  Future<void> _selectAvatar(String avatar) async {
    if (_saving || _selectedAvatar == avatar) return;
    setState(() {
      _selectedAvatar = avatar;
      _saving = true;
    });

    try {
      await AuthService.instance.updateAvatar(avatar);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update avatar. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final avatarName =
        AuthService.avatarNames[_selectedAvatar] ?? 'Custom Avatar';

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: AppTheme.getBg(context),
        body: NatureLeafBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  children: [
                    // Top App Bar / Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Back to Profile',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Choose Your Avatar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.getText(context),
                                  ),
                                ),
                                Text(
                                  'Visible on your profile & leaderboard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Active Avatar Preview Card
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.gold.withValues(alpha: 0.12),
                            AppTheme.emerald.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.gold, AppTheme.emerald],
                              ),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.getBg(context),
                              ),
                              child: Text(
                                _selectedAvatar,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE AVATAR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: AppTheme.emerald,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  avatarName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.getText(context),
                                  ),
                                ),
                                Text(
                                  _saving ? 'Saving changes…' : 'Tap any avatar below to switch',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.getMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grid of Available Avatars
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth >= 420 ? 5 : 4;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.84,
                            ),
                            itemCount: AuthService.predefinedAvatars.length,
                            itemBuilder: (context, index) {
                              final emoji =
                                  AuthService.predefinedAvatars[index];
                              final isSelected = emoji == _selectedAvatar;
                              final name =
                                  AuthService.avatarNames[emoji] ?? '';

                              return Semantics(
                                label: name,
                                selected: isSelected,
                                button: true,
                                child: InkWell(
                                  key: ValueKey('avatar-$index'),
                                  onTap: () => _selectAvatar(emoji),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: isSelected
                                          ? AppTheme.emerald.withValues(
                                              alpha: 0.22,
                                            )
                                          : (isDark
                                              ? AppTheme.bgMedium
                                              : AppTheme.bgLightMedium),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.emerald
                                            : AppTheme.getMuted(context)
                                                .withValues(alpha: 0.2),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.emerald
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              emoji,
                                              style:
                                                  const TextStyle(fontSize: 34),
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 4,
                                              ),
                                              child: Text(
                                                name,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? AppTheme.emerald
                                                      : AppTheme.getMuted(
                                                          context,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isSelected)
                                          const Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTheme.emerald,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Bottom Done Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            'Done',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
