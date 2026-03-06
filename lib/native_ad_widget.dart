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
  //chỉ nhận các giá trị 12, 16, 20, 24, 248, 30
  final int? borderRadius;

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
      // if (widget.size == NativeAdSize.fullScreen) {
      //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //     Navigator.pop(context);
      //   });
      // }
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
                                : 80,
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
            MexaAds.instance.nativeCTABackgroundColor ??
            [MexaAds.instance.primaryColor]),
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
                              : 'nativeAdFullScreenFactory',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) async {
          logger("Native: Không có Completer, tải và hiển thị quảng cáo");

          logger('.............$NativeAd loaded.');
          error = null;
          // OPTIMIZATION: Removed unnecessary 900ms delay (200ms + 700ms)
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = true;
            });
          }

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

  @override
  void initState() {
    initNativeAd();
    super.initState();
  }

  void initNativeAd() async {
    if (MexaAds.instance.isAdDisable) return;
    NativeAdManager manager = MexaAds.instance.nativeAdManager;

    // Kiểm tra nếu completer tồn tại và chưa hoàn thành
    if (manager.loadingNativeCompleters[widget.placement] != null) {
      Completer<void>? completer =
          manager.loadingNativeCompleters[widget.placement];

      if (completer?.isCompleted == false) {
        logger("Native: Chờ cho việc tải hoàn thành");
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
          logger("Native: Xử lý lỗi khi tải quảng cáo");

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
          print("Error while loading ad: $error");
        });
      } else {
        logger("Native: Nếu đã hoàn thành, cập nhật trạng thái hiển thị ngay");

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

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
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
      color: Colors.white,
      height: adHeight ?? MexaAds.instance.adConstant.nativeAdHeightLayout1,
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
