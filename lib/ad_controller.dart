import 'package:flutter/material.dart';

abstract class AdController {
  Future<void> loadAd({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  });

  Future<void> showAd(
      {BuildContext? context,
      Function(bool canShowAd)? onStartLoading,
      VoidCallback? onAdDismissedFullScreenContent,
      VoidCallback? onAdDisplay,
      VoidCallback? onAdClicked,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdFailedToLoad,
      String? placement,
      bool forceShow = false,
      bool showLoading = true,
      bool autoReloadAdAfterShow = true});

  void dispose();
}
