import 'package:flutter/material.dart';

/// Service managing ad state for the app.
/// In this release, all ads are completely disabled/removed.
/// To restore AdMob ads in future releases, refer to `lib/services/ad_service_admob_backup.dart`.
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();

  /// Global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Master switch for ads. Disabled (false) for this ad-free release.
  static const bool adsEnabled = false;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the ad service. In this release, this is a clean no-op.
  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('[AdService] App running in ad-free mode for this release.');
  }

  /// Displays an interstitial ad if enabled; otherwise immediately calls [onDismissed].
  void showInterstitialAd({BuildContext? context, VoidCallback? onDismissed}) {
    onDismissed?.call();
  }

  /// Shows a rewarded ad if enabled; otherwise invokes [onFailedToShow].
  void showRewardedAd({
    BuildContext? context,
    required Function(dynamic reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailedToShow,
  }) {
    onFailedToShow?.call();
  }

  /// Clean up cached ads (no-op when ads disabled)
  void dispose() {}
}
