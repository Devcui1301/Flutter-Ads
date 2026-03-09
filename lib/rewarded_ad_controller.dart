import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';

class RewardedAdController implements AdController {
  final _request = const AdRequest();
  RewardedAd? _rewardedAd;
  Completer<void>? _loadingCompleter;

  late List<String> _adIds;
  int _currentAdIndex = 0;

  late String _adPlacement;
  void setAdPlacement(String placement) {
    _adPlacement = placement;
  }

  void setAdId(List<String> ids) {
    _adIds = ids;
  }

  @override
  Future<bool> loadAd(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) async {
    // Nếu đang load, đợi quá trình load hoàn tất
    if (_loadingCompleter != null && _loadingCompleter?.isCompleted == false) {
      logger("RewardAd Controller: Đang load quảng cáo, chờ hoàn tất");
      try {
        await _loadingCompleter?.future;
        return true; // Load thành công
      } catch (e) {
        onAdFailedToLoad?.call(); // Gọi callback khi thất bại
        return false; // Load thất bại
      }
    }

    // Nếu đã có quảng cáo sẵn sàng, không cần load lại
    if (_rewardedAd != null) {
      logger("RewardAd Controller: Quảng cáo đã sẵn sàng, không cần load lại");
      return true;
    }

    // Khởi tạo quá trình load quảng cáo
    _loadingCompleter = Completer<void>();
    _currentAdIndex = 0; // Bắt đầu từ adId đầu tiên

    Timer timeoutTimer = Timer(MexaAds.instance.adConstant.timeoutLoadAd, () {
      if (_loadingCompleter?.isCompleted == false) {
        _loadingCompleter?.completeError("Ad load timeout");
        _loadingCompleter = null;
        _rewardedAd = null;
        onAdFailedToLoad?.call();
      }
    });

    // Bắt đầu load quảng cáo với danh sách adIds
    _loadAdReward(
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

  void _loadAdReward(
      {VoidCallback? onAdLoaded, VoidCallback? onAdFailedToLoad}) {
    if (_currentAdIndex >= _adIds.length) {
      logger("RewardAd Controller: Tất cả adIds đã thử và không thành công.");
      onAdFailedToLoad?.call();
      return;
    }

    final currentAdId = _adIds[_currentAdIndex];
    logger("RewardAd Controller: Đang load quảng cáo với adId: $currentAdId");

    final String adId =
        kDebugMode ? getTestAdUnitId(AdType.rewarded) : currentAdId;
    RewardedAd.load(
      adUnitId: adId,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd?.setImmersiveMode(true);
          logger("RewardAd Controller: Load thành công với adId: $currentAdId");
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          logger(
              "RewardAd Controller: Load thất bại với adId: $currentAdId. Lỗi: $error");

          if (_currentAdIndex < _adIds.length - 1) {
            _currentAdIndex++; // Thử ID tiếp theo
            _loadAdReward(
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
    VoidCallback? onAdClicked,
    VoidCallback? onAdDisplay,
    VoidCallback? onAdFailedToShow,
    bool reloadAfterShow = true,
    bool recordLastTimeShowAd = true,
  }) async {
    // Nếu quảng cáo chưa được load, return luôn
    if (_rewardedAd == null) {
      onAdFailedToShow?.call();
      return;
    }

    // Hiển thị quảng cáo
    _rewardedAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
        networkName:
            ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
        revenue: valueMicros / 1000000.0,
        adUnitId: ad.adUnitId,
        adType: AdType.rewarded.value,
        placement: _adPlacement,
        country: currencyCode,
      );
      MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
      MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
    };
    _rewardedAd?.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        onAdDismissedFullScreenContent?.call();
        ad.dispose();
        _rewardedAd = null; // Reset sau khi hiển thị
        MexaAds.instance.isShowingFullScreenAd = false;
        if (reloadAfterShow) {
          loadAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onAdFailedToShow?.call();
        ad.dispose();
        _rewardedAd = null;
        MexaAds.instance.isShowingFullScreenAd = false;
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
        MexaAds.instance.adClickedListener?.call(AdClickedParams(
          networkName:
              ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
          adUnitId: ad.adUnitId,
          adType: AdType.rewarded.value,
          placement: _adPlacement,
        ));
      },
      onAdImpression: (ad) {
        onAdDisplay?.call();
        MexaAds.instance.isShowingFullScreenAd = true;
      },
    );

    _rewardedAd?.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {},
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
