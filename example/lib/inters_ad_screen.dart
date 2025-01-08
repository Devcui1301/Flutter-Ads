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
              MexaAds.instance.showInterAd(
                onAdDisplay: () {
                  log('Test Inter Ad: On inters ad display callback');
                },
                onAdFailedToShow: () {
                  log('Test Inter Ad: On inters ad failed to show callback');
                },
                onAdDismissedFullScreenContent: () {
                  log('Test Inter Ad: On inters ad dismissed callback');
                },
                onAdClicked: () {
                  log('Test Inter Ad: On inters ad clicked callback');
                },
                placement: 'inter_1',
                context: context,
              );
            },
            label: 'Show Interstitial Ad',
          ),
        ],
      ),
    );
  }
}
