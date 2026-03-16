import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/aoa_place_holder.dart';

class AppOpenAdController implements AdController {
  final AdRequest _request = const AdRequest();
  AppOpenAd? _appOpenAd;
  Completer<void>? _loadingCompleter;

  late List<String> _adIds;
  int _currentAdIndex = 0;

  late String _adPlacement;

  void setAdId(List<String> ids) => _adIds = ids;

  void setAdPlacement(String placement) => _adPlacement = placement;

  @override
  Future<bool> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    // Nếu đang load, chờ hoàn thành
    if (_loadingCompleter != null && _loadingCompleter?.isCompleted == false) {
      logger("AppOpenAd Controller: Đang load quảng cáo, chờ hoàn tất");
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
      logger("AppOpenAd Controller: Quảng cáo đã sẵn sàng, không cần load lại");
      return true;
    }

    // Bắt đầu load quảng cáo
    _loadingCompleter = Completer<void>();
    _currentAdIndex = 0; // Bắt đầu từ adId đầu tiên

    Timer timeoutTimer = Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      if (_loadingCompleter?.isCompleted == false) {
        _loadingCompleter?.completeError("Ad load timeout");
        _loadingCompleter = null;
        _appOpenAd = null;
        onAdFailedToLoad?.call();
      }
    });

    // Bắt đầu load quảng cáo với danh sách adIds
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
    } finally {
      timeoutTimer.cancel();
    }
  }

  void _loadAdAppOpen(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    if (_currentAdIndex >= _adIds.length) {
      logger("AppOpenAd Controller: Tất cả adIds đã thử và không thành công.");
      onAdFailedToLoad?.call();
      return;
    }

    final currentAdId = _adIds[_currentAdIndex];
    logger("AppOpenAd Controller: Đang load quảng cáo với adId: $currentAdId");

    final String adId =
        kDebugMode ? getTestAdUnitId(AdType.appOpen) : currentAdId;
    AppOpenAd.load(
      adUnitId: adId,
      request: _request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAd?.setImmersiveMode(true);
          logger(
              "AppOpenAd Controller: Load thành công với adId: $currentAdId");
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          logger(
              "AppOpenAd Controller: Load thất bại với adId: $currentAdId. Lỗi: $error");

          if (_currentAdIndex < _adIds.length - 1) {
            _currentAdIndex++; // Thử ID tiếp theo
            _loadAdAppOpen(
                onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
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
      MexaAds.instance.logAppflyerRevenueEvent(adRevenuePaidParams);
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
          MexaAds.instance.lastestTimeShowAOAAd = DateTime.now();
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
          adUnitId: ad.adUnitId,
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
