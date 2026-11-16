import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nature_leaf_background.dart';

class LeaderboardScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final LeaderboardService? service;

  const LeaderboardScreen({super.key, this.onBack, this.service});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  StreamSubscription<LeaderboardState>? _subscription;
  LeaderboardState _state = const LeaderboardState();
  int _generation = 0;

  LeaderboardService get _service =>
      widget.service ?? LeaderboardService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final token = ++_generation;
    await _subscription?.cancel();
    if (!mounted || token != _generation) return;
    setState(() => _state = const LeaderboardState());
    _subscription = _service.watchLeaderboard().listen(
      (state) {
        if (mounted && token == _generation) setState(() => _state = state);
      },
      onError: (Object error, StackTrace stack) {
        if (mounted && token == _generation) {
          setState(
            () => _state = LeaderboardState(
              entries: _state.entries,
              currentUid: _state.currentUid,
              status: LeaderboardStatus.error,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topThree = _state.entries.take(3).toList();
    return Scaffold(
      body: NatureLeafBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.gold,
            onRefresh: () async {
              LeaderboardService.clearCache();
              await _loadData();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildStatus(context),
                if (topThree.isNotEmpty) ...[
                  _buildPodium(context, topThree),
                  const SizedBox(height: 16),
                ],
                ..._state.entries
                    .skip(3)
                    .map((entry) => _buildRankItem(context, entry)),
                if (_state.entries.length > 3) const SizedBox(height: 8),
                _buildPlayerStanding(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Star Leaderboard',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getText(context),
                ),
              ),
              Text(
                'Compete for the top spot with stars',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getMuted(context),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh Rankings',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    final message = switch (_state.status) {
      LeaderboardStatus.loading => 'Loading public rankings...',
      LeaderboardStatus.unavailable =>
        'Leaderboard unavailable. Firebase is not configured.',
      LeaderboardStatus.error =>
        _state.entries.isEmpty
            ? 'Could not load rankings. Check your connection and retry.'
            : 'Could not refresh rankings. Showing saved results; standings may have changed.',
      LeaderboardStatus.cached =>
        _state.entries.isEmpty
            ? 'Offline or awaiting server confirmation. No cached rankings available.'
            : 'Cached rankings — offline or awaiting server confirmation. Standings may have changed.',
      LeaderboardStatus.ready =>
        _state.entries.isEmpty ? 'No public rankings yet.' : '',
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_state.status == LeaderboardStatus.loading) ...[
            const LinearProgressIndicator(color: AppTheme.gold),
            const SizedBox(height: 12),
          ],
          Text(message, key: const ValueKey('leaderboard-status')),
          if (_state.status == LeaderboardStatus.error ||
              _state.status == LeaderboardStatus.unavailable ||
              _state.status == LeaderboardStatus.cached)
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  BoxDecoration _card(BuildContext context, {bool isMe = false}) {
    return BoxDecoration(
      color: isMe
          ? const Color(0x262ECC71)
          : AppTheme.isDark(context)
          ? const Color(0xFF132244)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: (isMe ? AppTheme.emerald : AppTheme.gold).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _avatar(LeaderboardEntry entry, Color color) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: entry.avatar.isEmpty
          ? Icon(Icons.person, color: color)
          : Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                child: Text(entry.avatar, style: const TextStyle(fontSize: 24)),
              ),
            ),
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        if (stacked) {
          return Column(
            children: entries
                .map((entry) => _buildRankItem(context, entry))
                .toList(),
          );
        }
        final order = entries.length == 3
            ? [entries[1], entries[0], entries[2]]
            : entries;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: _card(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: order
                .map(
                  (entry) =>
                      Expanded(child: _buildPodiumPillar(context, entry)),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPodiumPillar(BuildContext context, LeaderboardEntry entry) {
    final color = switch (entry.rank) {
      1 => AppTheme.gold,
      2 => const Color(0xFFBDC3C7),
      _ => const Color(0xFFCD7F32),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: color),
          _avatar(entry, color),
          const SizedBox(height: 8),
          Text(
            entry.isCurrentPlayer ? 'YOU' : entry.username,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: entry.isCurrentPlayer
                  ? AppTheme.emerald
                  : AppTheme.getText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.stars} stars',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: entry.rank == 1
                ? 125
                : entry.rank == 2
                ? 95
                : 75,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.4),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(BuildContext context, LeaderboardEntry entry) {
    return Container(
      key: ValueKey('leaderboard-${entry.uid}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: _card(context, isMe: entry.isCurrentPlayer),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(
            entry,
            entry.isCurrentPlayer ? AppTheme.emerald : AppTheme.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${entry.rank}  ${entry.username}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getText(context),
                  ),
                ),
                if (entry.isCurrentPlayer)
                  const Text(
                    'YOU',
                    style: TextStyle(
                      color: AppTheme.emerald,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Text(
                  '${entry.levelsCompleted} levels completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getMuted(context),
                  ),
                ),
                Text(
                  '${entry.stars} stars',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStanding(BuildContext context) {
    final player = _state.currentPlayer;
    final confirmed = _state.status == LeaderboardStatus.ready;
    final standing = player != null
        ? '${confirmed ? 'Your Standing' : 'Your saved standing'}: #${player.rank} (${player.username})'
        : _state.currentUid == null
        ? 'Sign in to appear in public rankings.'
        : confirmed && _state.entries.length == LeaderboardService.limit
        ? 'Not in top 100'
        : confirmed
        ? 'Unranked'
        : 'Your standing is not confirmed.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(context, isMe: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            standing,
            key: const ValueKey('player-standing'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.getText(context),
            ),
          ),
          if (player != null)
            Text(
              '${player.stars} stars',
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
