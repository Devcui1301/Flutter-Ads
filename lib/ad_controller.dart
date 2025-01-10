import 'package:flutter/material.dart';

abstract class AdController {
  Future<bool> loadAd({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  });

  Future<void> showAd({
    BuildContext? context,
    VoidCallback? onAdDismissedFullScreenContent,
    VoidCallback? onAdClicked,
    VoidCallback? onAdDisplay,
    VoidCallback? onAdFailedToShow,
    VoidCallback? onShowInOffsetTime,
    bool reloadAfterShow = true,
    bool forceShow = true,
  });

  void dispose();
}
