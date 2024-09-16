import 'dart:developer';

import 'package:admob_ads/admob_ads.dart';
import 'package:admob_ads_example/button.dart';
import 'package:flutter/material.dart';

class RewardedAdScreen extends StatelessWidget {
  const RewardedAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PrimaryButton(
        onPressed: () {
          AdmobAds.instance.showRewardedAd(
              context: context,
              forceShow: true,
              onAdDismissedFullScreenContent: () {
                log('On AOA dismissed callback');
              },
              onAdClicked: () {
                log('On AOA clicked callback');
              },
              placement: 'rewarded_1');
        },
        label: 'Show Rewarded Ad',
      ),
    );
  }
}
