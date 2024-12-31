import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/container_shimmer.dart';
import 'package:mexa_ads/widget/primary_shimmer.dart';

/// This example demonstrates inline ads in a list view, where the ad objects
/// live for the lifetime of this widget.
class NativeAdWidget extends StatefulWidget {
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdClosed;
  final NativeAdSize size;
  final String placement;
  final bool showCloseButton;
  final double? adHeight;
  final Color? adBannerColor;
  final Color? adBackgrounColor;
  final List<Color>? adCTABackgroundColor;
  final Color? adCTATextColor;
  final Color? adTitleTextColor;
  final Color? adBodyTextColor;
  final GradientOrientation? gradientOrientation;

  final Function(
    Ad ad,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
    AdType adType,
  )? onRevenuePaid;

  const NativeAdWidget({
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
    this.adBackgrounColor,
    this.adCTABackgroundColor,
    this.adCTATextColor,
    this.adTitleTextColor,
    this.adBodyTextColor,
    this.gradientOrientation,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
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
    if (error != null || MexaAds.instance.isAdDisable) {
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
            ? widget.adHeight ?? MexaAds.instance.adConstant.nativeAdHeightSmall
            : widget.size == NativeAdSize.medium
                ? widget.adHeight ??
                    MexaAds.instance.adConstant.nativeAdHeightMedium
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
      adUnitId: MexaAds.instance.adConstant.nativeId[widget.placement] ?? '',
      request: const AdRequest(),
      nativeAdOptions: widget.size == NativeAdSize.fullScreen
          ? NativeAdOptions(
              adChoicesPlacement: AdChoicesPlacement.topRightCorner,
            )
          : null,
      customOptions: {
        'bg_color': colorToHexString(
            widget.adBackgrounColor ?? MexaAds.instance.nativeBackgroundColor),
        'cta_bg_color': convertColorsToHex(widget.adCTABackgroundColor ??
            MexaAds.instance.nativeCTABackgroundColor),
        'cta_text_color': colorToHexString(widget.adCTATextColor ??
            MexaAds.instance.nativeCTATitleStyle?.color),
        'title_text_color': colorToHexString(widget.adTitleTextColor ??
            MexaAds.instance.nativeTitleStyle?.color),
        'body_text_color': colorToHexString(
            widget.adBodyTextColor ?? MexaAds.instance.nativeBodyStyle?.color),
        'ad_height': widget.adHeight == null
            ? widget.size == NativeAdSize.small
                ? MexaAds.instance.adConstant.nativeAdHeightSmall.toInt()
                : widget.size == NativeAdSize.medium
                    ? MexaAds.instance.adConstant.nativeAdHeightMedium.toInt()
                    : widget.size == NativeAdSize.square
                        ? (widget.adHeight ?? 120)
                        : -1
            : widget.adHeight!.toInt(),
        'ad_banner_color': colorToHexString(
            widget.adBannerColor ?? MexaAds.instance.primaryColor),
        'gradient_orientation': gradientOrientationToString(
            widget.gradientOrientation ?? GradientOrientation.leftToRight)
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
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = true;
            });
          }
          // Future.delayed(const Duration(milliseconds: 700)).then((value) {
          //   if (mounted) {
          //     setState(() {});
          //   }
          // });
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger('..............$NativeAd failedToLoad: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              this.error = error;
            });
          }
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
          MexaAds.instance.adClickedListener?.call(
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
          MexaAds.instance.adRevenuePaidListener?.call(
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
    if (MexaAds.instance.isAdDisable == false) {
      NativeAdManager manager = MexaAds.instance.nativeAdManager;
      if (manager.isAdLoaded(widget.placement)) {
        _nativeAd = manager.nativeAds[widget.placement];
        if (mounted) {
          setState(() {
            _nativeAdIsLoaded = true;
          });
        }
        // Future.delayed(const Duration(milliseconds: 700)).then((value) {
        //   if (mounted) {
        //     setState(() {});
        //   }
        // });
        manager.nativeAds.remove(widget.placement);
        manager.isAdLoadeds.remove(widget.placement);
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
      height: MexaAds.instance.adConstant.nativeAdHeightSmall,
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
      height: MexaAds.instance.adConstant.nativeAdHeightMedium,
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
