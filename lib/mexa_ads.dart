import 'dart:collection';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_ad_revenue.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/app_open_ad_controller.dart';
import 'package:mexa_ads/inters_ad_controller.dart';
import 'package:mexa_ads/rewarded_ad_controller.dart';
import 'package:mexa_ads/utils.dart';

typedef RevenuePaidedListener = Function(AdRevenuePaidParams params)?;
typedef AdClickedListener = Function(AdClickedParams params)?;

class MexaAds {
  MexaAds._();
  static final _instance = MexaAds._();
  static MexaAds get instance => _instance;

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
  Color? nativeBackgroundColor;
  List<Color>? nativeCTABackgroundColor;
  TextStyle? nativeTitleStyle;
  TextStyle? nativeCTATitleStyle;
  TextStyle? nativeBodyStyle;
  Color primaryColor = Colors.orange;

  late final Map<String, AdController> _intersAdController = {};
  late final Map<String, AdController> _appOpenAdController = {};
  late final Map<String, AdController> _rewardedAdController = {};

  //call AdmobAds.instance.openAdInspector();
  void openAdInspector() {
    MobileAds.instance.openAdInspector((error) {
      // Error will be non-null if ad inspector closed due to an error.
      print("openAdInspector: $error");
    });
  }

  RevenuePaidedListener? adRevenuePaidListener;
  void setAdRevenuePaidedListener(RevenuePaidedListener onAdRevenuePaided) {
    adRevenuePaidListener = onAdRevenuePaided;
  }

  void logAdjustRevenueEvent(AdRevenuePaidParams adRevenuePaidParams) {
    try {
      final AdjustAdRevenue adRevenue = AdjustAdRevenue("admob_sdk");
      // Thiết lập doanh thu và loại tiền
      adRevenue.setRevenue(
          adRevenuePaidParams.revenue, adRevenuePaidParams.country);
      adRevenue.adRevenueNetwork = adRevenuePaidParams.networkName;
      adRevenue.adRevenuePlacement = adRevenuePaidParams.placement;

      // Gửi thông tin đến Adjust
      Adjust.trackAdRevenue(adRevenue);
    } catch (e) {
      print(e.toString);
    }
  }

  AdClickedListener? adClickedListener;
  void setAdClickedListener(AdClickedListener adClickedListener) {
    this.adClickedListener = adClickedListener;
  }

  void initialize(
      {required String adjustkey,
      required AdConstant value,
      List<String>? preloadPlacements}) {
    if (adjustkey != "") {
      _initAdjust(adjustkey);
    }
    MobileAds.instance.initialize();
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

  void _initAdjust(String adjustkey) {
    AdjustConfig config = AdjustConfig(adjustkey, AdjustEnvironment.sandbox);
    Adjust.initSdk(config);
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
      bool showLoading = true,
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
        showLoading: showLoading,
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
      bool showLoading = true,
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
        showLoading: showLoading,
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

  NativeAdManager nativeAdManager = NativeAdManager();

  void preloadNative(
      {required String placement,
      required NativeAdSize size,
      double? adHeight,
      final Color? adBannerColor,
      final Color? adBackgrounColor,
      final List<Color>? adCTABackgroundColor,
      final Color? adCTATextColor,
      final Color? adTitleTextColor,
      final Color? adBodyTextColor,
      final GradientOrientation? gradientOrientation,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdFailedToLoad,
      VoidCallback? onAdClicked,
      VoidCallback? onAdClosed,
      Function(
        Ad ad,
        double valueMicros,
        PrecisionType precision,
        String currencyCode,
        AdType adType,
      )? onRevenuePaid}) {
    nativeAdManager.preloadNative(
      placement: placement,
      size: size,
      adHeight: adHeight,
      onAdClosed: onAdClosed,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdLoaded: onAdLoaded,
      onRevenuePaid: onRevenuePaid,
      adBannerColor: adBannerColor,
      adBackgrounColor: adBackgrounColor,
      adCTABackgroundColor: adCTABackgroundColor,
      adCTATextColor: adCTATextColor,
      adTitleTextColor: adTitleTextColor,
      adBodyTextColor: adBodyTextColor,
      gradientOrientation: gradientOrientation,
    );
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
  final Duration timeoutLoadAd;
  double nativeAdHeightLayout1;
  double nativeAdHeightLayout2;
  double nativeAdHeightLayout3;
  double nativeAdHeightLayout4;
  double nativeAdHeightLayoutNoMedia;

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
    this.timeoutLoadAd = const Duration(seconds: 30),
    this.nativeAdHeightLayout1 = 280,
    this.nativeAdHeightLayout2 = 200,
    this.nativeAdHeightLayout3 = 240,
    this.nativeAdHeightLayout4 = 160,
    this.nativeAdHeightLayoutNoMedia = 90,
  });
}

enum NativeAdSize { layout1, layout2, layout3, layout4, fullScreen, noMedia }

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

class NativeAdManager {
  Map<String, NativeAd?> nativeAds = <String, NativeAd?>{};

