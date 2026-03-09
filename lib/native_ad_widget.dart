import 'dart:async';
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
  final int? borderRadius;
  final bool showCloseText;
  final TextStyle? closeTextStyle;
  final int? closeButtonDelay; // Time in seconds
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
    this.size = NativeAdSize.layout1,
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
    this.borderRadius,
    this.closeButtonDelay,
    this.showCloseText = false,
    this.closeTextStyle,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  LoadAdError? error;
  bool _isCloseButtonVisible = false;
  Timer? _closeButtonTimer;

  @override
  void initState() {
    initNativeAd();
    super.initState();
    // Initialize visibility based on delay
    if (widget.closeButtonDelay == null || widget.closeButtonDelay == 0) {
      _isCloseButtonVisible = true;
    }
  }

  @override
  void dispose() {
    _closeButtonTimer?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: (widget.size == NativeAdSize.fullScreen ||
              widget.size == NativeAdSize.custom1 ||
              widget.size == NativeAdSize.custom2)
          ? false
          : true,
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    if (error != null || MexaAds.instance.isAdDisable) {
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
        height: widget.size == NativeAdSize.layout1
            ? widget.adHeight ??
                MexaAds.instance.adConstant.nativeAdHeightLayout1
            : widget.size == NativeAdSize.layout2
                ? widget.adHeight ??
                    MexaAds.instance.adConstant.nativeAdHeightLayout2
                : widget.size == NativeAdSize.layout3
                    ? widget.adHeight ??
                        MexaAds.instance.adConstant.nativeAdHeightLayout3
                    : widget.size == NativeAdSize.layout4
                        ? widget.adHeight ??
                            MexaAds.instance.adConstant.nativeAdHeightLayout4
                        : widget.size == NativeAdSize.noMedia
                            ? widget.adHeight ??
                                MexaAds.instance.adConstant
                                    .nativeAdHeightLayoutNoMedia
                            : widget.size == NativeAdSize.noMedia2
                                ? widget.adHeight ??
                                    MexaAds.instance.adConstant
                                        .nativeAdHeightLayoutNoMedia2
                                : (widget.size == NativeAdSize.fullScreen ||
                                        widget.size == NativeAdSize.custom1 ||
                                        widget.size == NativeAdSize.custom2)
                                    ? MediaQuery.of(context).size.height
                                    : 80,
        child: (widget.size == NativeAdSize.fullScreen ||
                widget.size == NativeAdSize.custom1 ||
                widget.size == NativeAdSize.custom2)
            ? Scaffold(
                backgroundColor: widget.adBackgrounColor,
                body: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: AdWidget(ad: _nativeAd!)),
                        if (widget.showCloseText)
                          GestureDetector(
                            onTap: () => widget.onAdFailedToLoad?.call(),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  "Close",
                                  style: widget.closeTextStyle ??
                                      TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                )),
                          )
                      ],
                    ),
                    if (widget.showCloseButton && _isCloseButtonVisible)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical:
                                  MediaQuery.of(context).padding.top + 16),
                          child: GestureDetector(
                            onTap: () => widget.onAdFailedToLoad?.call(),
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
    return _buildShimmer();
  }

  Widget _buildShimmer() {
    return widget.size == NativeAdSize.custom1
        ? FullScreenNativeAdCustom1Shimmer()
        : widget.size == NativeAdSize.custom2
            ? FullScreenNativeAdCustom2Shimmer()
            : widget.size == NativeAdSize.fullScreen
                ? const FullScreenNativeAdShimmer()
                : widget.size == NativeAdSize.layout1
                    ? const NativeLayout1Shimmer()
                    : widget.size == NativeAdSize.layout2
                        ? const NativeLayout2Shimmer()
                        : widget.size == NativeAdSize.layout3
                            ? const NativeLayout3Shimmer()
                            : widget.size == NativeAdSize.layout4
                                ? const NativeLayout4Shimmer()
                                : widget.size == NativeAdSize.noMedia
                                    ? const NoMediaNativeAdShimmer()
                                    : const NoMedia2NativeAdShimmer();
  }

  void _loadAd({int adIndex = 0}) {
    final adIds = MexaAds.instance.adConstant.nativeId[widget.placement] ?? [];
    if (adIndex >= adIds.length) {
      logger('Native Ad: Tất cả adIds đã thử và không thành công.');
      if (mounted) {
        setState(() {
          error = LoadAdError(1, "All ad IDs failed", "",
              const ResponseInfo(responseExtras: {}));
        });
      }
      widget.onAdFailedToLoad?.call();
      return;
    }

    final currentAdId = adIds[adIndex];
    logger('Native Ad: Đang load với adId: $currentAdId (index: $adIndex)');

    _nativeAd = NativeAd(
      adUnitId: currentAdId,
      request: const AdRequest(),
      nativeAdOptions: (widget.size == NativeAdSize.fullScreen ||
              widget.size == NativeAdSize.custom1 ||
              widget.size == NativeAdSize.custom2)
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
            ? widget.size == NativeAdSize.layout1
                ? MexaAds.instance.adConstant.nativeAdHeightLayout1.toInt()
                : widget.size == NativeAdSize.layout2
                    ? MexaAds.instance.adConstant.nativeAdHeightLayout2.toInt()
                    : widget.size == NativeAdSize.layout3
                        ? MexaAds.instance.adConstant.nativeAdHeightLayout3
                            .toInt()
                        : widget.size == NativeAdSize.layout4
                            ? MexaAds.instance.adConstant.nativeAdHeightLayout4
                                .toInt()
                            : widget.size == NativeAdSize.noMedia
                                ? MexaAds.instance.adConstant
                                    .nativeAdHeightLayoutNoMedia
                                    .toInt()
                                : widget.size == NativeAdSize.noMedia2
                                    ? MexaAds.instance.adConstant
                                        .nativeAdHeightLayoutNoMedia2
                                        .toInt()
                                    : -1
            : widget.adHeight!.toInt(),
        'ad_banner_color': colorToHexString(
            widget.adBannerColor ?? MexaAds.instance.primaryColor),
        'gradient_orientation': gradientOrientationToString(
            widget.gradientOrientation ?? GradientOrientation.leftToRight),
        'cta_border_radius': widget.borderRadius ?? 12
      }..removeWhere((key, value) => value is String && value.isEmpty),
      factoryId: widget.size == NativeAdSize.layout1
          ? 'nativeLayout1Factory'
          : widget.size == NativeAdSize.layout2
              ? 'nativeLayout2Factory'
              : widget.size == NativeAdSize.layout3
                  ? 'nativeLayout3Factory'
                  : widget.size == NativeAdSize.layout4
                      ? 'nativeLayout4Factory'
                      : widget.size == NativeAdSize.noMedia
                          ? 'nativeAdNoMediaFactory'
                          : widget.size == NativeAdSize.noMedia2
                              ? 'nativeAdNoMedia2Factory'
                              : widget.size == NativeAdSize.custom1
                                  ? 'nativeAdFullScreenCustom1Factory'
                                  : widget.size == NativeAdSize.custom2
                                      ? 'nativeAdFullScreenCustom2Factory'
                                      : 'nativeAdFullScreenFactory',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) async {
          logger("Native Ad: Load thành công với adId: $currentAdId");

          logger('Native Ad: Loaded');
          error = null;
          // OPTIMIZATION: Removed unnecessary 900ms delay (200ms + 700ms)
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = true;
            });

            if (widget.closeButtonDelay != null &&
                widget.closeButtonDelay! > 0) {
              _closeButtonTimer?.cancel();
              _closeButtonTimer =
                  Timer(Duration(seconds: widget.closeButtonDelay!), () {
                if (mounted) {
                  setState(() {
                    _isCloseButtonVisible = true;
                  });
                }
              });
            } else {
              if (mounted && !_isCloseButtonVisible) {
                setState(() {
                  _isCloseButtonVisible = true;
                });
              }
            }
          }

          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger(
              'Native Ad: Load thất bại với adId: $currentAdId. Lỗi: $error');
          ad.dispose();

          // Try next ad ID
          if (adIndex < adIds.length - 1) {
            _loadAd(adIndex: adIndex + 1);
          } else {
            if (mounted) {
              setState(() {
                this.error = error;
              });
            }
            widget.onAdFailedToLoad?.call();
          }
        },
        onAdOpened: (Ad ad) {
          logger('Native Ad: onAdOpened');
          widget.onAdClicked?.call();
        },
        onAdClosed: (Ad ad) {
          logger('Native Ad: onAdClosed');
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
          logger('Native Ad: onPaidEvent $valueMicros $precision');
          widget.onRevenuePaid?.call(
            ad,
            valueMicros,
            precision,
            currencyCode,
            AdType.native,
          );
          final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
            networkName:
                ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ?? '',
            revenue: valueMicros / 1000000.0,
            adUnitId: ad.adUnitId,
            adType: AdType.native.value,
            placement: widget.placement,
            country: currencyCode,
          );
          MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
          MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
        },
      ),
    )..load();
  }

  void initNativeAd() async {
    if (MexaAds.instance.isAdDisable) return;
    NativeAdManager manager = MexaAds.instance.nativeAdManager;

    // Kiểm tra nếu completer tồn tại và chưa hoàn thành
    if (manager.loadingNativeCompleters[widget.placement] != null) {
      Completer<void>? completer =
          manager.loadingNativeCompleters[widget.placement];

      if (completer?.isCompleted == false) {
        logger("Native Ad: Chờ cho việc tải hoàn thành");
        // Chờ cho việc tải hoàn thành
        completer?.future.then((_) async {
          // OPTIMIZATION: Removed unnecessary delays
          if (mounted) {
            setState(() {
              // Quảng cáo đã tải xong, cập nhật trạng thái hiển thị
              _nativeAdIsLoaded = true;
              _nativeAd = manager.nativeAds[widget.placement];
            });
          }
          manager.nativeAds.remove(widget.placement);
          manager.loadingNativeCompleters.remove(widget.placement);
        }).catchError((error) async {
          // OPTIMIZATION: Removed unnecessary delay
          logger("Native Ad: Xử lý lỗi khi tải quảng cáo");

          // Xử lý lỗi khi tải quảng cáo
          if (mounted) {
            setState(() {
              this.error = LoadAdError(
                  1,
                  "",
                  "",
                  const ResponseInfo(
                    responseExtras: {},
                  ));
            });
          }
          logger("Native Ad: Error while loading ad: $error");
        });
      } else {
        logger(
            "Native Ad: Nếu đã hoàn thành, cập nhật trạng thái hiển thị ngay");

        // OPTIMIZATION: Removed unnecessary delays
        // Nếu đã hoàn thành, cập nhật trạng thái hiển thị ngay
        if (mounted) {
          setState(() {
            _nativeAdIsLoaded = true;
            _nativeAd = manager.nativeAds[widget.placement];
          });
        }
        manager.nativeAds.remove(widget.placement);
        manager.loadingNativeCompleters.remove(widget.placement);
      }
    } else {
      // Nếu không có completer, bắt đầu tải quảng cáo
      _loadAd();
    }
  }
}

