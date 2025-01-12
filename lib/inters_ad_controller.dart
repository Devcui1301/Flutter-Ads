import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';

class InterstitialAdController implements AdController {
  final AdRequest _request = const AdRequest();
  InterstitialAd? _interstitialAd;
  Completer<void>? _loadingCompleter;
  int _numLoadAttempts = 0;
  static const int maxLoadAttempts = 5;

  late String _adId;
  void setAdId(String id) {
    _adId = id;
  }

  late String _adPlacement;
  void setAdPlacement(String placement) {
    _adPlacement = placement;
  }

  @override
  Future<bool> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    // Nếu đang load, đợi quá trình load hoàn tất
    if (_loadingCompleter != null && _loadingCompleter?.isCompleted == false) {
      log("Đang load quảng cáo, chờ hoàn tất");
      try {
        await _loadingCompleter?.future;
        return true; // Load thành công
      } catch (e) {
        onAdFailedToLoad?.call(); // Gọi callback khi thất bại
        return false; // Load thất bại
      }
    }

    // Nếu đã có quảng cáo sẵn sàng, không cần load lại
    if (_interstitialAd != null) {
      log("Quảng cáo đã sẵn sàng, không cần load lại");
      return true;
    }

    // Khởi tạo quá trình load quảng cáo
    _loadingCompleter = Completer<void>();
    _numLoadAttempts = 0;
    Timer timeoutTimer = Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      if (_loadingCompleter?.isCompleted == false) {
        _loadingCompleter?.completeError("Ad load timeout");
        _loadingCompleter = null;
        _interstitialAd = null;
        onAdFailedToLoad?.call();
      }
    });
    // Bắt đầu load quảng cáo
    _loadAdInternal(
      onAdLoaded: () {
        _loadingCompleter?.complete();
        _loadingCompleter = null;
        timeoutTimer.cancel();
        onAdLoaded?.call();
      },
      onAdFailedToLoad: () {
        _loadingCompleter?.completeError("Ad load failed");
        _loadingCompleter = null;
        timeoutTimer.cancel();
        onAdFailedToLoad?.call();
      },
    );
    // Chờ quá trình load hoàn tất
    try {
      await _loadingCompleter?.future;
      return true; // Load thành công
    } catch (e) {
      onAdFailedToLoad?.call(); // Gọi callback khi thất bại
      return false; // Load thất bại
    } finally {
      timeoutTimer.cancel();
    }
  }

  void _loadAdInternal(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    InterstitialAd.load(
      adUnitId: _adId,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _numLoadAttempts = 0;
          _interstitialAd?.setImmersiveMode(true);
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _numLoadAttempts++;
          _interstitialAd = null;

          if (_numLoadAttempts < maxLoadAttempts) {
            _loadAdInternal(
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad); // Thử lại
          } else {
            onAdFailedToLoad?.call();
          }
        },
      ),
    );
  }

  @override
  Future<void> showAd({
    BuildContext? context,
    VoidCallback? onAdDismissedFullScreenContent,
    VoidCallback? onAdClicked,
    VoidCallback? onAdDisplay,
    VoidCallback? onAdFailedToShow,
    bool reloadAfterShow = false,
  }) async {
    // Nếu quảng cáo chưa được load, return luôn
    if (_interstitialAd == null) {
      onAdFailedToShow?.call();
      return;
    }

    // Hiển thị quảng cáo
    _interstitialAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
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
    _interstitialAd?.fullScreenContentCallback =
        FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
        _interstitialAd = null; // Reset sau khi hiển thị
        MexaAds.instance.lastestTimeShowInterstitialAd = DateTime.now();
        if (reloadAfterShow) {
          loadAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
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
        onAdDisplay?.call();
      },
    );

    _interstitialAd?.show();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
