import 'dart:developer';

import 'package:admob_ads/admob_ads.dart';
import 'package:admob_ads_example/button.dart';
import 'package:flutter/material.dart';

class AppOpenAdScreen extends StatelessWidget {
  const AppOpenAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PrimaryButton(
        onPressed: () {
          AdmobAds.instance.showAppOpenAd(
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
