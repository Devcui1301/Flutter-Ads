import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/widget/loading_dialog.dart';

class InterstitialAdController implements AdController {
  final AdRequest _request = const AdRequest();
  InterstitialAd? _interstitialAd;
  Completer<void>? _loadingCompleter;
  int _numLoadAttempts = 0;
  static const int maxLoadAttempts = 5;
  bool loadingShowing = false;

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
    // Nếu đã có quảng cáo hoặc đang load, không load lại
    if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
      log("Nếu đã có quảng cáo hoặc đang load, không load lại");
      return _loadingCompleter!.future;
    }

    if (_interstitialAd != null) {
      return Future.value(); // Quảng cáo đã sẵn sàng
    }

    _loadingCompleter = Completer<void>();
    _numLoadAttempts = 0;

    // Bắt đầu load quảng cáo
    _loadAdInternal(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
    return _loadingCompleter!.future;
  }

  void _loadAdInternal(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    Timer timeoutTimer = Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      if (!_loadingCompleter!.isCompleted) {
        _loadingCompleter?.completeError("Ad load timeout");
        _loadingCompleter = null;
        _interstitialAd = null;
        onAdFailedToLoad?.call();
      }
    });
    InterstitialAd.load(
      adUnitId: _adId,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          timeoutTimer.cancel();
          _interstitialAd = ad;
          _numLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
          _loadingCompleter?.complete();
          _loadingCompleter = null;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          timeoutTimer.cancel();
          _numLoadAttempts++;
          _interstitialAd = null;

          if (_numLoadAttempts < maxLoadAttempts) {
            _loadAdInternal(
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad); // Thử lại
          } else {
            _loadingCompleter?.completeError(error);
            _loadingCompleter = null;
            onAdFailedToLoad?.call();
          }
        },
      ),
    );
  }

  @override
  Future<void> showAd(
      {required BuildContext context,
      VoidCallback? onAdDismissedFullScreenContent,
      VoidCallback? onAdClicked,
      VoidCallback? onAdDisplay,
      VoidCallback? onAdFailedToShow,
      bool showLoading = true}) async {
    // Nếu quảng cáo đang được load, chờ hoàn tất
    if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
      try {
        log("Nếu quảng cáo đang được load, chờ hoàn tất");
        _showLoadingOverlay(context, showLoading, onAdFailedToShow);
        await _loadingCompleter!.future; // Chờ quá trình load hoàn thành
        log("Chờ quá trình load hoàn thành");
      } catch (e) {
        onAdFailedToShow?.call();
        return;
      }
    }

    // Nếu quảng cáo chưa được load, bắt đầu load trước
    if (_interstitialAd == null) {
      try {
        log("Nếu quảng cáo chưa được load, bắt đầu load trước");
        if (context.mounted) {
          _showLoadingOverlay(context, showLoading, onAdFailedToShow);
        }
        await loadAd(
          onAdFailedToLoad: () {
            _hideLoadingOverlay(context, showLoading);
            onAdFailedToShow?.call();
          },
        ); // Load quảng cáo
      } catch (e) {
        onAdFailedToShow?.call();
        return;
      }
    }
    if (context.mounted) {
      _showLoadingOverlay(context, showLoading, onAdFailedToShow);
    }
    // Hiển thị quảng cáo nếu đã load xong
    if (_interstitialAd != null) {
      _interstitialAd?.onPaidEvent =
          (ad, valueMicros, precision, currencyCode) {
        final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          revenue: valueMicros / 1000000.0,
          adUnitId: ad.adUnitId,
          adType: AdType.interstitial.value,
          placement: _adPlacement,
          country: currencyCode,
        );
        MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
        MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
      };
      _interstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback<InterstitialAd>(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissedFullScreenContent?.call();
          ad.dispose();
          _interstitialAd = null; // Reset sau khi hiển thị
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _hideLoadingOverlay(context, showLoading);
          onAdFailedToShow?.call();
          ad.dispose();
          _interstitialAd = null;
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
        },
      );

      _interstitialAd!.show();
    } else {
      onAdFailedToShow?.call();
    }
  }

  void _showLoadingOverlay(
      BuildContext? context, bool showLoading, VoidCallback? onAdFailedToLoad) {
    if (loadingShowing) return;
    loadingShowing = true;
    _loadingTimer ??= Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      _hideLoadingOverlay(context, showLoading);
      onAdFailedToLoad?.call();
    });

    if (!showLoading) return;
    if (context != null && context.mounted) {
      Navigator.of(context).push(LoadingOverlay());
    }
  }

  void _hideLoadingOverlay(BuildContext? context, bool showLoading) {
    if (!loadingShowing) return;
    loadingShowing = false;
    _loadingTimer?.cancel(); // Cancel the Timer
    _loadingTimer = null; // Reset Timer
    if (!showLoading) return;
    if (context != null && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
