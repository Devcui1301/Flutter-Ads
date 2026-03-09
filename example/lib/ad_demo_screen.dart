import 'package:flutter/material.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads_example/app_open_ad_screen.dart';
import 'package:mexa_ads_example/banner_anchor_ad_screen.dart';
import 'package:mexa_ads_example/collapsible_ad_screen.dart';
import 'package:mexa_ads_example/inline_ad_screen.dart';
import 'package:mexa_ads_example/inters_ad_screen.dart';
import 'package:mexa_ads_example/native_ad_screen.dart';
import 'package:mexa_ads_example/rewarded_open_ad_screen.dart';

class AdDemoScreen extends StatefulWidget {
  const AdDemoScreen({super.key});

  @override
  State<AdDemoScreen> createState() => _AdDemoScreenState();
}

class _AdDemoScreenState extends State<AdDemoScreen> {
  final adsType = const [
    'Native',
    'AOA',
    'Interstitial',
    'Banner Anchor',
    'Inline',
    'Collapsible',
    'Rewarded',
    'Open Ad Inspector'
  ];
  String selectedAd = 'AOA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Admob Admob Plugin example',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        actions: [
          DropdownButton<String>(
            icon: const Icon(
              Icons.change_circle_sharp,
              size: 24,
            ),
            isDense: true,
            value: selectedAd,
            items: adsType
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedAd = value.toString();
              });
              if (value.toString() == "Open Ad Inspector") {
                MexaAds.instance.openAdInspector();
              }
            },
          ),
        ],
      ),
      body: selectedAd == adsType[0]
          ? const NativeAdScreen()
          : selectedAd == adsType[1]
              ? const AppOpenAdScreen()
              : selectedAd == adsType[2]
                  ? const IntersAdScreen()
                  : selectedAd == adsType[3]
                      ? const BannerAnchorAdScreen()
                      : selectedAd == adsType[4]
                          ? const InlineAdScreen()
                          : selectedAd == adsType[5]
                              ? const CollapsibleAdScreen()
                              : const RewardedAdScreen(),
    );
  }
}
