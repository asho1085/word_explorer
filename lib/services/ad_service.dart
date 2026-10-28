import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/admob_test_ad_overlay.dart';

/// Service managing AdMob configuration, test ad unit IDs, and ad lifecycles.
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();

  /// Global navigator key to display test ads on web and desktop overlays
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Interstitial Ad cache
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // Rewarded Ad cache
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  /// Whether current platform is supported by google_mobile_ads (Android/iOS only)
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    } catch (_) {}
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Helper to safely fetch an environment variable from .env or fallback
  static String _getEnv(String key, String fallback) {
    try {
      if (dotenv.isInitialized) {
        final val = dotenv.env[key];
        if (val != null && val.trim().isNotEmpty) {
          return val.trim();
        }
      }
    } catch (_) {}
    return fallback;
  }

  // ==========================================
  // ADMOB IDs (Loaded from .env with Test ID Fallbacks)
  // ==========================================

  // App IDs (Configured in AndroidManifest.xml and Info.plist)
  static String get androidAppId =>
      _getEnv('ADMOB_ANDROID_APP_ID', 'ca-app-pub-3940256099942544~3347511713');
  static String get iosAppId =>
      _getEnv('ADMOB_IOS_APP_ID', 'ca-app-pub-3940256099942544~1458002511');

  // Banner Unit IDs
  static String get androidBannerId =>
      _getEnv('ADMOB_ANDROID_BANNER_ID', 'ca-app-pub-3940256099942544/6300978111');
  static String get iosBannerId =>
      _getEnv('ADMOB_IOS_BANNER_ID', 'ca-app-pub-3940256099942544/2934735716');

  // Interstitial Unit IDs
  static String get androidInterstitialId =>
      _getEnv('ADMOB_ANDROID_INTERSTITIAL_ID', 'ca-app-pub-3940256099942544/1033173712');
  static String get iosInterstitialId =>
      _getEnv('ADMOB_IOS_INTERSTITIAL_ID', 'ca-app-pub-3940256099942544/4411468910');

  // Rewarded Video Unit IDs
  static String get androidRewardedId =>
      _getEnv('ADMOB_ANDROID_REWARDED_ID', 'ca-app-pub-3940256099942544/5224354917');
  static String get iosRewardedId =>
      _getEnv('ADMOB_IOS_REWARDED_ID', 'ca-app-pub-3940256099942544/1712485313');

  // Rewarded Interstitial Unit IDs
  static String get androidRewardedInterstitialId =>
      _getEnv('ADMOB_ANDROID_REWARDED_INTERSTITIAL_ID', 'ca-app-pub-3940256099942544/5354046379');
  static String get iosRewardedInterstitialId =>
      _getEnv('ADMOB_IOS_REWARDED_INTERSTITIAL_ID', 'ca-app-pub-3940256099942544/6978759866');

  // Native Advanced Unit IDs
  static String get androidNativeId =>
      _getEnv('ADMOB_ANDROID_NATIVE_ID', 'ca-app-pub-3940256099942544/2247696110');
  static String get iosNativeId =>
      _getEnv('ADMOB_IOS_NATIVE_ID', 'ca-app-pub-3940256099942544/3986624511');

  // App Open Unit IDs
  static String get androidAppOpenId =>
      _getEnv('ADMOB_ANDROID_APP_OPEN_ID', 'ca-app-pub-3940256099942544/9257395921');
  static String get iosAppOpenId =>
      _getEnv('ADMOB_IOS_APP_OPEN_ID', 'ca-app-pub-3940256099942544/5575463023');

  // ==========================================
  // Platform-Aware Ad Unit ID Getters
  // ==========================================

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) return androidBannerId;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosBannerId;
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) return androidInterstitialId;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosInterstitialId;
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) return androidRewardedId;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosRewardedId;
    return '';
  }

  static String get rewardedInterstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidRewardedInterstitialId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosRewardedInterstitialId;
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) return androidNativeId;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosNativeId;
    return '';
  }

  static String get appOpenAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) return androidAppOpenId;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosAppOpenId;
    return '';
  }

  // ==========================================
  // Initialization
  // ==========================================

  /// Initializes the Google Mobile Ads SDK on supported platforms.
  Future<void> initialize() async {
    if (!isMobilePlatform) {
      debugPrint('[AdService] Mobile ads not supported on current platform.');
      return;
    }

    try {
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] MobileAds initialized successfully: ${status.adapterStatuses}');

      // Preload interstitial and rewarded ads for instant availability
      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Error initializing MobileAds: $e');
    }
  }

  // ==========================================
  // Banner Ad Creator
  // ==========================================

  /// Creates and loads a BannerAd with test ID.
  BannerAd? createBannerAd({
    required Function(Ad ad) onAdLoaded,
    Function(Ad ad, LoadAdError error)? onAdFailedToLoad,
    AdSize size = AdSize.banner,
  }) {
    if (!isMobilePlatform) return null;

    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner ad failed to load: $error');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }

  // ==========================================
  // Interstitial Ad Management
  // ==========================================

  /// Preloads an Interstitial Ad.
  void loadInterstitialAd() {
    if (!isMobilePlatform || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial Ad loaded.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Interstitial Ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('[AdService] Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  /// Displays the preloaded Interstitial Ad if available, then calls [onDismissed].
  void showInterstitialAd({BuildContext? context, VoidCallback? onDismissed}) {
    if (isMobilePlatform && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          loadInterstitialAd(); // Reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      return;
    }

    // On Web / Chrome / Desktop or when ad not loaded, show AdMob Test Ad overlay
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      AdMobTestAdOverlay.show(
        ctx,
        type: TestAdType.interstitial,
        onDismissed: onDismissed,
      );
      if (isMobilePlatform) loadInterstitialAd();
    } else {
      onDismissed?.call();
      if (isMobilePlatform) loadInterstitialAd();
    }
  }

  // ==========================================
  // Rewarded Ad Management
  // ==========================================

  /// Preloads a Rewarded Ad.
  void loadRewardedAd() {
    if (!isMobilePlatform || _isRewardedLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdService] Rewarded Ad loaded.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Rewarded Ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          debugPrint('[AdService] Rewarded Ad failed to load: $error');
        },
      ),
    );
  }

  /// Shows the Rewarded Ad and executes [onUserEarnedReward] when reward is granted.
  void showRewardedAd({
    BuildContext? context,
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailedToShow,
  }) {
    if (isMobilePlatform && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          onDismissed?.call();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          onFailedToShow?.call();
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
      return;
    }

    // On Web / Chrome / Desktop or when native ad not loaded, show AdMob Test Ad overlay
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      AdMobTestAdOverlay.show(
        ctx,
        type: TestAdType.rewarded,
        onUserEarnedReward: () {
          onUserEarnedReward(RewardItem(50, 'coins'));
        },
        onDismissed: onDismissed,
      );
      if (isMobilePlatform) loadRewardedAd();
    } else {
      if (isMobilePlatform) loadRewardedAd();
      onFailedToShow?.call();
    }
  }

  /// Clean up cached ads when no longer needed
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
