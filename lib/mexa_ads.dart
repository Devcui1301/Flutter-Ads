import 'dart:async';
import 'dart:collection';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_ad_revenue.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/ad_controller.dart';
import 'package:mexa_ads/app_open_ad_controller.dart';
import 'package:mexa_ads/inters_ad_controller.dart';
import 'package:mexa_ads/rewarded_ad_controller.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/loading_dialog.dart';

typedef RevenuePaidedListener = Function(AdRevenuePaidParams params)?;
typedef AdClickedListener = Function(AdClickedParams params)?;

class MexaAds {
  MexaAds._();
  static final _instance = MexaAds._();
  static MexaAds get instance => _instance;

  /// ad constant must be set before calling the function
  late final AdConstant _adConstant;
  AdConstant get adConstant => _adConstant;

  bool isAdDisable = false;
  bool loadAdAfterInitializing = true;
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

  DateTime lastestTimeShowInterstitialAd = DateTime.now();
  DateTime lastestTimeShowAOAAd = DateTime.now();

  /// Flag indicating if an Interstitial or Rewarded Ad is currently presenting.
  /// Used to block App Open Ads from showing when the app resumes after closing a full-screen ad.
  bool isShowingFullScreenAd = false;

  //call AdmobAds.instance.openAdInspector();
  void openAdInspector() {
    MobileAds.instance.openAdInspector((error) {
      // Error will be non-null if ad inspector closed due to an error.
      logger("openAdInspector: $error");
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
        adRevenuePaidParams.revenue,
        adRevenuePaidParams.country,
      );
      adRevenue.adRevenueNetwork = adRevenuePaidParams.networkName;
      adRevenue.adRevenuePlacement = adRevenuePaidParams.placement;
      Adjust.trackAdRevenue(adRevenue);

      AdjustEvent adjustRevenueEvent = AdjustEvent(
        _adConstant.adjustRevenueEventKey,
      );
      adjustRevenueEvent.setRevenue(
        adRevenuePaidParams.revenue,
        adRevenuePaidParams.country,
      );
      Adjust.trackEvent(adjustRevenueEvent);
    } catch (e) {
      logger(e.toString());
    }
  }

  AdClickedListener? adClickedListener;
  void setAdClickedListener(AdClickedListener adClickedListener) {
    this.adClickedListener = adClickedListener;
  }

  void initialize({
    required String adjustkey,
    required AdConstant value,
    List<String>? preloadPlacements,
  }) {
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
    AdjustConfig config = AdjustConfig(
      adjustkey,
      kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production,
    );
    Adjust.initSdk(config);
  }

  Future<bool> loadInterAd({
    required String placement,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
  }) async {
    if (isAdDisable) return false;
    return await _intersAdController[placement]?.loadAd(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailToLoad,
        ) ??
        false;
  }

