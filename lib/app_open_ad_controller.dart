import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/widget/aoa_place_holder.dart';

class AppOpenAdController implements AdController {
  final AdRequest _request = const AdRequest();
  AppOpenAd? _appOpenAd;
  Completer<void>? _loadingCompleter;
  // OPTIMIZATION: Removed unused _numLoadAttempts and maxLoadAttempts

  late String _adId;
  late String _adPlacement;

  void setAdId(String id) => _adId = id;

  void setAdPlacement(String placement) => _adPlacement = placement;

  @override
  Future<bool> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    // Nếu đang load, chờ hoàn thành
    if (_loadingCompleter != null && _loadingCompleter?.isCompleted == false) {
      try {
        await _loadingCompleter?.future;
        return true; // Load thành công
      } catch (_) {
        onAdFailedToLoad?.call();
        return false; // Load thất bại
      }
    }

    // Nếu đã có quảng cáo sẵn sàng
    if (_appOpenAd != null) {
      log("Quảng cáo đã sẵn sàng, không cần load lại");
      return true;
    }

    // Bắt đầu load quảng cáo
    _loadingCompleter = Completer<void>();
    Timer timeoutTimer = Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      if (_loadingCompleter?.isCompleted == false) {
        _loadingCompleter?.completeError("Ad load timeout");
        _loadingCompleter = null;
        _appOpenAd = null;
        onAdFailedToLoad?.call();
      }
    });
    // Bắt đầu load quảng cáo
    _loadAdAppOpen(
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
    }
  }

  void _loadAdAppOpen(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    AppOpenAd.load(
      adUnitId: _adId,
      request: _request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAd?.setImmersiveMode(true);
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          // Retry logic removed - will be handled by timeout
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  @override
  Future<void> showAd({
    BuildContext? context,
    VoidCallback? onAdDismissedFullScreenContent,
    VoidCallback? onAdFailedToShow,
    VoidCallback? onAdDisplay,
    VoidCallback? onAdClicked,
    bool reloadAfterShow = true,
    bool recordLastTimeShowAd = true,
  }) async {
    // Nếu quảng cáo chưa được load, return luôn
    if (_appOpenAd == null) {
      onAdFailedToShow?.call();
      return;
    }

    _appOpenAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
        networkName:
            ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
        revenue: valueMicros / 1000000.0,
        adUnitId: ad.adUnitId,
        adType: AdType.appOpen.value,
        placement: _adPlacement,
        country: currencyCode,
      );
      MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
      MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
    };

    _appOpenAd?.fullScreenContentCallback =
        FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        _hideAOAPlaceHolder(context);
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
        _appOpenAd = null;
        if (recordLastTimeShowAd) {
          MexaAds.instance.lastestTimeShowInterstitialAd = DateTime.now();
        }
        if (reloadAfterShow) {
          loadAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onAdFailedToShow?.call();
        ad.dispose();
        _appOpenAd = null;
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
        MexaAds.instance.adClickedListener?.call(AdClickedParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          adUnitId: _adId,
          adType: AdType.appOpen.value,
          placement: _adPlacement,
        ));
      },
      onAdImpression: (ad) {
        _showAOAPlaceHolder(context);

        onAdDisplay?.call();
      },
    );
    _appOpenAd?.show();
  }

  void _showAOAPlaceHolder(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.of(context).push(AOAPlaceHolder());
    }
  }

  void _hideAOAPlaceHolder(BuildContext? context) {
    if (context != null && context.mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
