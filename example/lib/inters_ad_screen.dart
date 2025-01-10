import 'dart:developer';

import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads_example/button.dart';
import 'package:flutter/material.dart';

class IntersAdScreen extends StatelessWidget {
  const IntersAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            onPressed: () {
              MexaAds.instance.loadInterAd(
                placement: 'inter_1',
                onAdLoaded: () {
                  log("Test Inter Ad: loaded");
                },
                onAdFailToLoad: () {
                  log("Test Inter Ad: load fail");
                },
              );
            },
            label: 'Load Interstitial Ad',
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            onPressed: () {
              MexaAds.instance.loadAndShowInterAd(
                context: context,
                placement: "inter_1",
                forceShow: false,
                onAdLoaded: () {
                  log("Inter Ad: onAdLoaded");
                },
                onAdFailToLoad: () {
                  log("Inter Ad: onAdFailToLoad");
                },
                onAdClicked: () {
                  log("Inter Ad: onAdClicked");
                },
                onAdDisplay: () {
                  log("Inter Ad: onAdDisplay");
                },
                onAdDismissedFullScreenContent: () {
                  log("Inter Ad: onAdDismissedFullScreenContent");
                },
                onAdFailedToShow: () {
                  log("Inter Ad: onAdFailedToShow");
                },
                showLoading: true,
                reloadAfterShow: true,
              );
            },
            label: 'Show Interstitial Ad',
          ),
        ],
      ),
    );
  }
}