  void showInterAd({
    required String placement,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    Function()? onShowInOffsetTime,
    bool reloadAfterShow = true,
    bool forceShow = true,
    bool recordLastTimeShowAd = true,
  }) {
    if (!forceShow &&
            MexaAds.instance.lastestTimeShowInterstitialAd
                    .add(MexaAds.instance.adConstant.interstitialOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        isAdDisable) {
      onShowInOffsetTime?.call();
      return;
    }
    _intersAdController[placement]?.showAd(
      onAdClicked: onAdClicked,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdDisplay: onAdDisplay,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: reloadAfterShow,
      recordLastTimeShowAd: recordLastTimeShowAd,
    );
  }

  void loadAndShowInterAd({
    required String placement,
    required BuildContext context,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    bool showLoading = true,
    Function()? onShowInOffsetTime,
    bool reloadAfterShow = true,
    bool forceShow = true,
    bool recordLastTimeShowAd = true,
    Route? customLoadingOverlay,
    int? timeout,
  }) async {
    if (!forceShow &&
            MexaAds.instance.lastestTimeShowInterstitialAd
                    .add(MexaAds.instance.adConstant.interstitialOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        isAdDisable) {
      onShowInOffsetTime?.call();
      return;
    }

    if (showLoading && context.mounted) {
      Navigator.of(context).push(customLoadingOverlay ?? LoadingOverlay());
    }

    final stopwatch = Stopwatch()..start();
    bool loadCompleted = false;

    await Future.any([
      loadInterAd(
        placement: placement,
        onAdLoaded: onAdLoaded,
        onAdFailToLoad: onAdFailToLoad,
      ).then((_) => loadCompleted = true),
      Future.delayed(
        Duration(seconds: timeout ?? adConstant.timeoutLoadAd.inSeconds),
      ),
    ]);
    stopwatch.stop();

    // If ad was pre-loaded (returned almost instantly) and loading is shown,
    // delay 2 seconds so user can see the loading overlay
    if (showLoading && loadCompleted && stopwatch.elapsedMilliseconds < 500) {
      await Future.delayed(
        Duration(milliseconds: 2000 - stopwatch.elapsedMilliseconds),
      );
    }

    if (showLoading && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    showInterAd(
      placement: placement,
      onAdClicked: onAdClicked,
      onAdDisplay: onAdDisplay,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: reloadAfterShow,
      forceShow: forceShow,
      onShowInOffsetTime: onShowInOffsetTime,
      recordLastTimeShowAd: recordLastTimeShowAd,
    );
  }

  Future<bool> loadAppOpenAd({
    required String placement,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
  }) async {
    if (isAdDisable) return false;
    return await _appOpenAdController[placement]?.loadAd(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailToLoad,
        ) ??
        false;
  }

  void showAppOpenAd({
    required String placement,
    required BuildContext context,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    bool reloadAfterShow = true,
    Function()? onShowInOffsetTime,
    bool forceShow = true,
    bool recordLastTimeShowAd = true,
  }) {
    if (!forceShow &&
            MexaAds.instance.lastestTimeShowAOAAd
                    .add(MexaAds.instance.adConstant.appOpenOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        isAdDisable) {
      onShowInOffsetTime?.call();
      return;
    }
    _appOpenAdController[placement]?.showAd(
      onAdClicked: onAdClicked,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdDisplay: onAdDisplay,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: true,
      context: context,
      recordLastTimeShowAd: recordLastTimeShowAd,
    );
  }

  void loadAndShowAppOpenAd({
    required String placement,
    required BuildContext context,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    bool showLoading = true,
    bool reloadAfterShow = true,
    bool recordLastTimeShowAd = true,
    Function()? onShowInOffsetTime,
    bool forceShow = true,
    Route? customLoadingOverlay,
    int? timeout,
  }) async {
    if (!forceShow &&
            MexaAds.instance.lastestTimeShowAOAAd
                    .add(MexaAds.instance.adConstant.appOpenOffsetTime)
                    .compareTo(DateTime.now()) >
                0 ||
        isAdDisable) {
      onShowInOffsetTime?.call();
      return;
    }

    if (showLoading && context.mounted) {
      Navigator.of(context).push(customLoadingOverlay ?? LoadingOverlay());
    }

    final stopwatch = Stopwatch()..start();
    bool loadCompleted = false;

    await Future.any([
      loadAppOpenAd(
        placement: placement,
        onAdLoaded: onAdLoaded,
        onAdFailToLoad: onAdFailToLoad,
      ).then((_) => loadCompleted = true),
      Future.delayed(
        Duration(seconds: timeout ?? adConstant.timeoutLoadAd.inSeconds),
      ),
    ]);
    stopwatch.stop();

    // If ad was pre-loaded (returned almost instantly) and loading is shown,
    // delay 2 seconds so user can see the loading overlay
    if (showLoading && loadCompleted && stopwatch.elapsedMilliseconds < 500) {
      await Future.delayed(
        Duration(milliseconds: 2000 - stopwatch.elapsedMilliseconds),
      );
    }

    if (showLoading && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    showAppOpenAd(
      placement: placement,
      onAdClicked: onAdClicked,
      context: context,
      onAdDisplay: onAdDisplay,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: reloadAfterShow,
      recordLastTimeShowAd: recordLastTimeShowAd,
    );
  }

  Future<bool> loadRewardAd({
    required String placement,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
  }) async {
    if (isAdDisable) return false;
    return await _rewardedAdController[placement]?.loadAd(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailToLoad,
        ) ??
        false;
  }

  void showRewardAd({
    required String placement,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    bool reloadAfterShow = true,
  }) {
    if (isAdDisable) return;

    _rewardedAdController[placement]?.showAd(
      onAdClicked: onAdClicked,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdDisplay: onAdDisplay,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: reloadAfterShow,
    );
  }

  void loadAndShowRewardAd({
    required String placement,
    required BuildContext context,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailToLoad,
    Function()? onAdDismissedFullScreenContent,
    Function()? onAdClicked,
    Function()? onAdDisplay,
    Function()? onAdFailedToShow,
    bool showLoading = true,
    bool reloadAfterShow = true,
    Route? customLoadingOverlay,
    int? timeout,
  }) async {
    if (isAdDisable) return;

    if (showLoading && context.mounted) {
      Navigator.of(context).push(customLoadingOverlay ?? LoadingOverlay());
    }

    final stopwatch = Stopwatch()..start();
    bool loadCompleted = false;

    await Future.any([
      loadRewardAd(
        placement: placement,
        onAdLoaded: onAdLoaded,
        onAdFailToLoad: onAdFailToLoad,
      ).then((_) => loadCompleted = true),
      Future.delayed(
        Duration(seconds: timeout ?? adConstant.timeoutLoadAd.inSeconds),
      ),
    ]);
    stopwatch.stop();

    // If ad was pre-loaded (returned almost instantly) and loading is shown,
    // delay 2 seconds so user can see the loading overlay
    if (showLoading && loadCompleted && stopwatch.elapsedMilliseconds < 500) {
      await Future.delayed(
        Duration(milliseconds: 2000 - stopwatch.elapsedMilliseconds),
      );
    }

    if (showLoading && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    showRewardAd(
      placement: placement,
      onAdClicked: onAdClicked,
      onAdDisplay: onAdDisplay,
      onAdDismissedFullScreenContent: onAdDismissedFullScreenContent,
      onAdFailedToShow: onAdFailedToShow,
      reloadAfterShow: reloadAfterShow,
    );
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

  Future<bool> preloadNative({
    required String placement,
    String? adUnitId,
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
    int borderRadius = 12,
    Function(
      Ad ad,
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
      AdType adType,
    )? onRevenuePaid,
  }) async {
    if (isAdDisable) return false;
    final bool result = await nativeAdManager.preloadNative(
      adUnitId: adUnitId,
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
      borderRadius: borderRadius,
    );
    if (!result) {
      nativeAdManager.loadingNativeCompleters.remove(placement);
      nativeAdManager.nativeAds.remove(placement);
    }
    return result;
  }

  Future<void> preloadNativeHighFloor({
    required String placement,
    required List<String> adUnitIds,
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
    int borderRadius = 12,
    Function(
      Ad ad,
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
      AdType adType,
    )? onRevenuePaid,
  }) async {
    for (var adId in adUnitIds) {
      final result = await preloadNative(
        adUnitId: adId,
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
        borderRadius: borderRadius,
      );
      if (result) {
        return;
      } else {
        nativeAdManager.loadingNativeCompleters.remove(placement);
        nativeAdManager.nativeAds.remove(placement);
      }
    }
  }
}

class AdConstant {
  final Map<String, List<String>> interstitialId;

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
  double nativeAdHeightLayoutNoMedia2;
  final String adjustRevenueEventKey;

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
    this.nativeAdHeightLayoutNoMedia = 80,
    this.nativeAdHeightLayoutNoMedia2 = 140,
    this.adjustRevenueEventKey = 'adjustEventKey',
  });
}

enum NativeAdSize {
  layout1,
  layout2,
  layout3,
  layout4,
  fullScreen,
  noMedia,
  noMedia2,
  custom1,
  custom2,
}

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

  // Map<String, bool> isAdLoadeds = <String, bool>{};

  Map<String, Completer<void>?> loadingNativeCompleters =
      <String, Completer<void>?>{};

  NativeAdManager();

  Future<bool> preloadNative({
    required String placement,
    required NativeAdSize size,
    String? adUnitId,
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
    int borderRadius = 12,
    Function(
      Ad ad,
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
      AdType adType,
    )? onRevenuePaid,
  }) async {
    // Kiểm tra nếu đang load
    if (loadingNativeCompleters[placement]?.isCompleted == false) {
      await loadingNativeCompleters[placement]!.future;
      return false;
    }

    // Khởi tạo Completer mới
    final completer = Completer<bool>();
    loadingNativeCompleters[placement] = completer;

    try {
      nativeAds[placement] = NativeAd(
        adUnitId:
            adUnitId ?? MexaAds.instance.adConstant.nativeId[placement] ?? '',
        request: const AdRequest(),
        nativeAdOptions: size == NativeAdSize.fullScreen
            ? NativeAdOptions(
                adChoicesPlacement: AdChoicesPlacement.topRightCorner,
              )
            : null,
        customOptions: {
          'bg_color': colorToHexString(
            adBackgrounColor ?? MexaAds.instance.nativeBackgroundColor,
          ),
          'cta_bg_color': convertColorsToHex(
            adCTABackgroundColor ?? MexaAds.instance.nativeCTABackgroundColor,
          ),
          'cta_text_color': colorToHexString(
            adCTATextColor ?? MexaAds.instance.nativeCTATitleStyle?.color,
          ),
          'title_text_color': colorToHexString(
            adTitleTextColor ?? MexaAds.instance.nativeTitleStyle?.color,
          ),
          'body_text_color': colorToHexString(
            adBodyTextColor ?? MexaAds.instance.nativeBodyStyle?.color,
          ),
          'ad_height': adHeight == null
              ? size == NativeAdSize.layout1
                  ? MexaAds.instance.adConstant.nativeAdHeightLayout1.toInt()
                  : size == NativeAdSize.layout2
                      ? MexaAds.instance.adConstant.nativeAdHeightLayout2
                          .toInt()
                      : size == NativeAdSize.layout3
                          ? MexaAds.instance.adConstant.nativeAdHeightLayout3
                              .toInt()
                          : size == NativeAdSize.layout4
                              ? MexaAds
                                  .instance.adConstant.nativeAdHeightLayout4
                                  .toInt()
                              : size == NativeAdSize.noMedia
                                  ? MexaAds.instance.adConstant
                                      .nativeAdHeightLayoutNoMedia
                                      .toInt()
                                  : size == NativeAdSize.noMedia2
                                      ? MexaAds.instance.adConstant
                                          .nativeAdHeightLayoutNoMedia2
                                      : -1
              : adHeight.toInt(),
          'ad_banner_color': colorToHexString(
            adBannerColor ?? MexaAds.instance.primaryColor,
          ),
          'gradient_orientation': gradientOrientationToString(
            gradientOrientation ?? GradientOrientation.leftToRight,
          ),
          'cta_border_radius': borderRadius,
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
                            : size == NativeAdSize.noMedia2
                                ? 'nativeAdNoMedia2Factory'
                                : size == NativeAdSize.custom1
                                    ? 'nativeAdFullScreenCustom1Factory'
                                    : size == NativeAdSize.custom2
                                        ? 'nativeAdFullScreenCustom2Factory'
                                        : 'nativeAdFullScreenFactory',
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            logger('NativeAd $placement loaded.');
            completer.complete(true);
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            logger('NativeAd $placement failed to load: $error');
            ad.dispose();
            completer.complete(false);
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
              '.............. NativeAd onPaidEvent ${'$valueMicros $precision'}',
            );
            onRevenuePaid?.call(
              ad,
              valueMicros,
              precision,
              currencyCode,
              AdType.native,
            );

            final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.native.value,
              placement: placement,
              country: currencyCode,
            );
            MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
          },
        ),
      )..load();

      return await completer.future;
    } catch (e) {
      logger('Error loading NativeAd $placement: $e');
      return false;
    }
  }
}
