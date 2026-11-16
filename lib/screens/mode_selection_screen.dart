import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/word_repository.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/leaderboard_service.dart';
import '../services/streak_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_selection_dialog.dart';
import '../widgets/nature_leaf_background.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/welcome_bonus_dialog.dart';
import 'leaderboard_screen.dart';
import 'level_selection_screen.dart';
import 'login_screen.dart';

class _ModeConfig {
  final String mode;
  final String title;
  final String tag;
  final String subtitle;
  final String? letter;
  final Color accent;

  const _ModeConfig(
    this.mode,
    this.title,
    this.tag,
    this.subtitle,
    this.letter,
    this.accent,
  );
}

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  static const _modes = [
    _ModeConfig(
      'master',
      'Duo Mode',
      'FEATURED',
      'Hindi → English',
      null,
      AppTheme.royalBlue,
    ),
    _ModeConfig(
      'english',
      'English Mode',
      'CLASSIC',
      'Find English words',
      'Aa',
      AppTheme.emerald,
    ),
    _ModeConfig(
      'hindi',
      'Hindi Mode',
      'DEVANAGARI',
      'हिन्दी शब्द खोजें',
      'अ',
      AppTheme.orange,
    ),
  ];
  int _tab = 0;
  bool _claiming = false;
  bool _loggingOut = false;
  StreamSubscription<LeaderboardState>? _board;
  int? _rank;

  bool get _profileBusy => _loggingOut;

  @override
  void initState() {
    super.initState();
    DatabaseService.dataRevision.addListener(_refresh);
    AuthService.instance.userNotifier.addListener(_refresh);
    StreakService.instance.addListener(_refresh);
    _board = LeaderboardService.instance.watchLeaderboard().listen((state) {
      final rank = state.currentPlayer?.rank;
      if (mounted && rank != _rank) setState(() => _rank = rank);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWelcomeBonus());
  }

  @override
  void dispose() {
    DatabaseService.dataRevision.removeListener(_refresh);
    AuthService.instance.userNotifier.removeListener(_refresh);
    StreakService.instance.removeListener(_refresh);
    unawaited(_board?.cancel());
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _checkWelcomeBonus() async {
    if (!mounted || DatabaseService.instance.isWelcomeBonusClaimed()) return;
    await showDialog<bool>(
      context: context,
      builder: (_) => WelcomeBonusDialog(
        username: AuthService.instance.currentUser?.username ?? 'Explorer',
        bonusCoins: 200,
      ),
    );
    _refresh();
  }

  int _completedLevels(String mode) {
    var completed = 0;
    for (var level = 1; level <= WordRepository.totalLevels; level++) {
      if (DatabaseService.instance.getProgress(mode, level)?.completed ==
          true) {
        completed++;
      }
    }
    return completed;
  }

  Future<void> _openMode(_ModeConfig config) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LevelSelectionScreen(mode: config.mode, modeTitle: config.title),
      ),
    );
    _refresh();
  }

  Future<void> _openSettings() async {
    await showDialog(context: context, builder: (_) => const SettingsDialog());
    _refresh();
  }

  void _selectTab(int tab) {
    if (!_profileBusy) setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == 0 && !_profileBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        body: _tab == 1
            ? LeaderboardScreen(onBack: () => _selectTab(0))
            : NatureLeafBackground(
                child: SafeArea(
                  bottom: _tab == 3,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: switch (_tab) {
                        2 => _buildCoins(),
                        3 => _buildProfile(),
                        _ => _buildHome(),
                      },
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: _tab == 3 ? null : _buildNavigation(),
      ),
    );
  }

  Widget _buildNavigation() {
    const labels = ['Home', 'Leaderboard', 'Coins', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.emoji_events_outlined,
      Icons.monetization_on_rounded,
      Icons.person_outline_rounded,
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.getCard(context), AppTheme.getBg(context)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.getMuted(context).withValues(alpha: .38),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == _tab,
                    button: true,
                    child: InkWell(
                      key: ValueKey('nav-${labels[i].toLowerCase()}'),
                      onTap: () => _selectTab(i),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: i == _tab
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.emerald.withValues(alpha: .35),
                                    AppTheme.emerald.withValues(alpha: .08),
                                  ],
                                )
                              : null,
                          border: Border.all(
                            color: i == _tab
                                ? AppTheme.emerald.withValues(alpha: .75)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[i],
                              size: 25,
                              color: i == _tab
                                  ? AppTheme.emerald
                                  : AppTheme.getText(context),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              labels[i],
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getText(context),
                              ),
                            ),
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

  Widget _buildHome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxHeight >= 820;
        return SingleChildScrollView(
          key: const ValueKey('home-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              SizedBox(height: roomy ? 20 : 14),
              _buildWelcome(),
              SizedBox(height: roomy ? 23 : 16),
              _section('SELECT MODE', trailing: '3 ways to play'),
              const SizedBox(height: 13),
              for (var i = 0; i < _modes.length; i++) ...[
                if (i > 0) SizedBox(height: roomy ? 14 : 11),
                _buildModeCard(_modes[i], roomy: roomy),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final user = AuthService.instance.currentUser;
    final isDark = AppTheme.isDark(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectTab(3),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: _panelDecoration(),
              child: Row(
                children: [
                  _iconTile(
                    AppTheme.emerald,
                    child: Text(
                      user?.avatar ?? AuthService.predefinedAvatars.first,
                      style: const TextStyle(fontSize: 24),
                    ),
                    size: 36,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAYER',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.4,
                            color: AppTheme.getMuted(context),
                          ),
                        ),
                        Text(
                          user?.username ?? 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: AppTheme.getMuted(context),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        InkWell(
          onTap: () => _selectTab(2),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: _panelDecoration(accent: AppTheme.gold),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppTheme.gold,
                  size: 21,
                ),
                const SizedBox(width: 5),
                Text(
                  '${DatabaseService.instance.getCoins()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 7),
        _squareButton(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          isDark ? 'Light mode' : 'Dark mode',
          () async {
            await DatabaseService.instance.setIsDarkMode(!isDark);
          },
          color: AppTheme.gold,
        ),
        const SizedBox(width: 7),
        _squareButton(Icons.settings_rounded, 'Settings', _openSettings),
      ],
    );
  }

  Widget _buildWelcome() {
    final db = DatabaseService.instance;
    final completed = db.getTotalCompletedLevels();
    final stars = db.getTotalStars();
    final total = _modes.length * WordRepository.totalLevels;
    final rank = _rank == null ? '—' : '#$_rank';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(accent: AppTheme.emerald, glow: true),
      child: Column(
        children: [
          Row(
            children: [
              _iconTile(
                AppTheme.emerald,
                icon: Icons.auto_awesome_rounded,
                size: 42,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${AuthService.instance.currentUser?.username ?? 'Explorer'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Keep exploring and learn new words!',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.getMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _progress(
                  completed / total,
                  AppTheme.emerald,
                  height: 9,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completed/$total',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getMuted(context),
                ),
              ),
              Text(
                ' · ${(completed / total * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _stat(Icons.star_rounded, '$stars', 'Stars', AppTheme.gold),
              _stat(
                Icons.bar_chart_rounded,
                '$completed',
                'Levels',
                AppTheme.emerald,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTab(1),
                  borderRadius: BorderRadius.circular(12),
                  child: _statContent(
                    Icons.emoji_events_rounded,
                    rank,
                    'Rank',
                    AppTheme.gold,
                  ),
                ),
              ),
              _stat(
                Icons.local_fire_department_rounded,
                '${StreakService.instance.current}',
                'Streak',
                AppTheme.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) =>
      Expanded(child: _statContent(icon, value, label, color));

  Widget _statContent(IconData icon, String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .10),
            AppTheme.getCard(context).withValues(alpha: .45),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: AppTheme.getMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(_ModeConfig config, {bool roomy = true}) {
    final completed = _completedLevels(config.mode);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMode(config),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: _panelDecoration(accent: config.accent),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            config.accent,
                            config.accent.withValues(alpha: .45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      roomy ? 17 : 12,
                      12,
                      roomy ? 17 : 12,
                    ),
                    child: Row(
                      children: [
                        _iconTile(
                          config.accent,
                          size: 52,
                          icon: config.letter == null
                              ? Icons.workspace_premium_rounded
                              : null,
                          child: config.letter == null
                              ? null
                              : Text(
                                  config.letter!,
                                  style: TextStyle(
                                    fontSize: 27,
                                    color: config.accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final title = Text(
                                    config.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  );
                                  final badge = _badge(
                                    config.tag,
                                    config.accent,
                                  );
                                  if (constraints.maxWidth < 220 ||
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(17) >
                                          20) {
                                    return Wrap(
                                      spacing: 7,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [title, badge],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Flexible(child: title),
                                      const SizedBox(width: 7),
                                      badge,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 5),
                              Text(
                                config.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: config.accent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _progress(
                                      completed / WordRepository.totalLevels,
                                      config.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$completed/${WordRepository.totalLevels}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.getMuted(context),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoins() {
    final canClaim = DatabaseService.instance.canClaimDailyBonus();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(AppTheme.gold, icon: Icons.monetization_on_rounded, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Coins',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Collect coins, unlock hints, and more!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.gold, width: 1.5),
              gradient: LinearGradient(
                colors: [
                  AppTheme.gold.withValues(alpha: .12),
                  AppTheme.getCard(context),
                  AppTheme.royalBlue.withValues(alpha: .22),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: .12),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 180,
                  height: 118,
                  child: CustomPaint(painter: _CoinPainter()),
                ),
                Text(
                  '${DatabaseService.instance.getCoins()}',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Total Coins',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.getMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.royalBlue.withValues(alpha: .85),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  AppTheme.royalBlue.withValues(alpha: .55),
                  AppTheme.royalBlue.withValues(alpha: .18),
                  AppTheme.orange.withValues(alpha: .25),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.royalBlue.withValues(alpha: .25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: _actionRow(
              Icons.card_giftcard_rounded,
              AppTheme.gold,
              'Daily Bonus',
              subtitle: canClaim
                  ? 'Claim your free +50 coins every day!'
                  : 'Claimed today. Come back tomorrow!',
              onTap: _claiming ? null : _showBonusCoinsDialog,
              trailing: _claiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      canClaim
                          ? Icons.chevron_right_rounded
                          : Icons.check_circle_rounded,
                      color: canClaim
                          ? AppTheme.getText(context)
                          : AppTheme.emerald,
                    ),
            ),
          ),
          const SizedBox(height: 22),
          _section('Get More Coins'),
          const SizedBox(height: 14),
          Container(
            decoration: _panelDecoration(accent: AppTheme.blue),
            child: _actionRow(
              Icons.share_rounded,
              AppTheme.blue,
              'Invite Friends',
              subtitle: 'Referral rewards are not available yet',
              trailing: _badge('SOON', AppTheme.blue),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Use your coins for hints when you need a little help finding a word.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.getMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final streaks = StreakService.instance;
    return Container(
      key: const ValueKey('profile-streak'),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(accent: AppTheme.orange),
      child: Row(
        children: [
          _iconTile(
            AppTheme.orange,
            icon: Icons.local_fire_department_rounded,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${streaks.current}-day streak · Best ${streaks.streak.best}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = AuthService.instance.currentUser;
    final isGuest = user == null || user.isGuest;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _squareButton(
                Icons.chevron_left_rounded,
                'Back to Home',
                () => _selectTab(0),
              ),
              const Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              _squareButton(
                Icons.edit_outlined,
                'Edit name',
                user == null || _profileBusy ? null : () => _editName(user),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              label: 'Change avatar',
              button: true,
              child: InkWell(
                key: const ValueKey('edit-avatar-button'),
                onTap: user == null || _profileBusy
                    ? null
                    : () => _openAvatarPicker(user),
                borderRadius: BorderRadius.circular(50),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(3),
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
                          user?.avatar ?? AuthService.predefinedAvatars.first,
                          style: const TextStyle(fontSize: 51),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.emerald,
                          border: Border.all(
                            color: AppTheme.getBg(context),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              key: const ValueKey('edit-avatar-pill'),
              onPressed: user == null || _profileBusy
                  ? null
                  : () => _openAvatarPicker(user),
              icon: const Icon(Icons.palette_outlined, size: 14),
              label: const Text(
                'Change Avatar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.emerald,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.username ?? 'Guest Player',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          Text(
            isGuest ? 'Playing on this device' : user.email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.getMuted(context)),
          ),
          const SizedBox(height: 9),
          Center(
            child: _badge(
              isGuest
                  ? 'Guest Account'
                  : user.provider == 'google'
                  ? 'Google Account'
                  : 'Password Account',
              AppTheme.emerald,
              icon: Icons.shield_outlined,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: _panelDecoration(accent: AppTheme.gold),
            child: Row(
              children: [
                _stat(
                  Icons.star_rounded,
                  '${DatabaseService.instance.getTotalStars()}',
                  'Total Stars',
                  AppTheme.gold,
                ),
                _stat(
                  Icons.monetization_on_rounded,
                  '${DatabaseService.instance.getCoins()}',
                  'Coins',
                  AppTheme.gold,
                ),
                _stat(
                  Icons.bar_chart_rounded,
                  '${DatabaseService.instance.getTotalCompletedLevels()}',
                  'Levels Completed',
                  AppTheme.emerald,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildStreakCard(),
          const SizedBox(height: 16),
          Container(
            decoration: _panelDecoration(),
            child: Column(
              children: [
                _actionRow(
                  Icons.emoji_events_rounded,
                  AppTheme.gold,
                  'Leaderboard',
                  onTap: () => _selectTab(1),
                ),
                _divider(),
                _actionRow(
                  Icons.bar_chart_rounded,
                  AppTheme.emerald,
                  'My Progress',
                  onTap: _profileBusy ? null : _showProgress,
                ),
                _divider(),
                _actionRow(
                  Icons.settings_rounded,
                  AppTheme.textMuted,
                  'Settings',
                  onTap: _profileBusy ? null : _openSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _profileBusy ? null : _logout,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(isGuest ? Icons.login_rounded : Icons.logout_rounded),
            label: Text(
              _loggingOut
                  ? 'Signing out…'
                  : isGuest
                  ? 'Log In / Sign Up'
                  : 'Log Out',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAvatarPicker(UserModel? user) async {
    if (user == null || _profileBusy) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AvatarSelectionDialog(currentUser: user),
    );
  }

  Future<void> _logout() async {
    if (_profileBusy) return;
    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _loggingOut = false);
        _message('Could not log out. Please try again.');
      }
    }
  }

  Future<void> _editName(UserModel user) => showDialog<void>(
    context: context,
    builder: (_) => _EditNameDialog(username: user.username),
  );

  void _showProgress() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Progress'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in _modes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mode.title}: ${_completedLevels(mode.mode)}/${WordRepository.totalLevels}',
                        style: TextStyle(
                          color: mode.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _progress(
                        _completedLevels(mode.mode) /
                            WordRepository.totalLevels,
                        mode.accent,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBonusCoinsDialog() async {
    final canClaim = DatabaseService.instance.canClaimDailyBonus();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Bonus Coins'),
        content: Text(
          canClaim
              ? 'Claim your +50 coins to unlock extra hints on your next puzzle.'
              : 'You have already claimed today’s bonus. Come back tomorrow for another +50 coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(canClaim ? 'Cancel' : 'Got it'),
          ),
          if (canClaim)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Claim +50'),
            ),
        ],
      ),
    );
    if (confirm != true || !mounted || _claiming) return;
    setState(() => _claiming = true);
    try {
      final claimed = await DatabaseService.instance.claimDailyBonus();
      if (mounted) {
        _message(
          claimed ? '+50 Bonus Coins added!' : 'Bonus already claimed today.',
        );
      }
    } catch (_) {
      if (mounted) _message('Could not claim your bonus. Please try again.');
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );

  BoxDecoration _panelDecoration({Color? accent, bool glow = false}) {
    final color = accent ?? AppTheme.blue;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.getCardLight(context).withValues(alpha: .9),
          AppTheme.getCard(context),
          Color.alphaBlend(
            color.withValues(alpha: .06),
            AppTheme.getCard(context),
          ),
        ],
      ),
      border: Border.all(
        color: color.withValues(alpha: accent == null ? .27 : .48),
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                color: color.withValues(alpha: .13),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }

  Widget _iconTile(
    Color accent, {
    IconData? icon,
    Widget? child,
    double size = 44,
  }) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * .27),
      border: Border.all(color: accent.withValues(alpha: .4)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withValues(alpha: .27), accent.withValues(alpha: .07)],
      ),
    ),
    child: child ?? Icon(icon, color: accent, size: size * .57),
  );

  Widget _squareButton(
    IconData icon,
    String tooltip,
    VoidCallback? onTap, {
    Color? color,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 44),
      padding: const EdgeInsets.all(9),
      backgroundColor: AppTheme.getCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppTheme.getMuted(context).withValues(alpha: .3),
        ),
      ),
    ),
    icon: Icon(icon, size: 22, color: color ?? AppTheme.getMuted(context)),
  );

  Widget _badge(String text, Color color, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .55)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: icon == null ? 8 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _progress(double value, Color color, {double height = 6}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      backgroundColor: AppTheme.getMuted(context).withValues(alpha: .23),
      color: color,
    ),
  );

  Widget _section(String title, {String? trailing}) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: AppTheme.emerald,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: trailing == null ? 0 : 1,
            color: trailing == null
                ? AppTheme.getText(context)
                : AppTheme.getMuted(context),
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: TextStyle(fontSize: 12, color: AppTheme.getMuted(context)),
        ),
    ],
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(
      height: 1,
      color: AppTheme.getMuted(context).withValues(alpha: .25),
    ),
  );

  Widget _actionRow(
    IconData icon,
    Color accent,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: subtitle == null ? 8 : 12,
      ),
      child: Row(
        children: [
          _iconTile(accent, icon: icon, size: subtitle == null ? 30 : 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.getMuted(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 7),
            trailing,
          ] else if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: AppTheme.getText(context)),
        ],
      ),
    ),
  );
}

class _EditNameDialog extends StatefulWidget {
  final String username;

  const _EditNameDialog({required this.username});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.username,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error = AuthService.validateUsername(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateUsername(_controller.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AuthException
              ? e.message
              : 'Could not save your name. Try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        maxLength: 20,
        decoration: InputDecoration(
          labelText: 'Player name',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 118);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppTheme.gold.withValues(alpha: .38), Colors.transparent],
      ).createShader(const Rect.fromLTWH(5, 0, 170, 118));
    canvas.drawOval(const Rect.fromLTWH(5, 0, 170, 118), glow);
    void stack(double x, double y, int count) {
      for (var i = 0; i < count; i++) {
        final top = y - i * 11;
        final rect = Rect.fromLTWH(x, top, 57, 26);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFC400), Color(0xFFE99A00), Color(0xFFFFD72E)],
            ).createShader(rect),
        );
        canvas.drawOval(
          Rect.fromLTWH(x, top - 3, 57, 17),
          Paint()..color = const Color(0xFFFFE256),
        );
        canvas.drawOval(
          Rect.fromLTWH(x + 5, top, 47, 11),
          Paint()..color = const Color(0xFFFFC600),
        );
      }
      for (var i = 0; i < count; i++) {
        canvas.drawArc(
          Rect.fromLTWH(x + 1, y - i * 11 + 10, 55, 13),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFFFE256)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    stack(30, 76, 3);
    stack(66, 59, 5);
    const center = Offset(117, 77);
    canvas.drawCircle(
      center,
      34,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF17B), Color(0xFFFFBC00)],
        ).createShader(const Rect.fromLTWH(83, 43, 68, 68)),
    );
    canvas.drawCircle(center, 28, Paint()..color = const Color(0xFFFFC400));
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = const Color(0xFFFFE470)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? 19.0 : 9.0;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFEC68));
    for (final point in [
      const Offset(23, 52),
      const Offset(145, 26),
      const Offset(164, 73),
    ]) {
      final path = Path()
        ..moveTo(point.dx, point.dy - 8)
        ..quadraticBezierTo(point.dx + 2, point.dy - 2, point.dx + 7, point.dy)
        ..quadraticBezierTo(point.dx + 2, point.dy + 2, point.dx, point.dy + 8)
        ..quadraticBezierTo(point.dx - 2, point.dy + 2, point.dx - 7, point.dy)
        ..quadraticBezierTo(point.dx - 2, point.dy - 2, point.dx, point.dy - 8);
      canvas.drawPath(path, Paint()..color = AppTheme.gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoinPainter oldDelegate) => false;
}
