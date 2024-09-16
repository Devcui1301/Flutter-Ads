import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:admob_ads/ad_controller.dart';
import 'package:admob_ads/app_open_ad_controller.dart';
import 'package:admob_ads/inters_ad_controller.dart';
import 'package:admob_ads/rewarded_ad_controller.dart';
import 'package:admob_ads/utils.dart';

typedef RevenuePaidedListener = Function(AdRevenuePaidParams params)?;
typedef AdClickedListener = Function(AdClickedParams params)?;

class AdmobAds {
  AdmobAds._();
  static final _instance = AdmobAds._();
  static AdmobAds get instance => _instance;

  /// ad constant must be set before calling the function
  late final AdConstant _adConstant;
  AdConstant get adConstant => _adConstant;

  DateTime lastestShowIntersDateTime = DateTime.now();

  DateTime _lastestTimeShowInterstitialAd = DateTime.now();
  DateTime _lastestTimeShowRewardAd = DateTime.now();
  DateTime _lastestTimeShowAOAAd = DateTime.now();
  bool _isFirstShowAOA = true;
  bool _isFirstShowInters = true;
  bool _isFirstShowRewared = true;

  bool isAdDisable = false;
  bool loadAdAfterInitializing = true;
  bool isShownAOAPending = false;
  bool isShownIntersPending = false;
  bool isShownRewardedPending = false;
  Widget? loadingAdWidget;

  // native ad decoration
  ButtonStyle? nativeCallToActionStyle;
  TextStyle? nativeTitleStyle;
  TextStyle? nativeBodyStyle;
  BoxDecoration? nativeDecoration;
  Color primaryColor = Colors.orange;

  late final Map<String, AdController> _intersAdController = {};
  late final Map<String, AdController> _appOpenAdController = {};
  late final Map<String, AdController> _rewardedAdController = {};

  //call AdmobAds.instance.openAdInspector();
  void openAdInspector() {
    MobileAds.instance.initialize();
    MobileAds.instance.openAdInspector((error) {
      // Error will be non-null if ad inspector closed due to an error.
      print("openAdInspector: $error");
    });
  }

  RevenuePaidedListener? adRevenuePaidListener;
  void setAdRevenuePaidedListener(RevenuePaidedListener onAdRevenuePaided) {
    adRevenuePaidListener = onAdRevenuePaided;
  }

  AdClickedListener? adClickedListener;
  void setAdClickedListener(AdClickedListener adClickedListener) {
    this.adClickedListener = adClickedListener;
  }

  void initialize(AdConstant value, {List<String>? preloadPlacements}) {
    _adConstant = value;

    adConstant.interstitialId.forEach((key, value) {
      _intersAdController.putIfAbsent(
        key,
        () => InterstitialAdController()
          ..setAdId(value)
          ..setAdPlacement(key),
      );
    });
    adConstant.appOpenId.forEach((key, value) {
      _appOpenAdController.putIfAbsent(
        key,
        () => AppOpenAdController()
          ..setAdId(value)
          ..setAdPlacement(key),
      );
    });
    adConstant.rewardedAdId.forEach((key, value) {
      _rewardedAdController.putIfAbsent(
        key,
        () => RewardedAdController()
          ..setAdId(value)
          ..setAdPlacement(key),
      );
    });

    if (_adConstant.interstitialId.isNotEmpty) {
      adConstant.interstitialId.forEach((key, value) {
        if (preloadPlacements?.contains(key) ?? false) {
          _intersAdController[key]?.loadAd();
        }
      });
    }
    if (_adConstant.appOpenId.isNotEmpty) {
      adConstant.appOpenId.forEach((key, value) {
        if (preloadPlacements?.contains(key) ?? false) {
          _appOpenAdController[key]?.loadAd();
        }
      });
    }
    if (_adConstant.rewardedAdId.isNotEmpty) {
      adConstant.rewardedAdId.forEach((key, value) {
        if (preloadPlacements?.contains(key) ?? false) {
          _rewardedAdController[key]?.loadAd();
        }
      });
    }
  }