class NativeLayout1Shimmer extends StatelessWidget {
  final double? adHeight;
  const NativeLayout1Shimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      color: const Color(0xff24292E),
      height: adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayout1,
      child: const PrimaryShimmer(
        baseColor: Color(0xff454C52),
        highlightColor: Color(0xff676E76),
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
                        height: 20,
                      ),
                      SizedBox(height: 10),
                      ContainerShimmer(
                        width: double.infinity,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(child: ContainerShimmer()),
            SizedBox(
              height: 10,
            ),
            ContainerShimmer(
              width: double.infinity,
              height: 50,
            )
          ],
        ),
      ),
    );
  }
}

class NativeLayout2Shimmer extends StatelessWidget {
  final double? adHeight;
  const NativeLayout2Shimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      width: double.infinity,
      color: Colors.white,
      height: adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayout2,
      child: const PrimaryShimmer(
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ContainerShimmer(
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: ContainerShimmer(
                                height: 25,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ContainerShimmer(
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(flex: 1, child: ContainerShimmer())
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            ContainerShimmer(
              height: 50,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class NativeLayout3Shimmer extends StatelessWidget {
  final double? adHeight;
  const NativeLayout3Shimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      width: double.infinity,
      color: Colors.white,
      height: adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayout3,
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
                        height: 20,
                      ),
                      SizedBox(height: 10),
                      ContainerShimmer(
                        width: double.infinity,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ContainerShimmer(
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: ContainerShimmer(height: 50, width: 100)),
            ),
          ],
        ),
      ),
    );
  }
}

