import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads/widget/container_shimmer.dart';
import 'package:mexa_ads/widget/primary_shimmer.dart';

/// This example demonstrates inline ads in a list view, where the ad objects
/// live for the lifetime of this widget.
class BannerAnchorAdWidget extends StatefulWidget {
  final AdSize? adSize;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdClosed;
  final String placement;
  const BannerAnchorAdWidget(
      {super.key,
      this.adSize,
      this.onAdLoaded,
      this.onAdFailedToLoad,
      this.onAdClicked,
      this.onAdClosed,
      required this.placement});

  @override
  State<BannerAnchorAdWidget> createState() => _BannerAnchorAdWidgetState();
}

class _BannerAnchorAdWidgetState extends State<BannerAnchorAdWidget> {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;
  late final AnchoredAdaptiveBannerAdSize? size;
  @override
  Widget build(BuildContext context) {
    if (MexaAds.instance.isAdDisable) return const SizedBox();

    if (_bannerAdIsLoaded && _bannerAd != null) {
      return SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!));
    }
    final tmpAdHeight = AdSize.banner.height.toDouble();
    return Container(
      height: tmpAdHeight,
      color: Colors.grey[50],
      padding: const EdgeInsets.all(8),
      child: PrimaryShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContainerShimmer(
              height: tmpAdHeight - 16,
              width: tmpAdHeight - 16,
            ),
            const SizedBox(
              width: 8,
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerShimmer(
                  width: 200,
                  height: 20,
                ),
                SizedBox(
                  height: 4,
                ),
                ContainerShimmer(
                  width: 240,
                  height: 10,
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(
              width: 8,
            ),
            ContainerShimmer(
              height: tmpAdHeight - 16,
              width: tmpAdHeight,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        initBannerAd();
      },
    );
  }

  void initBannerAd() {
    if (MexaAds.instance.isAdDisable) return;
    BannerAdManager manager = MexaAds.instance.bannerAdManager;

    // Check if a preloaded ad exists
    if (manager.loadingBannerCompleters[widget.placement] != null) {
      Completer<void>? completer =
          manager.loadingBannerCompleters[widget.placement];

      if (completer?.isCompleted == false) {
        logger("Banner Ad: Waiting for preload to complete");
        completer?.future.then((_) {
          if (mounted) {
            setState(() {
              _bannerAdIsLoaded = true;
              _bannerAd = manager.bannerAds[widget.placement];
            });
          }
          manager.bannerAds.remove(widget.placement);
          manager.loadingBannerCompleters.remove(widget.placement);
        }).catchError((error) {
          logger("Banner Ad: Preload failed, falling back to _loadAd: $error");
          _loadAd();
        });
      } else {
        logger("Banner Ad: Using preloaded ad");
        if (mounted) {
          setState(() {
            _bannerAdIsLoaded = true;
            _bannerAd = manager.bannerAds[widget.placement];
          });
        }
        manager.bannerAds.remove(widget.placement);
        manager.loadingBannerCompleters.remove(widget.placement);
      }
    } else {
      // No preloaded ad, load directly
      _loadAd();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
  }

  void _loadAd({int adIndex = 0}) async {
    try {
      if (MexaAds.instance.isAdDisable) return;
      final adIds =
          MexaAds.instance.adConstant.bannerAnchorId[widget.placement] ?? [];
      if (adIndex >= adIds.length) {
        logger('Banner Ad: Tất cả adIds đã thử và không thành công.');
        widget.onAdFailedToLoad?.call();
        return;
      }

      final currentAdId = adIds[adIndex];
      logger('Banner Ad: Đang load với adId: $currentAdId (index: $adIndex)');

      size = widget.adSize == null
          ? await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate())
          : null;
      _bannerAd = BannerAd(
        adUnitId: currentAdId,
        size: widget.adSize ?? size!,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            logger('Banner Ad: Load thành công với adId: $currentAdId');
            setState(() {
              _bannerAdIsLoaded = true;
            });
            widget.onAdLoaded?.call();
          },
          onAdClicked: (ad) {
            widget.onAdClicked?.call();
            MexaAds.instance.adClickedListener?.call(AdClickedParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              adUnitId: ad.adUnitId,
              adType: AdType.banner.value,
              placement: widget.placement,
            ));
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            logger(
                'Banner Ad: Load thất bại với adId: $currentAdId. Lỗi: $error');
            ad.dispose();

            // Try next ad ID
            if (adIndex < adIds.length - 1) {
              _loadAd(adIndex: adIndex + 1);
            } else {
              widget.onAdFailedToLoad?.call();
            }
          },
          onAdOpened: (Ad ad) {
            logger('Banner Ad: onAdOpened');
            widget.onAdClicked?.call();
          },
          onAdClosed: (Ad ad) {
            logger('Banner Ad: onAdClosed');
            widget.onAdClosed?.call();
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            final AdRevenuePaidParams adRevenuePaidParams = AdRevenuePaidParams(
              networkName:
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                      '',
              revenue: valueMicros / 1000000.0,
              adUnitId: ad.adUnitId,
              adType: AdType.banner.value,
              placement: widget.placement,
              country: currencyCode,
            );
            MexaAds.instance.logAdjustRevenueEvent(adRevenuePaidParams);
            MexaAds.instance.adRevenuePaidListener?.call(adRevenuePaidParams);
          },
        ),
      );
      _bannerAd?.load();
    } catch (e) {
      logger(e.toString());
    }
  }
}
