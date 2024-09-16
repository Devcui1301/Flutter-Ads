import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:admob_ads/admob_ads_platform_interface.dart';
import 'package:admob_ads/widget/container_shimmer.dart';
import 'package:admob_ads/widget/primary_shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'admob_ads.dart';

class AdmobCollapsibleAdWidget extends StatefulWidget {
  final bool isCollapsOnce;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdImpression;
  final VoidCallback? onAdOpened;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdClosed;
  final int reloadTimeInSeconds;
  final String placement;
  final bool? isBottom;
  const AdmobCollapsibleAdWidget(
      {super.key,
      this.isCollapsOnce = true,
      this.onAdLoaded,
      this.onAdFailedToLoad,
      this.onAdClicked,
      this.onAdOpened,
      this.onAdClosed,
      this.onAdImpression,
      this.reloadTimeInSeconds = -1,
      required this.placement,
      this.isBottom = true});

  @override
  State<AdmobCollapsibleAdWidget> createState() =>
      _AdmobCollapsibleAdWidgetState();
}

class _AdmobCollapsibleAdWidgetState extends State<AdmobCollapsibleAdWidget> {
  @override
  void initState() {
    super.initState();
    // Dimensions in logical pixels (dp)
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    Size size = view.physicalSize / view.devicePixelRatio;
    double height = size.height;

    bottomAdHeight = height <= 400
        ? 32
        : height <= 720
            ? 50
            : 90;

    if (AdmobAds.instance.isAdDisable == false) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _collapsibleAdCallback.receiveBroadcastStream().timeout(
          const Duration(seconds: 60),
          onTimeout: (sink) {
            sink.close();
          },
        ).listen((event) {
          switch (event['type']) {
            case 'onAdClicked':
              widget.onAdClicked?.call();
              AdmobAds.instance.adClickedListener?.call(
                AdClickedParams(
                    networkName: 'admob',
                    adUnitId: '',
                    adType: AdType.bannerCollapsible.value,
                    placement: widget.placement),
              );
              break;
            case 'onAdClosed':
              widget.onAdClosed?.call();
              break;
            case 'onAdFailedToLoad':
              try {
                setState(() {
                  _isAdFaiedToLoad = true;
                });
              } catch (_) {}
              widget.onAdFailedToLoad?.call();
              break;
            case 'onAdImpression':
              widget.onAdImpression?.call();
              break;
            case 'onAdLoaded':
              try {
                setState(() {
                  _isAdLoaded = true;
                });
              } catch (_) {}
              widget.onAdLoaded?.call();
              break;
            case 'onAdOpened':
              widget.onAdOpened?.call();
              break;
            case 'onPaidEvent':
              double adRevenue = 0;
              try {
                adRevenue = event['value'];
              } catch (_) {}

              AdmobAds.instance.adRevenuePaidListener?.call(
                AdRevenuePaidParams(
                  networkName: 'admob',
                  revenue: adRevenue,
                  adUnitId: AdmobAds.instance.adConstant
                          .bannerCollapsibleId[widget.placement] ??
                      '',
                  adType: AdType.bannerCollapsible.value,
                  placement: widget.placement,
                  country: '',
                ),
              );
              break;
            case 'adHeightChanged':
              try {
                final int adHeight = event['data'];
                if (adHeight != bottomAdHeight) {
                  setState(() {
                    bottomAdHeight = adHeight;
                  });
                }
              } catch (e) {}

              break;
            default:
          }
        });
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isIOS) AdmobAdsPlatform.instance.disposeCollapsibleAdLoad();
    super.dispose();
  }

  late int bottomAdHeight;
  String viewType = 'admob_collapsible_ads';
  final EventChannel _collapsibleAdCallback =
      const EventChannel('collapsible_event_callback');
  bool _isAdFaiedToLoad = false;
  bool _isAdLoaded = false;

  @override
  Widget build(BuildContext context) {
    if (AdmobAds.instance.isAdDisable || _isAdFaiedToLoad) {
      return const SizedBox();
    }

    return Stack(
      children: [
        VisibilityDetector(
          onVisibilityChanged: _onVisibilityChanged,
          key: Key('collapsible-key-${widget.placement}'),
          child: SizedBox(
            height: bottomAdHeight.toDouble(),
            width: double.infinity,
            // color: AppColor.excelColor,
            // alignment: Alignment.bottomCenter,
            child: Platform.isIOS
                ? UiKitView(
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: {
                      'ad_unit_id':
                          AdmobAds.instance.adConstant.bannerCollapsibleId,
                      'isShowCollapseOnce': widget.isCollapsOnce,
                      'reload_time_in_seconds': widget.reloadTimeInSeconds,
                      'placement': widget.placement,
                      'isBottom': widget.isBottom
                    },
                    creationParamsCodec: const StandardMessageCodec(),
                  )
                : PlatformViewLink(
                    viewType: viewType,
                    surfaceFactory: (context, controller) {
                      return AndroidViewSurface(
                        controller: controller as AndroidViewController,
                        gestureRecognizers: const <Factory<
                            OneSequenceGestureRecognizer>>{},
                        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                      );
                    },
                    onCreatePlatformView: (params) {
                      return PlatformViewsService.initSurfaceAndroidView(
                        id: params.id,
                        viewType: viewType,
                        layoutDirection: TextDirection.ltr,
                        creationParams: {
                          'isShowCollapseOnce': widget.isCollapsOnce,
                          'reload_time_in_seconds': widget.reloadTimeInSeconds,
                          'placement': widget.placement,
                          'isBottom': widget.isBottom
                        },
                        creationParamsCodec: const StandardMessageCodec(),
                        onFocus: () {
                          params.onFocusChanged(true);
                        },
                      )
                        ..addOnPlatformViewCreatedListener(
                            params.onPlatformViewCreated)
                        ..create();
                    },
                  ),
          ),
        ),
        if (_isAdLoaded == false)
          Container(
            height: bottomAdHeight.toDouble(),
            color: Colors.grey[50],
            padding: const EdgeInsets.all(8),
            child: PrimaryShimmer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ad',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  ContainerShimmer(
                    height: bottomAdHeight.toDouble() - 16,
                    width: bottomAdHeight.toDouble() - 16,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContainerShimmer(
                          width: 200,
                          height: 20,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        ContainerShimmer(
                          width: 240,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  // Center(
                  //   child: ContainerShimmer(
                  //     height: bottomAdHeight / 2 - 8,
                  //     width: bottomAdHeight.toDouble(),
                  //   ),
                  // ),
                ],
              ),
            ),
          )
      ],
    );
  }

  // final bool _isFirstInitialization = true;
  void _onVisibilityChanged(VisibilityInfo info) {
    // if (_isFirstInitialization) {
    //   _isFirstInitialization = false;
    //   return;
    // }

    if (info.visibleFraction == 0.0) {
      AdmobAdsPlatform.instance.pauseCollapsibleAdLoad(widget.placement);
    } else {
      AdmobAdsPlatform.instance.resumeCollapsibleAdLoad(widget.placement);
    }
  }
}