  Map<String, bool> isAdLoadeds = <String, bool>{};

  NativeAdManager();

  Future<void> preloadNative(
      {required String placement,
      required NativeAdSize size,
      double? adHeight,
      final Color? adBannerColor,
      final Color? adBackgrounColor,
      final List<Color>? adCTABackgroundColor,
      final Color? adCTATextColor,
      final Color? adTitleTextColor,
      final Color? adBodyTextColor,
      final GradientOrientation? gradientOrientation,
      VoidCallback? onAdLoaded,
      VoidCallback? onAdFailedToLoad,
      VoidCallback? onAdClosed,
      Function(
        Ad ad,
        double valueMicros,
        PrecisionType precision,
        String currencyCode,
        AdType adType,
      )? onRevenuePaid}) async {
    nativeAds[placement] = NativeAd(
      adUnitId: MexaAds.instance.adConstant.nativeId[placement] ?? '',
      request: const AdRequest(),
      nativeAdOptions: size == NativeAdSize.fullScreen
          ? NativeAdOptions(
              adChoicesPlacement: AdChoicesPlacement.topRightCorner,
            )
          : null,
      customOptions: {
        'bg_color': colorToHexString(
            adBackgrounColor ?? MexaAds.instance.nativeBackgroundColor),
        'cta_bg_color': convertColorsToHex(
            adCTABackgroundColor ?? MexaAds.instance.nativeCTABackgroundColor),
        'cta_text_color': colorToHexString(
            adCTATextColor ?? MexaAds.instance.nativeCTATitleStyle?.color),
        'title_text_color': colorToHexString(
            adTitleTextColor ?? MexaAds.instance.nativeTitleStyle?.color),
        'body_text_color': colorToHexString(
            adBodyTextColor ?? MexaAds.instance.nativeBodyStyle?.color),
        'ad_height': adHeight == null
            ? size == NativeAdSize.layout1
                ? MexaAds.instance.adConstant.nativeAdHeightLayout1.toInt()
                : size == NativeAdSize.layout2
                    ? MexaAds.instance.adConstant.nativeAdHeightLayout2.toInt()
                    : size == NativeAdSize.layout3
                        ? MexaAds.instance.adConstant.nativeAdHeightLayout3
                            .toInt()
                        : size == NativeAdSize.layout4
                            ? MexaAds.instance.adConstant.nativeAdHeightLayout4
                                .toInt()
                            : size == NativeAdSize.noMedia
                                ? MexaAds.instance.adConstant
                                    .nativeAdHeightLayoutNoMedia
                                    .toInt()
                                : -1
            : adHeight.toInt(),
        'ad_banner_color':
            colorToHexString(adBannerColor ?? MexaAds.instance.primaryColor),
        'gradient_orientation': gradientOrientationToString(
            gradientOrientation ?? GradientOrientation.leftToRight)
      }..removeWhere((key, value) => value is String && value.isEmpty),
      factoryId: size == NativeAdSize.layout1
          ? 'nativeLayout1Factory'
          : size == NativeAdSize.layout2
              ? 'nativeLayout2Factory'
              : size == NativeAdSize.layout3
                  ? 'nativeLayout3Factory'
                  : size == NativeAdSize.layout4
                      ? 'nativeLayout4Factory'
                      : size == NativeAdSize.noMedia
                          ? 'nativeAdNoMediaFactory'
                          : 'nativeAdFullScreenFactory',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          logger('NativeAd $placement loaded.');
          isAdLoadeds[placement] = true;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger('NativeAd $placement failed to load: $error');
          ad.dispose();
          isAdLoadeds[placement] = false;
          onAdFailedToLoad?.call();
        },
        onAdClosed: (Ad ad) {
          logger('..............$NativeAd onAdClosed.');
          onAdClosed?.call();
        },
        onAdClicked: (ad) {
          MexaAds.instance.adClickedListener?.call(
            AdClickedParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              adUnitId: ad.adUnitId,
              adType: AdType.native.value,
              placement: placement,
            ),
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          logger(
              '.............. NativeAd onPaidEvent ${'$valueMicros $precision'}');
          onRevenuePaid?.call(
            ad,
            valueMicros,
            precision,
            currencyCode,
            AdType.native,
          );
          MexaAds.instance.adRevenuePaidListener?.call(
            AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.native.value,
              placement: placement,
              country: currencyCode,
            ),
          );
        },
      ),
    )..load();
  }

  bool isAdLoaded(String placement) {
    return isAdLoadeds[placement] ?? false;
  }
}