  void showInterstitialAd(
      {required BuildContext context,
      required String? placement,
      Function(bool canShowAd)? onStartLoading,
      Function()? onAdDismissedFullScreenContent,
      VoidCallback? onAdClicked,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdDisplayed,
      VoidCallback? onAdFailToLoad,
      bool forceShow = false,
      bool autoReloadAdAfterShow = true}) {
    placement ??= adConstant.interstitialId.keys.first;
    logger('show with placement: $placement ${_intersAdController[placement]}');
    if (_isFirstShowAOA == false ||
        _isFirstShowInters == false ||
        _isFirstShowRewared == false) {
      logger(
          'inters time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowInterstitialAd.millisecondsSinceEpoch}');
      logger(
          'RV time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowRewardAd.millisecondsSinceEpoch}');
      logger(
          'AOA time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowAOAAd.millisecondsSinceEpoch}');
      if (DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowInterstitialAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowRewardAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowAOAAd.millisecondsSinceEpoch <
              2000) {
        onStartLoading?.call(false);
        return;
      }
    }
    _intersAdController[placement]?.showAd(
        context: context,
        forceShow: forceShow,
        onStartLoading: (canShowAd) => onStartLoading?.call(canShowAd),
        onAdClicked: () => onAdClicked?.call(),
        onAdDismissedFullScreenContent: () {
          _lastestTimeShowInterstitialAd = DateTime.now();
          onAdDismissedFullScreenContent?.call();
          _isFirstShowInters = false;
        },
        onAdLoaded: () => onAdLoaded?.call(),
        onAdFailedToLoad: () => onAdFailToLoad?.call(),
        onAdDisplay: () => onAdDisplayed?.call(),
        autoReloadAdAfterShow: autoReloadAdAfterShow);
  }

  void showAppOpenAd(
      {required BuildContext context,
      required String? placement,
      Function(bool canShowAd)? onStartLoading,
      VoidCallback? onAdDismissedFullScreenContent,
      VoidCallback? onAdClicked,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdDisplayed,
      VoidCallback? onAdFailToLoad,
      bool forceShow = true,
      bool showLoading = true,
      bool autoReloadAdAfterShow = true}) {
    placement ??= adConstant.appOpenId.keys.first;
    logger(
        'show AOA with placement: $placement ${_appOpenAdController[placement]}');

    if (_isFirstShowAOA == false ||
        _isFirstShowInters == false ||
        _isFirstShowRewared == false) {
      logger(
          'inters time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowInterstitialAd.millisecondsSinceEpoch}');
      logger(
          'RV time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowRewardAd.millisecondsSinceEpoch}');
      logger(
          'AOA time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowAOAAd.millisecondsSinceEpoch}');
      if (DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowInterstitialAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowRewardAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowAOAAd.millisecondsSinceEpoch <
              2000) {
        onStartLoading?.call(false);
        return;
      }
    }

    _appOpenAdController[placement]?.showAd(
        context: context,
        forceShow: forceShow,
        onStartLoading: (canShowAd) => onStartLoading?.call(canShowAd),
        onAdClicked: () => onAdClicked?.call(),
        onAdLoaded: () => onAdLoaded?.call(),
        onAdDismissedFullScreenContent: () {
          _lastestTimeShowAOAAd = DateTime.now();
          onAdDismissedFullScreenContent?.call();
          _isFirstShowAOA = false;
        },
        onAdFailedToLoad: () => onAdFailToLoad?.call(),
        onAdDisplay: () => onAdDisplayed?.call(),
        showLoading: showLoading,
        placement: placement,
        autoReloadAdAfterShow: autoReloadAdAfterShow);
  }