class NativeLayout4Shimmer extends StatelessWidget {
  final double? adHeight;
  const NativeLayout4Shimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      width: double.infinity,
      color: Colors.white,
      height: adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayout4,
      child: const PrimaryShimmer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ContainerShimmer(
                        width: 50,
                        height: 50,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ContainerShimmer(
                          height: 30,
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: ContainerShimmer(),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ContainerShimmer(
                    width: double.infinity,
                    height: 40,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: ContainerShimmer(
                width: double.infinity,
              ),
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
          PrimaryShimmer(
            baseColor: Color.fromARGB(255, 180, 180, 180),
            highlightColor: Color.fromARGB(255, 80, 80, 80),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 12,
                ),
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
              height: 30,
              width: 300,
            ),
          ),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          PrimaryShimmer(
            baseColor: Color.fromARGB(255, 180, 180, 180),
            highlightColor: Color.fromARGB(255, 80, 80, 80),
            child: ContainerShimmer(
              height: 50,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

class NoMediaNativeAdShimmer extends StatelessWidget {
  final double? adHeight;
  const NoMediaNativeAdShimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      height:
          adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayoutNoMedia,
      color: Colors.white,
      child: const PrimaryShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ContainerShimmer(
                      width: 160,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ContainerShimmer(
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ContainerShimmer(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoMedia2NativeAdShimmer extends StatelessWidget {
  final double? adHeight;
  const NoMedia2NativeAdShimmer({
    super.key,
    this.adHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      height:
          adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayoutNoMedia2,
      color: Colors.white,
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
                        height: 20,
                      ),
                      SizedBox(height: 10),
                      ContainerShimmer(
                        width: double.infinity,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            ContainerShimmer(
              width: double.infinity,
              height: 50,
            )
          ],
        ),
      ),
    );
  }
}

class FullScreenNativeAdCustom1Shimmer extends StatelessWidget {
  const FullScreenNativeAdCustom1Shimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PrimaryShimmer(
                  baseColor: const Color(0xff454C52),
                  highlightColor: const Color(0xff676E76),
                  child: ContainerShimmer(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 16,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: PrimaryShimmer(
                baseColor: const Color(0xff454C52),
                highlightColor: const Color(0xff676E76),
                child: Column(
                  children: const [
                    ContainerShimmer(
                      width: 120,
                      height: 24,
                      radius: 30,
                    ),
                    SizedBox(height: 16),
                    ContainerShimmer(
                      width: double.infinity,
                      height: 16,
                      radius: 30,
                    ),
                    SizedBox(height: 8),
                    ContainerShimmer(
                      width: 200,
                      height: 16,
                      radius: 30,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xffEBEF26),
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenNativeAdCustom2Shimmer extends StatelessWidget {
  const FullScreenNativeAdCustom2Shimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PrimaryShimmer(
                baseColor: const Color(0xff454C52),
                highlightColor: const Color(0xff676E76),
                child: ContainerShimmer(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            SizedBox(height: 32),
            PrimaryShimmer(
              baseColor: const Color(0xff454C52),
              highlightColor: const Color(0xff676E76),
              child: Column(
                children: const [
                  ContainerShimmer(
                    width: 180,
                    height: 24,
                    radius: 30,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xffEBEF26),
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
