import 'dart:async';
import 'package:flutter/material.dart';

enum TestAdType { interstitial, rewarded }

/// Displays an interactive AdMob Test Ad simulation on platforms where native
/// AdMob SDK does not render (such as Flutter Web / Chrome and Desktop), or
/// as an instant visual fallback.
class AdMobTestAdOverlay extends StatefulWidget {
  final TestAdType type;
  final VoidCallback? onDismissed;
  final VoidCallback? onUserEarnedReward;

  const AdMobTestAdOverlay({
    super.key,
    required this.type,
    this.onDismissed,
    this.onUserEarnedReward,
  });

  static Future<void> show(
    BuildContext context, {
    required TestAdType type,
    VoidCallback? onDismissed,
    VoidCallback? onUserEarnedReward,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => AdMobTestAdOverlay(
        type: type,
        onDismissed: onDismissed,
        onUserEarnedReward: onUserEarnedReward,
      ),
    );
  }

  @override
  State<AdMobTestAdOverlay> createState() => _AdMobTestAdOverlayState();
}

class _AdMobTestAdOverlayState extends State<AdMobTestAdOverlay>
    with SingleTickerProviderStateMixin {
  late int _countdownSeconds;
  Timer? _timer;
  bool _rewardGranted = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _countdownSeconds = widget.type == TestAdType.rewarded ? 5 : 3;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _countdownSeconds = 0;
          if (widget.type == TestAdType.rewarded && !_rewardGranted) {
            _rewardGranted = true;
            widget.onUserEarnedReward?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isRewarded = widget.type == TestAdType.rewarded;
    final canClose = !isRewarded || _rewardGranted;

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(240),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Test Ad Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.developer_mode, size: 14, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          'Google AdMob Test Ad',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timer / Close Action
                  Row(
                    children: [
                      if (isRewarded && !_rewardGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Reward in ${_countdownSeconds}s',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (canClose)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                          onPressed: _close,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Ad Creative Card
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(150),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AdMob Icon / Preview
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF4285F4), width: 2),
                          ),
                          child: Icon(
                            isRewarded ? Icons.play_circle_fill_rounded : Icons.campaign_rounded,
                            color: isRewarded ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          isRewarded
                              ? 'Rewarded Video Test Ad'
                              : 'Interstitial Test Ad',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Nice job! This is an interactive AdMob test ad for Web & Desktop testing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Reward / Status Indicator
                        if (isRewarded) ...[
                          if (_rewardGranted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(40),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '🎉 Reward Earned: +50 Coins!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: (5 - _countdownSeconds) / 5.0,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Playing test ad... (${_countdownSeconds}s remaining)',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                        ],

                        const SizedBox(height: 28),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canClose ? const Color(0xFF10B981) : Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: canClose ? _close : null,
                            child: Text(
                              canClose ? 'Claim & Return to Game' : 'Please wait (${_countdownSeconds}s)...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
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
    );
  }
}
