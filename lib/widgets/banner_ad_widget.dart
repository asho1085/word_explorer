import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Reusable banner ad widget that displays AdMob test banner ad.
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdService.isMobilePlatform) return;

    _bannerAd = AdService.instance.createBannerAd(
      size: widget.adSize,
      onAdLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _isLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        if (!mounted) return;
        setState(() {
          _isLoaded = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdService.isMobilePlatform && _isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // On Web / Chrome / Desktop or while SDK initializes, show authentic AdMob test banner
    return _buildWebTestBanner(context);
  }

  Widget _buildWebTestBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = widget.adSize.width > 0 ? widget.adSize.width.toDouble() : 320.0;
    final height = widget.adSize.height > 0 ? widget.adSize.height.toDouble() : 50.0;

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Test Ad',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google AdMob Banner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Nice job! This is a test banner ad.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF4285F4)),
          ],
        ),
      ),
    );
  }
}
