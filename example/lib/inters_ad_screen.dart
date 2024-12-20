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
              MexaAds.instance.showInterstitialAd(
                showLoading: true,
                // forceShow: true,
                onAdDismissedFullScreenContent: () {
                  log('On inters ad dismissed callback');
                },
                onAdClicked: () {
                  log('On inters ad clicked callback');
                },
                placement: 'inter_1',
                forceShow: true, context: context,
              );
            },
            label: 'Show Interstitial Ad 1',
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            onPressed: () {
              MexaAds.instance.showInterstitialAd(
                // forceShow: true,
                onAdDismissedFullScreenContent: () {
                  log('On inters ad dismissed callback');
                },
                onAdClicked: () {
                  log('On inters ad clicked callback');
                },
                placement: 'inter_2',
                forceShow: true, context: context,
              );
            },
            label: 'Show Interstitial Ad 2',
          ),
        ],
      ),
    );
  }
}
