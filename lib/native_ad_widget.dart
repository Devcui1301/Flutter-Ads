import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:admob_ads/admob_ads.dart';
import 'package:admob_ads/utils.dart';
import 'package:admob_ads/widget/container_shimmer.dart';
import 'package:admob_ads/widget/primary_shimmer.dart';

/// This example demonstrates inline ads in a list view, where the ad objects
/// live for the lifetime of this widget.
class AdmobNativeAdWidget extends StatefulWidget {
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdClosed;
  final NativeAdSize size;
  final String placement;
  final Color? adBannerColor;
  final bool showCloseButton;
  final double? adHeight;
  final Function(
    Ad ad,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
    AdType adType,
  )? onRevenuePaid;
  final int? preloadIndex;

  const AdmobNativeAdWidget({
    super.key,
    required this.placement,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.size = NativeAdSize.medium,
    this.onAdClicked,
    this.onAdClosed,
    this.onRevenuePaid,
    this.adBannerColor,
    this.showCloseButton = true,
    this.adHeight,
    this.preloadIndex,
  });

  @override
  State<AdmobNativeAdWidget> createState() => _AdmobNativeAdWidgetState();
}

class _AdmobNativeAdWidgetState extends State<AdmobNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  LoadAdError? error;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.size == NativeAdSize.fullScreen ? false : true,
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    if (error != null || AdmobAds.instance.isAdDisable) {
      if (widget.size == NativeAdSize.fullScreen) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Navigator.pop(context);
        });
      }
      return kDebugMode
          ? Container(
              padding: const EdgeInsets.all(10.0),
              width: double.infinity,
              color: Colors.white,
              child: Text("Debug mode:\nNative Ad error: ${error?.message}"),
            )
          : const SizedBox();
    }
    if (_nativeAdIsLoaded && _nativeAd != null) {
      return SizedBox(
        height: widget.size == NativeAdSize.small
            ? widget.adHeight ??
                AdmobAds.instance.adConstant.nativeAdHeightSmall
            : widget.size == NativeAdSize.medium
                ? widget.adHeight ??
                    AdmobAds.instance.adConstant.nativeAdHeightMedium
                : widget.adHeight ?? 120,
        child: widget.size == NativeAdSize.fullScreen
            ? Scaffold(
                body: Stack(
                  children: [
                    AdWidget(ad: _nativeAd!),
                    if (widget.showCloseButton)
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: MediaQuery.of(context).padding.top + 16),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 75, 75, 75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white,
                              )),
                        ),
                      )
                  ],
                ),
              )
            : AdWidget(
                ad: _nativeAd!,
              ),
      );
    }
    return widget.size == NativeAdSize.fullScreen
        ? const FullScreenNativeAdShimmer()
        : widget.size == NativeAdSize.medium
            ? const MediumNativeAdShimmer()
            : const SmallNativeAdShimmer();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdmobAds.instance.adConstant.nativeId[widget.placement] ?? '',
      request: const AdRequest(),
      nativeAdOptions: widget.size == NativeAdSize.fullScreen
          ? NativeAdOptions(
              adChoicesPlacement: AdChoicesPlacement.topRightCorner,
            )
          : null,
      customOptions: {
        'bg_color': colorToHexString(AdmobAds.instance.nativeDecoration?.color),
        'cta_bg_color': colorToHexString(AdmobAds
            .instance.nativeCallToActionStyle?.backgroundColor
            ?.resolve(Set.of({WidgetState.pressed}))),
        'cta_text_color': colorToHexString(AdmobAds
            .instance.nativeCallToActionStyle?.foregroundColor
            ?.resolve(Set.of({WidgetState.pressed}))),
        'title_text_color':
            colorToHexString(AdmobAds.instance.nativeTitleStyle?.color),
        'body_text_color':
            colorToHexString(AdmobAds.instance.nativeBodyStyle?.color),
        'ad_height': widget.adHeight == null
            ? widget.size == NativeAdSize.small
                ? AdmobAds.instance.adConstant.nativeAdHeightSmall.toInt()
                : widget.size == NativeAdSize.medium
                    ? AdmobAds.instance.adConstant.nativeAdHeightMedium.toInt()
                    : widget.size == NativeAdSize.square
                        ? (widget.adHeight ?? 120)
                        : -1
            : widget.adHeight!.toInt(),
        'ad_banner_color': colorToHexString(AdmobAds.instance.primaryColor),
      }..removeWhere((key, value) => value is String && value.isEmpty),
      factoryId: widget.size == NativeAdSize.small
          ? 'nativeAdSmallFactory'
          : widget.size == NativeAdSize.medium
              ? 'nativeAdMediumFactory'
              : widget.size == NativeAdSize.square
                  ? 'nativeAdSquareFactory'
                  : 'nativeAdFullScreenFactory',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          logger('.............$NativeAd loaded.');
          error = null;
          setState(() {
            _nativeAdIsLoaded = true;
          });
          Future.delayed(const Duration(milliseconds: 700)).then((value) {
            setState(() {});
          });
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger('..............$NativeAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            this.error = error;
          });
          widget.onAdFailedToLoad?.call();
        },
        onAdOpened: (Ad ad) {
          logger('..............$NativeAd onAdOpened.');
          widget.onAdClicked?.call();
        },
        onAdClosed: (Ad ad) {
          logger('..............$NativeAd onAdClosed.');
          widget.onAdClosed?.call();
        },
        onAdClicked: (ad) {
          AdmobAds.instance.adClickedListener?.call(
            AdClickedParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              adUnitId: ad.adUnitId,
              adType: AdType.native.value,
              placement: widget.placement,
            ),
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          logger(
              '.............. NativeAd onPaidEvent ${'$valueMicros $precision'}');
          widget.onRevenuePaid?.call(
            ad,
            valueMicros,
            precision,
            currencyCode,
            AdType.native,
          );
          AdmobAds.instance.adRevenuePaidListener?.call(
            AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.native.value,
              placement: widget.placement,
              country: currencyCode,
            ),
          );
        },
      ),
    )..load();
  }

  @override
  void initState() {
    if (AdmobAds.instance.isAdDisable == false) {
      if (widget.preloadIndex != null) {
        NativeAdManager manager = AdmobAds.instance.nativeAdManager;
        if (manager.isAdLoaded(widget.preloadIndex!)) {
          _nativeAd = manager.nativeAdList[widget.preloadIndex!];
          setState(() {
            _nativeAdIsLoaded = true;
          });
          Future.delayed(const Duration(milliseconds: 700)).then((value) {
            setState(() {});
          });
          AdmobAds.instance.nativeAdManager.nativeAdList[widget.preloadIndex!] =
              null;
          manager.isAdLoadedList[widget.preloadIndex!] = false;
        } else {
          _loadAd();
        }
      } else {
        _loadAd();
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
  }
}

class SmallNativeAdShimmer extends StatelessWidget {
  const SmallNativeAdShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      color: Colors.white,
      height: AdmobAds.instance.adConstant.nativeAdHeightSmall,
      child: const PrimaryShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContainerShimmer(
              width: 100,
              height: 100,
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerShimmer(
                    width: 160,
                    height: 25,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      PrimaryShimmer(
                        child: Row(
                          children: [
                            Text('Ad', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 10),
                            Icon(Icons.star, size: 12),
                            Icon(Icons.star, size: 12),
                            Icon(Icons.star, size: 12),
                            Icon(Icons.star, size: 12),
                            Icon(Icons.star, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ContainerShimmer(
                    width: double.infinity,
                    height: 35,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediumNativeAdShimmer extends StatelessWidget {
  const MediumNativeAdShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      width: double.infinity,
      color: Colors.white,
      height: AdmobAds.instance.adConstant.nativeAdHeightMedium,
      child: const PrimaryShimmer(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerShimmer(
                  width: 50,
                  height: 50,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContainerShimmer(
                        width: 160,
                        height: 25,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          PrimaryShimmer(
                            child: Row(
                              children: [
                                Text('Ad', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 10),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: ContainerShimmer(
                  width: double.infinity,
                ),
              ),
            ),
            ContainerShimmer(
              height: 32,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenNativeAdShimmer extends StatelessWidget {
  const FullScreenNativeAdShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: 16,
          top: MediaQuery.of(context).padding.top,
          left: 8,
          right: 8),
      width: double.infinity,
      color: Colors.black,
      height: 300,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(
            height: 4,
          ),
          PrimaryShimmer(
            baseColor: Color.fromARGB(255, 180, 180, 180),
            highlightColor: Color.fromARGB(255, 80, 80, 80),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryShimmer(
                  child: ContainerShimmer(
                    width: 50,
                    height: 50,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContainerShimmer(
                        width: 160,
                        height: 24,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          PrimaryShimmer(
                            child: Row(
                              children: [
                                Text('Ad', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 10),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                                Icon(Icons.star, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 12,
          ),
          PrimaryShimmer(
            baseColor: Color.fromARGB(255, 180, 180, 180),
            highlightColor: Color.fromARGB(255, 80, 80, 80),
            child: ContainerShimmer(
              height: 20,
              width: 300,
            ),
          ),
          SizedBox(
            height: 12,
          ),
          PrimaryShimmer(
            baseColor: Color.fromARGB(255, 180, 180, 180),
            highlightColor: Color.fromARGB(255, 80, 80, 80),
            child: ContainerShimmer(
              height: 32,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
