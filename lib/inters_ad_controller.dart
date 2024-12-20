import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/loading_dialog.dart';

import 'dart:async';

class InterstitialAdController implements AdController {
  final _request = const AdRequest();
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 5;

  late String _adId;
  void setAdId(String id) {
    _adId = id;
  }

  late String _adPlacement;
  void setAdPlacement(String placement) {
    _adPlacement = placement;
  }

  Timer? _loadingTimer; // Biến lưu trữ Timer

  @override
  Future<void> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    try {
      await InterstitialAd.load(
        adUnitId: _adId,
        request: _request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            logger('INTER: onAdLoaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            logger('INTER: onAdFailedToLoad');
            _numInterstitialLoadAttempts++;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              loadAd.call();
            } else {
              onAdFailedToLoad?.call();
              _numInterstitialLoadAttempts = 0;
              logger(
                  'INTERS: Load ad error code ${error.code} -> ${error.message}');
            }
          },
        ),
      );
    } catch (e) {
      logger('load error catched: $e');
      onAdFailedToLoad?.call();
      _numInterstitialLoadAttempts = 0;
    }
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
            MexaAds.instance.lastestShowIntersDateTime
                    .add(MexaAds.instance.adConstant.interstitialOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        MexaAds.instance.isAdDisable) {
      onStartLoading?.call(false);
      return;
    }
    onStartLoading?.call(true);

    // init fullscreen callback object
    final fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        MexaAds.instance.lastestShowIntersDateTime = DateTime.now();
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        _hideLoadingOverlay(context, showLoading);
        _interstitialAd = null;
        ad.dispose();
        onStartLoading?.call(false);
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
        MexaAds.instance.adClickedListener?.call(AdClickedParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          adUnitId: _adId,
          adType: AdType.interstitial.value,
          placement: _adPlacement,
        ));
      },
      onAdImpression: (ad) {
        _hideLoadingOverlay(context, showLoading);
        onAdDisplay?.call();
        if (autoReloadAdAfterShow) {
          loadAd();
        }
      },
    );

    if (_interstitialAd == null) {
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
      logger('Inters ad != null');
      _showLoadingOverlay(
          context, showLoading, onAdFailedToLoad); // Chỉnh sửa ở đây
      _setAdListener(fullScreenContentCallback);
      _showAd();
    }
  }

  void _setAdListener(FullScreenContentCallback<InterstitialAd> callback) {
    _interstitialAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      MexaAds.instance.adRevenuePaidListener?.call(
        AdRevenuePaidParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          revenue: valueMicros / 1000000.0,
          adUnitId: ad.adUnitId,
          adType: AdType.interstitial.value,
          placement: _adPlacement,
          country: currencyCode,
        ),
      );
    };
    _interstitialAd!.fullScreenContentCallback = callback;
  }

  void _showAd({bool isDelayed = true}) {
    if (MexaAds.instance.isShownIntersPending) {
      Future.delayed(
        Duration(milliseconds: isDelayed ? 1500 : 0),
        () {
          _interstitialAd!.show();
          _interstitialAd = null;
        },
      );
    }
  }

  void _showLoadingOverlay(
      BuildContext? context, bool showLoading, VoidCallback? onAdFailedToLoad) {
    logger('INTER: isReady: false -> show loading');
    MexaAds.instance.isShownIntersPending = true;
    _loadingTimer ??= Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      logger(
          'INTER: Loading timeout -> hide loading and call onAdFailedToLoad');
      _hideLoadingOverlay(context, showLoading);
      onAdFailedToLoad?.call();
    });

    if (!showLoading) return;
    if (context != null && context.mounted) {
      Navigator.of(context).push(LoadingOverlay());
    }
  }

  void _hideLoadingOverlay(BuildContext? context, bool showLoading) {
    logger('INTER: isReady: true -> hide loading');
    if (MexaAds.instance.isShownIntersPending) {
      logger('INTER: isReady: true -> hide loading2');
      MexaAds.instance.isShownIntersPending = false;
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
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _loadingTimer?.cancel(); // Cancel the Timer when disposing
  }
}
