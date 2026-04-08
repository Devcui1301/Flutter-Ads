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
import 'package:uuid/uuid.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

export 'package:adjust_sdk/adjust.dart';
export 'package:adjust_sdk/adjust_ad_revenue.dart';
export 'package:adjust_sdk/adjust_config.dart';
export 'package:adjust_sdk/adjust_event.dart';
export 'package:appsflyer_sdk/appsflyer_sdk.dart';

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
  AppsflyerSdk? appsflyerSdk;

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
      logger("MexaAds: openAdInspector: $error");
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
      logger("MexaAds: Error: $e");
    }
  }

  void logAppflyerRevenueEvent(AdRevenuePaidParams adRevenuePaidParams) {
    if (appsflyerSdk != null) {
      try {
        final adRevenueData = AdRevenueData(
          monetizationNetwork: adRevenuePaidParams.networkName,
          mediationNetwork: adRevenuePaidParams.mediation,
          currencyIso4217Code: adRevenuePaidParams.country,
          revenue: adRevenuePaidParams.revenue,
          additionalParameters: {
            "af_ad_unit_id": adRevenuePaidParams.adUnitId,
            "af_ad_type": adRevenuePaidParams.adType,
            "af_placement": adRevenuePaidParams.placement,
          },
        );
        appsflyerSdk!.logAdRevenue(adRevenueData);
        // appsflyerSdk!.logEvent("eventPurchase", {
        //   "af_revenue": adRevenuePaidParams.revenue,
        //   "af_currency": adRevenuePaidParams.country,
        //   "af_network_name": adRevenuePaidParams.networkName,
        //   "af_ad_unit_id": adRevenuePaidParams.adUnitId,
        //   "af_ad_type": adRevenuePaidParams.adType,
        //   "af_placement": adRevenuePaidParams.placement,
        // });
      } catch (e) {
        logger("MexaAds: Error Appsflyer logAppflyerRevenueEvent: $e");
      }
    }
  }

  AdClickedListener? adClickedListener;
  void setLogLevel(MexaAdsLogLevel level) {
    setMexaAdsLogLevel(level);
  }

  void setAdClickedListener(AdClickedListener adClickedListener) {
    this.adClickedListener = adClickedListener;
  }

  void initialize({
    required String adjustkey,
    required AdConstant value,
    String appflyerId = "",
    List<String>? preloadPlacements,
  }) {
    if (adjustkey.isNotEmpty) {
      _initAdjust(adjustkey);
    }
    if (appflyerId.isNotEmpty) {
      _initAppsflyer(appflyerId);
    }
    MobileAds.instance.initialize();
    _adConstant = value;
    setMexaAdsLogLevel(_adConstant.logLevel);

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

  void _initAppsflyer(String appflyerId) {
    AppsFlyerOptions appsFlyerOptions = AppsFlyerOptions(
      afDevKey: appflyerId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 50,
      disableAdvertisingIdentifier: false,
      disableCollectASA: false,
    );
    appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
    appsflyerSdk!.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
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
      reloadAfterShow: reloadAfterShow,
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
  BannerAdManager bannerAdManager = BannerAdManager();
  CollapsibleAdManager collapsibleAdManager = CollapsibleAdManager();

  Future<bool> preloadNative({
    required String placement,
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
    final adIds = adConstant.nativeId[placement] ?? [];
    for (var adId in adIds) {
      final result = await nativeAdManager.preloadNative(
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
        return true;
      } else {
        nativeAdManager.loadingNativeCompleters.remove(placement);
        nativeAdManager.nativeAds.remove(placement);
      }
    }
    return false;
  }

  Future<bool> preloadBannerAnchor({
    required String placement,
    int? screenWidth,
    AdSize? adSize,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
    VoidCallback? onAdClicked,
    VoidCallback? onAdClosed,
  }) async {
    if (isAdDisable) return false;
    final adIds = adConstant.bannerAnchorId[placement] ?? [];
    for (var adId in adIds) {
      final result = await bannerAdManager.preloadBanner(
        placement: placement,
        adUnitId: adId,
        screenWidth: screenWidth,
        adSize: adSize,
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdClicked: onAdClicked,
        onAdClosed: onAdClosed,
      );
      if (result) {
        return true;
      } else {
        bannerAdManager.loadingBannerCompleters.remove(placement);
        bannerAdManager.bannerAds.remove(placement);
      }
    }
    return false;
  }

  Future<bool> preloadCollapsible({
    required String placement,
    int? screenWidth,
    bool isBottom = true,
    bool isCollapsOnce = true,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
    VoidCallback? onAdClicked,
    VoidCallback? onAdClosed,
  }) async {
    if (isAdDisable) return false;
    final adIds = adConstant.bannerCollapsibleId[placement] ?? [];
    for (var adId in adIds) {
      final result = await collapsibleAdManager.preloadCollapsible(
        placement: placement,
        adUnitId: adId,
        screenWidth: screenWidth,
        isBottom: isBottom,
        isCollapsOnce: isCollapsOnce,
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdClicked: onAdClicked,
        onAdClosed: onAdClosed,
      );
      if (result) {
        return true;
      } else {
        collapsibleAdManager.loadingCollapsibleCompleters.remove(placement);
        collapsibleAdManager.collapsibleAds.remove(placement);
      }
    }
    return false;
  }
}

class AdConstant {
  final Map<String, List<String>> interstitialId;

  final Map<String, List<String>> nativeId;
  final Map<String, String> inlineId;
  final Map<String, List<String>> appOpenId;
  final Map<String, List<String>> bannerAnchorId;
  final Map<String, List<String>> bannerCollapsibleId;
  final Map<String, List<String>> rewardedAdId;
  // the offet time after the last ad was showed, default is 30s
  final Duration interstitialOffsetTime;
  final Duration appOpenOffsetTime;
  final Duration timeoutLoadAd;
  double nativeAdHeightLayout1;
  double nativeAdHeightLayout2;
  double nativeAdHeightLayout3;
  double nativeAdHeightLayout4;
  double nativeAdHeightLayoutNoMedia;
  final double nativeAdHeightLayoutNoMedia2;
  final String adjustRevenueEventKey;
  final MexaAdsLogLevel logLevel;

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
    this.logLevel = MexaAdsLogLevel.debug,
  });
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
      final String currentAdId =
          kDebugMode ? getTestAdUnitId(AdType.native) : (adUnitId ?? "");
      nativeAds[placement] = NativeAd(
        adUnitId: currentAdId,
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
            logger('Native Ad Manager: $placement loaded.');
            completer.complete(true);
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            logger('Native Ad Manager: $placement failed to load: $error');
            ad.dispose();
            completer.complete(false);
            onAdFailedToLoad?.call();
          },
          onAdClosed: (Ad ad) {
            logger('Native Ad Manager: onAdClosed.');
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
              'Native Ad Manager: onPaidEvent $valueMicros $precision',
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
            MexaAds.instance.logAppflyerRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
          },
        ),
      )..load();

      return await completer.future;
    } catch (e) {
      logger('Native Ad Manager: Error loading $placement: $e');
      return false;
    }
  }
}

