import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class WelcomeBonusDialog extends StatefulWidget {
  final String username;
  final int bonusCoins;

  const WelcomeBonusDialog({
    super.key,
    required this.username,
    this.bonusCoins = 200,
  });

  @override
  State<WelcomeBonusDialog> createState() => _WelcomeBonusDialogState();
}

class _WelcomeBonusDialogState extends State<WelcomeBonusDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      // Ensure coins is set to 200 (avoiding excess duplicates if tapped repeatedly)
      final current = DatabaseService.instance.getCoins();
      if (current < widget.bonusCoins) {
        await DatabaseService.instance.setCoins(widget.bonusCoins);
      } else {
        final completed = DatabaseService.instance.getTotalCompletedLevels();
        if (completed == 0) {
          await DatabaseService.instance.setCoins(widget.bonusCoins);
        }
      }
      await DatabaseService.instance.setWelcomeBonusClaimed();
    } catch (e) {
      debugPrint('[Bonus] Claim error: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardColor = AppTheme.getCard(context);
    final textColor = AppTheme.getText(context);
    final mutedColor = AppTheme.getMuted(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 80,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.gold.withAlpha(120), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withAlpha(isDark ? 60 : 35),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 140 : 30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -8,
                right: -4,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: mutedColor,
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Close',
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Glowing Icon Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withAlpha(35),
                  border: Border.all(color: AppTheme.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🪙', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                '🎉 Welcome Bonus!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Welcome, ${widget.username}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // Amount Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.gold.withAlpha(140),
                    width: 1.5,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '+',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.gold,
                      ),
                    ),
                    Text(
                      '${widget.bonusCoins}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'COINS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Here is your starter gift to unlock hints, find difficult words, and climb to the top of the leaderboard!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 24),

              // Claim Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isClaiming ? null : _claimReward,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: AppTheme.gold.withAlpha(120),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isClaiming ? 'Claiming...' : 'Claim ${widget.bonusCoins} Coins',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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
        ],
      ),
    ),
  ),
);
  }
}

