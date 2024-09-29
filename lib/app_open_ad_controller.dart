import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:admob_ads/ad_controller.dart';
import 'package:admob_ads/admob_ads.dart';
import 'package:admob_ads/utils.dart';
import 'package:admob_ads/widget/aoa_place_holder.dart';
import 'package:admob_ads/widget/loading_dialog.dart';
import 'dart:async';

class AppOpenAdController implements AdController {
  final _request = const AdRequest();
  AppOpenAd? _appOpenAd;
  int _numAOALoadAttempts = 0;
  static const int maxFailedLoadAttempts = 5;
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
  Future<void> loadAd({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  }) async {
    await AppOpenAd.load(
      adUnitId: _adId,
      orientation: AppOpenAd.orientationPortrait,
      request: _request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _numAOALoadAttempts = 0;
          _appOpenAd!.setImmersiveMode(true);
          onAdLoaded?.call();
          logger('AOA onAdLoaded');
        },
        onAdFailedToLoad: (error) {
          _numAOALoadAttempts++;
          _appOpenAd = null;
          if (_numAOALoadAttempts < maxFailedLoadAttempts) {
            loadAd(
              onAdLoaded: onAdLoaded,
              onAdFailedToLoad: onAdFailedToLoad,
            );
          } else {
            _numAOALoadAttempts = 0;
            onAdFailedToLoad?.call();
            logger('AOA Load ad error code: ${error.code} -> ${error.message}');
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
                    .add(AdmobAds.instance.adConstant.appOpenOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        AdmobAds.instance.isAdDisable) {
      onStartLoading?.call(false);
      return;
    }
    onStartLoading?.call(true);

    // init fullscreen callback object
    final fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        showAdsDateTime = DateTime.now();
        _hideAOAPlaceHolder(context);
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _hideLoadingOverlay(context, showLoading);
        _appOpenAd = null;
        ad.dispose();
        if (autoReloadAdAfterShow) {
          loadAd();
        }
        onStartLoading?.call(false);
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
        AdmobAds.instance.adClickedListener?.call(AdClickedParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          adUnitId: ad.adUnitId,
          adType: AdType.appOpen.value,
          placement: placement ?? '',
        ));
      },
      onAdImpression: (ad) {
        _hideLoadingOverlay(context, showLoading);
        _showAOAPlaceHolder(context);
        if (autoReloadAdAfterShow) {
          loadAd();
        }
        onAdDisplay?.call();
      },
    );

    if (_appOpenAd == null) {
      _showLoadingOverlay(context, showLoading, onAdFailedToLoad);
      await loadAd(
        onAdLoaded: () {
          onAdLoaded?.call();
          _setAdListener(fullScreenContentCallback);
          _showAd(isShowImmediately: false);
        },
        onAdFailedToLoad: () {
          _hideLoadingOverlay(context, showLoading);
          onAdFailedToLoad?.call();
        },
      );
    } else {
      logger('AOA ad != null');
      _showLoadingOverlay(context, showLoading, onAdFailedToLoad);
      _setAdListener(fullScreenContentCallback);
      _showAd(isShowImmediately: true);
    }
  }

  void _setAdListener(FullScreenContentCallback<AppOpenAd> callback) {
    _appOpenAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      AdmobAds.instance.adRevenuePaidListener?.call(
        AdRevenuePaidParams(
          networkName: 'google_admob',
          revenue: valueMicros / 1000000.0,
          adUnitId: ad.adUnitId,
          adType: AdType.appOpen.value,
          placement: _adPlacement,
          country: currencyCode,
        ),
      );
    };
    _appOpenAd!.fullScreenContentCallback = callback;
  }

  void _showAd({bool isShowImmediately = true}) {
    if (AdmobAds.instance.isShownAOAPending) {
      Future.delayed(
        Duration(milliseconds: isShowImmediately ? 0 : 1500),
        () {
          _appOpenAd!.show();
          _appOpenAd = null;
        },
      );
    }
  }

  void _showLoadingOverlay(
      BuildContext? context, bool showLoading, VoidCallback? onAdFailedToLoad) {
    AdmobAds.instance.isShownAOAPending = true;
    _loadingTimer ??= Timer(AdmobAds.instance.adConstant.timeoutLoadAd, () {
      logger('AOA: Loading timeout -> hide loading and call onAdFailedToLoad');
      _hideLoadingOverlay(context, showLoading);
      onAdFailedToLoad?.call();
    });
    if (!showLoading) return;
    if (context != null && context.mounted) {
      Navigator.of(context).push(LoadingOverlay());
    }
  }

  void _hideLoadingOverlay(BuildContext? context, bool showLoading) {
    if (AdmobAds.instance.isShownAOAPending) {
      AdmobAds.instance.isShownAOAPending = false;
      _loadingTimer?.cancel(); // Cancel the Timer
      _loadingTimer = null; // Reset Timer
      if (!showLoading) return;
      if (context != null && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showAOAPlaceHolder(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.of(context).push(AOAPlaceHolder());
    }
  }

  void _hideAOAPlaceHolder(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