class BannerAdManager {
  Map<String, BannerAd?> bannerAds = <String, BannerAd?>{};
  Map<String, Completer<void>?> loadingBannerCompleters =
      <String, Completer<void>?>{};

  BannerAdManager();

  Future<bool> preloadBanner({
    required String placement,
    int? screenWidth,
    String? adUnitId,
    AdSize? adSize,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
    VoidCallback? onAdClicked,
    VoidCallback? onAdClosed,
  }) async {
    if (loadingBannerCompleters[placement]?.isCompleted == false) {
      await loadingBannerCompleters[placement]!.future;
      return false;
    }

    final completer = Completer<bool>();
    loadingBannerCompleters[placement] = completer;

    try {
      AdSize? size;
      if (adSize != null) {
        size = adSize;
      } else if (screenWidth != null) {
        size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            screenWidth);
      }
      size ??= AdSize.banner;

      final String currentAdId =
          kDebugMode ? getTestAdUnitId(AdType.banner) : (adUnitId ?? "");
      bannerAds[placement] = BannerAd(
        adUnitId: currentAdId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            logger('Banner Ad Manager: $placement preloaded.');
            completer.complete(true);
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            logger('Banner Ad Manager: $placement failed to preload: $error');
            ad.dispose();
            completer.complete(false);
            onAdFailedToLoad?.call();
          },
          onAdOpened: (Ad ad) {
            logger('Banner Ad Manager: $placement onAdOpened.');
          },
          onAdClosed: (Ad ad) {
            logger('Banner Ad Manager: $placement onAdClosed.');
            onAdClosed?.call();
          },
          onAdClicked: (ad) {
            onAdClicked?.call();
            MexaAds.instance.adClickedListener?.call(AdClickedParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              adUnitId: ad.adUnitId,
              adType: AdType.banner.value,
              placement: placement,
            ));
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            final adRevenuePaidParams = AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.banner.value,
              placement: placement,
              country: currencyCode,
            );
            MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.logAppflyerRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
          },
        ),
      )..load();

      return await completer.future;
    } catch (e) {
      logger('Banner Ad Manager: Error preloading $placement: $e');
      return false;
    }
  }
}

