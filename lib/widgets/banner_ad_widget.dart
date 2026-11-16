import 'package:flutter/material.dart';

/// Reusable banner ad widget.
/// In this release, ads are removed; this renders an empty zero-sized widget.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
