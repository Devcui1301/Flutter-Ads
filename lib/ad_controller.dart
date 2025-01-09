import 'package:flutter/material.dart';

abstract class AdController {
  Future<bool> loadAd({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  });

  Future<void> showAd({
    required BuildContext context,
    VoidCallback? onAdDismissedFullScreenContent,
    VoidCallback? onAdClicked,
    VoidCallback? onAdDisplay,
    VoidCallback? onAdFailedToShow,
  });

  void dispose();
}
