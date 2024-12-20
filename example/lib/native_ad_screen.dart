import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/native_ad_widget.dart';
import 'package:mexa_ads/utils.dart';
import 'package:flutter/material.dart';

class NativeAdScreen extends StatefulWidget {
  const NativeAdScreen({super.key});

  @override
  State<NativeAdScreen> createState() => _NativeAdScreenState();
}

class _NativeAdScreenState extends State<NativeAdScreen> {
  NativeAdSize size = NativeAdSize.square;

  @override
  Widget build(BuildContext context) {
    // return NativeAdView(adUnitId: AdmobAds.instance.adConstant.nativeId);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      size = NativeAdSize.medium;
                    });
                  },
                  child: const Text("Medium"),
                ),
                const SizedBox(
                  width: 8,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      size = NativeAdSize.small;
                    });
                  },
                  child: const Text("Small"),
                ),
                const SizedBox(
                  width: 8,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const NativeAdWidget(
                        size: NativeAdSize.fullScreen,
                        placement: 'native_2',
                      ),
                    ));
                  },
                  child: const Text("FullScreen"),
                ),
                const SizedBox(
                  width: 8,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      size = NativeAdSize.square;
                    });
                  },
                  child: const Text("Square"),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
                'Lorem ipsum, placeholder or dummy text used in typesetting and graphic design for previewing layouts. It features scrambled Latin text, which emphasizes the design over content of the layout. It is the standard placeholder text of the printing and publishing industries.'),
            const SizedBox(
              height: 8,
            ),
            NativeAdWidget(
              key: UniqueKey(),
              onAdClicked: () {
                logger('onAdClicked');
              },
              onRevenuePaid:
                  (ad, valueMicros, precision, currencyCode, adType) {
                logger('revenue: $valueMicros');
              },
              size: size,
              placement: 'native_1',
            ),
          ],
        ),
      ),
    );
  }
}