class CollapsibleAdManager {
  Map<String, BannerAd?> collapsibleAds = <String, BannerAd?>{};
  Map<String, Completer<void>?> loadingCollapsibleCompleters =
      <String, Completer<void>?>{};

  CollapsibleAdManager();

  Future<bool> preloadCollapsible({
    required String placement,
    int? screenWidth,
    String? adUnitId,
    bool isBottom = true,
    bool isCollapsOnce = true,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
    VoidCallback? onAdClicked,
    VoidCallback? onAdClosed,
  }) async {
    if (loadingCollapsibleCompleters[placement]?.isCompleted == false) {
      await loadingCollapsibleCompleters[placement]!.future;
      return false;
    }

    final completer = Completer<bool>();
    loadingCollapsibleCompleters[placement] = completer;

    try {
      AdSize? size;
      if (screenWidth != null) {
        size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            screenWidth);
      }
      size ??= AdSize.banner;

      Map<String, String> extras = {
        "collapsible": isBottom ? "bottom" : "top",
      };
      if (isCollapsOnce) {
        extras["collapsible_request_id"] = const Uuid().v4();
      }
      final adRequest = AdRequest(extras: extras);

      final String currentAdId = kDebugMode
          ? getTestAdUnitId(AdType.bannerCollapsible)
          : (adUnitId ?? "");
      collapsibleAds[placement] = BannerAd(
        adUnitId: currentAdId,
        size: size,
        request: adRequest,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            logger('Collapsible Ad Manager: $placement preloaded.');
            completer.complete(true);
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            logger(
                'Collapsible Ad Manager: $placement failed to preload: $error');
            ad.dispose();
            completer.complete(false);
            onAdFailedToLoad?.call();
          },
          onAdOpened: (Ad ad) {
            logger('Collapsible Ad Manager: $placement onAdOpened.');
          },
          onAdClosed: (Ad ad) {
            logger('Collapsible Ad Manager: $placement onAdClosed.');
            onAdClosed?.call();
          },
          onAdClicked: (ad) {
            onAdClicked?.call();
            MexaAds.instance.adClickedListener?.call(AdClickedParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              adUnitId: ad.adUnitId,
              adType: AdType.bannerCollapsible.value,
              placement: placement,
            ));
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            final adRevenuePaidParams = AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.bannerCollapsible.value,
              placement: placement,
              country: currencyCode,
            );
            MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.logAppflyerRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
          },
        ),
      )..load();

      return await completer.future;
    } catch (e) {
      logger('Collapsible Ad Manager: Error preloading $placement: $e');
      return false;
    }
  }
}
