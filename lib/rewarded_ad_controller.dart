import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/loading_dialog.dart';

class RewardedAdController implements AdController {
  final _request = const AdRequest();
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;
  // the offet time after the last ad was showed
  DateTime showAdsDateTime = DateTime.now();

  late String _adId;
  void setAdId(String id) {
    _adId = id;
  }

  late String _adPlacement;
  void setAdPlacement(String placement) {
    _adPlacement = placement;
  }

  Timer? _loadingTimer;
  @override
  Future<void> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    await RewardedAd.load(
      adUnitId: _adId,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
          _rewardedAd!.setImmersiveMode(true);
          onAdLoaded?.call();
          logger('REWARDED: onAdLoaded');
        },
        onAdFailedToLoad: (error) {
          _numRewardedLoadAttempts++;
          _rewardedAd = null;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            loadAd.call();
          } else {
            onAdFailedToLoad?.call();
            _numRewardedLoadAttempts = 0;
            logger(
                'REWARDED: Load ad error code ${error.code} -> ${error.message}');
          }
        },
      ),
    );
  }

  @override
  Future<void> showAd(
      {BuildContext? context,
      Function(bool canShowAd)? onStartLoading,
      VoidCallback? onAdDismissedFullScreenContent,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdDisplay,
      VoidCallback? onAdClicked,
      String? placement,
      VoidCallback? onAdFailedToLoad,
      bool forceShow = false,
      bool showLoading = true,
      bool autoReloadAdAfterShow = true}) async {
    if (!forceShow &&
            showAdsDateTime
                    .add(MexaAds.instance.adConstant.interstitialOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        MexaAds.instance.isAdDisable) {
      onStartLoading?.call(false);
      return;
    }

    onStartLoading?.call(true);
// init fullscreen callback object
    final fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        showAdsDateTime = DateTime.now();
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
        if (autoReloadAdAfterShow) {
          loadAd();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _hideLoadingOverlay(context, showLoading);
        _rewardedAd = null;
        ad.dispose();
        onStartLoading?.call(false);
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
        MexaAds.instance.adClickedListener?.call(AdClickedParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          adUnitId: _adId,
          adType: AdType.rewarded.value,
          placement: _adPlacement,
        ));
      },
      onAdImpression: (ad) {
        if (autoReloadAdAfterShow) {
          loadAd();
        }
        _hideLoadingOverlay(context, showLoading);
        onAdDisplay?.call();
      },
    );

    if (_rewardedAd == null) {
      logger('begin load ad');
      _showLoadingOverlay(context, showLoading, onAdFailedToLoad);
      await loadAd(
        onAdLoaded: () {
          onAdLoaded?.call();
          _setAdListener(fullScreenContentCallback);
          _showAd();
        },
        onAdFailedToLoad: () {
          onAdFailedToLoad?.call();
          _hideLoadingOverlay(context, showLoading);
        },
      );
    } else {
      logger('REWARDED ad != null');
      _showLoadingOverlay(context, showLoading, onAdFailedToLoad);
      _setAdListener(fullScreenContentCallback);
      _showAd();
    }
  }

  void _setAdListener(FullScreenContentCallback<RewardedAd> callback) {
    _rewardedAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      MexaAds.instance.adRevenuePaidListener?.call(
        AdRevenuePaidParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          revenue: valueMicros / 1000000.0,
          adUnitId: ad.adUnitId,
          adType: AdType.rewarded.value,
          placement: _adPlacement,
          country: currencyCode,
        ),
      );
    };
    _rewardedAd!.fullScreenContentCallback = callback;
  }

  void _showAd({bool isDelayed = true}) {
    if (MexaAds.instance.isShownRewardedPending) {
      Future.delayed(
        Duration(milliseconds: isDelayed ? 1500 : 0),
        () {
          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {},
          );
          _rewardedAd = null;
        },
      );
    }
  }

  void _showLoadingOverlay(
      BuildContext? context, bool showLoading, VoidCallback? onAdFailedToLoad) {
    logger('REWARD: isReady: false -> show loading');
    MexaAds.instance.isShownRewardedPending = true;
    _loadingTimer ??= Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      logger(
          'REWARD: Loading timeout -> hide loading and call onAdFailedToLoad');
      _hideLoadingOverlay(context, showLoading);
      onAdFailedToLoad?.call();
    });
    if (!showLoading) return;
    if (context != null && context.mounted) {
      Navigator.of(context).push(LoadingOverlay());
    }
  }

  void _hideLoadingOverlay(BuildContext? context, bool showLoading) {
    if (MexaAds.instance.isShownRewardedPending) {
      logger('REWARD: isReady: true -> hide loading');
      MexaAds.instance.isShownRewardedPending = false;
      _loadingTimer?.cancel(); // Cancel the Timer
      _loadingTimer = null; // Reset Timer
      if (!showLoading) return;
      if (context != null && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
