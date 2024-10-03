import 'package:admob_ads/admob_ads.dart';
import 'package:admob_ads/utils.dart';
import 'package:admob_ads_example/app_open_ad_screen.dart';
import 'package:admob_ads_example/banner_anchor_ad_screen.dart';
import 'package:admob_ads_example/collapsible_ad_screen.dart';
import 'package:admob_ads_example/inline_ad_screen.dart';
import 'package:admob_ads_example/inters_ad_screen.dart';
import 'package:admob_ads_example/native_ad_screen.dart';
import 'package:admob_ads_example/rewarded_open_ad_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdmobAds.instance.initialize(
    AdConstant(
        interstitialId: {
          'inter_1': 'ca-app-pub-3940256099942544/1033173712',
          'inter_2': 'ca-app-pub-3940256099942544/1033173712',
        },
        nativeId: {
          'native_1': '/6499/example/native',
          'native_2': '/6499/example/native',
        },
        appOpenId: {
          'app_open_1': 'ca-app-pub-3940256099942544/9257395921',
          'app_open_2': 'ca-app-pub-3940256099942544/9257395921',
        },
        bannerAnchorId: {
          'banner_1': 'ca-app-pub-3940256099942544/6300978111',
          'banner_2': 'ca-app-pub-3940256099942544/6300978111',
        },
        rewardedAdId: {
          'rewarded_1': 'ca-app-pub-3940256099942544/5224354917',
          'rewarded_2': 'ca-app-pub-3940256099942544/5224354917',
        },
        bannerCollapsibleId: {
          "collap_1": "ca-app-pub-3940256099942544/2014213617",
          "collap_2": "ca-app-pub-3940256099942544/2014213617",
        },
        interstitialOffsetTime: const Duration(seconds: 30),
        appOpenOffsetTime: const Duration(seconds: 30),
        timeoutLoadAd: const Duration(seconds: 30)),
  );
  AdmobAds.instance
    ..nativeCallToActionStyle = ButtonStyle(
      backgroundColor: const MaterialStatePropertyAll(Colors.green),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      padding: const MaterialStatePropertyAll(
        EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      ),
      elevation: const MaterialStatePropertyAll(0),
      // textStyle: const MaterialStatePropertyAll(),
      foregroundColor: const MaterialStatePropertyAll(Colors.white),
    )
    ..primaryColor = const Color.fromARGB(255, 229, 14, 164)
    ..nativeDecoration = const BoxDecoration(color: Color(0xff24267E))
    ..nativeTitleStyle = const TextStyle(color: Colors.white)
    ..nativeBodyStyle = const TextStyle(color: Colors.white);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    AdmobAds.instance.preloadNative(
        placement: "native_1", size: NativeAdSize.medium, preloadAdIndex: 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        logger("AppLifecycleState.resumed");
        if (isAppHidden) {
          AdmobAds.instance.showAppOpenAd(
              context: navKey.currentContext ?? context,
              forceShow: true,
              placement: 'app_open_1');
          isAppHidden = false;
        }
        break;
      case AppLifecycleState.paused:
        logger("AppLifecycleState.paused");
        break;
      case AppLifecycleState.hidden:
        logger("AppLifecycleState.hidden");
        isAppHidden = true;
        break;
      case AppLifecycleState.inactive:
        logger("AppLifecycleState.inactive");
        break;
      default:
    }
  }

  bool isAppHidden = false;
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

  late GlobalKey<NavigatorState> navKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    AdmobAds.instance.adConstant.nativeAdHeightMedium =
        MediaQuery.of(context).size.height * 3 / 10;
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                  AdmobAds.instance.openAdInspector();
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
      ),
    );
  }
}
