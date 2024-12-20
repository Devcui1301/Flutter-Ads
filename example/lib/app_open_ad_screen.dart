import 'dart:developer';

import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads_example/button.dart';
import 'package:flutter/material.dart';

class AppOpenAdScreen extends StatelessWidget {
  const AppOpenAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PrimaryButton(
        onPressed: () {
          MexaAds.instance.showAppOpenAd(
              context: context,
              forceShow: true,
              showLoading: true,
              onAdDismissedFullScreenContent: () {
                log('On AOA dismissed callback');
              },
              onAdClicked: () {
                log('On AOA clicked callback');
              },
              placement: 'app_open_1',
              autoReloadAdAfterShow: false);
        },
        label: 'Show App Open Ad',
      ),
    );
  }
}