  void showRewardedAd(
      {required BuildContext context,
      required String? placement,
      Function(bool canShowAd)? onStartLoading,
      VoidCallback? onAdDismissedFullScreenContent,
      VoidCallback? onAdClicked,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdDisplayed,
      VoidCallback? onAdFailToLoad,
      bool forceShow = true,
      bool autoReloadAdAfterShow = true}) {
    placement ??= adConstant.rewardedAdId.keys.first;
    logger(
        'show with placement: $placement ${_rewardedAdController[placement]}');
    if (_isFirstShowAOA == false ||
        _isFirstShowInters == false ||
        _isFirstShowRewared == false) {
      logger(
          'inters time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowInterstitialAd.millisecondsSinceEpoch}');
      logger(
          'RV time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowRewardAd.millisecondsSinceEpoch}');
      logger(
          'AOA time: ${DateTime.now().millisecondsSinceEpoch - _lastestTimeShowAOAAd.millisecondsSinceEpoch}');
      if (DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowInterstitialAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowRewardAd.millisecondsSinceEpoch <
              2000 ||
          DateTime.now().millisecondsSinceEpoch -
                  _lastestTimeShowAOAAd.millisecondsSinceEpoch <
              2000) {
        onStartLoading?.call(false);
        return;
      }
    }
    _rewardedAdController[placement]?.showAd(
        context: context,
        forceShow: forceShow,
        onStartLoading: (canShowAd) => onStartLoading?.call(canShowAd),
        onAdClicked: () => onAdClicked?.call(),
        onAdLoaded: () => onAdLoaded?.call(),
        onAdDismissedFullScreenContent: () {
          _lastestTimeShowRewardAd = DateTime.now();
          onAdDismissedFullScreenContent?.call();
          _isFirstShowRewared = false;
        },
        onAdFailedToLoad: () => onAdFailToLoad?.call(),
        onAdDisplay: () => onAdDisplayed?.call(),
        placement: placement,
        autoReloadAdAfterShow: autoReloadAdAfterShow);
  }

  void dispose() {
    _intersAdController.forEach((key, value) {
      value.dispose();
    });
    _appOpenAdController.forEach((key, value) {
      value.dispose();
    });
    _rewardedAdController.forEach((key, value) {
      value.dispose();
    });
  }
}

class AdConstant {
  final Map<String, String> interstitialId;

  final Map<String, String> nativeId;
  final Map<String, String> inlineId;
  final Map<String, String> appOpenId;
  final Map<String, String> bannerAnchorId;
  final Map<String, String> bannerCollapsibleId;
  final Map<String, String> rewardedAdId;
  // the offet time after the last ad was showed, default is 30s
  final Duration interstitialOffsetTime;
  final Duration appOpenOffsetTime;
  double nativeAdHeightSmall;
  double nativeAdHeightMedium;

  AdConstant({
    this.bannerAnchorId = const {},
    this.bannerCollapsibleId = const {},
    this.interstitialId = const {},
    this.nativeId = const {},
    this.inlineId = const {},
    this.appOpenId = const {},
    this.rewardedAdId = const {},
    this.interstitialOffsetTime = const Duration(seconds: 30),
    this.appOpenOffsetTime = const Duration(seconds: 30),
    this.nativeAdHeightMedium = 280,
    this.nativeAdHeightSmall = 160,
  });
}

enum NativeAdSize { small, medium, square, fullScreen }

enum AdType {
  banner,
  bannerCollapsible,
  native,
  rewarded,
  interstitial,
  appOpen,
}

extension AdTypeExt on AdType {
  String get value {
    switch (this) {
      case AdType.banner:
        return "Banner";
      case AdType.bannerCollapsible:
        return "BannerCollapsible";
      case AdType.native:
        return "Native";
      case AdType.rewarded:
        return "Rewarded";
      case AdType.interstitial:
        return "Interstitial";
      case AdType.appOpen:
        return "AppOpen";
    }
  }
}

class AdRevenuePaidParams {
  final String mediation;
  final String networkName;
  final double revenue;
  final String adUnitId;
  final String adType;
  final String placement;
  final String country;

  AdRevenuePaidParams({
    this.mediation = 'google_admob',
    required this.networkName,
    required this.revenue,
    required this.adUnitId,
    required this.adType,
    required this.placement,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = HashMap();
    data['networkName'] = networkName;
    data['revenue'] = revenue;
    data['adUnitId'] = adUnitId;
    data['adType'] = adType;
    data['placement'] = placement;
    data['country'] = country;
    return data;
  }
}

class AdClickedParams {
  final String mediation;
  final String networkName;
  final String adUnitId;
  final String adType;
  final String placement;

  AdClickedParams({
    this.mediation = 'google_admob',
    required this.networkName,
    required this.adUnitId,
    required this.adType,
    required this.placement,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = HashMap();
    data['networkName'] = networkName;
    data['adUnitId'] = adUnitId;
    data['adType'] = adType;
    data['placement'] = placement;
    return data;
  }
}
