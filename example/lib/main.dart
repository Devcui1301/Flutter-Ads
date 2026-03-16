import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads_example/preload_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MexaAds.instance.initialize(
    adjustkey: "l7niimcenmyo",
    appflyerId: "X6Kiaov2ZqhCk3fc7dGnCd",
    value: AdConstant(
        interstitialId: {
          'inter_1': ['ca-app-pub-3940256099942544/1033173712'],
          'inter_2': ['ca-app-pub-3940256099942544/1033173712'],
        },
        nativeId: {
          'native_1': ['/6499/example/native'],
          'native_2': ['/6499/example/native'],
        },
        appOpenId: {
          'app_open_1': ['ca-app-pub-3940256099942544/9257395921'],
          'app_open_2': ['ca-app-pub-3940256099942544/9257395921'],
        },
        bannerAnchorId: {
          'banner_1': ['ca-app-pub-3940256099942544/6300978111'],
          'banner_2': ['ca-app-pub-3940256099942544/6300978111'],
        },
        rewardedAdId: {
          'rewarded_1': ['ca-app-pub-3940256099942544/5224354917'],
          'rewarded_2': ['ca-app-pub-3940256099942544/5224354917'],
        },
        bannerCollapsibleId: {
          "collap_1": ["ca-app-pub-3940256099942544/2014213617"],
          "collap_2": ["ca-app-pub-3940256099942544/8388050270"],
        },
        interstitialOffsetTime: const Duration(seconds: 30),
        appOpenOffsetTime: const Duration(seconds: 30),
        timeoutLoadAd: const Duration(seconds: 30)),
  );
  MexaAds.instance
    ..primaryColor = const Color.fromARGB(255, 229, 14, 164)
    ..nativeTitleStyle = const TextStyle(color: Colors.black)
    ..nativeBodyStyle = const TextStyle(color: Colors.black);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late GlobalKey<NavigatorState> navKey = GlobalKey();
  bool isAppHidden = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        logger("AppLifecycleState.resumed");
        if (isAppHidden && !MexaAds.instance.isShowingFullScreenAd) {
          MexaAds.instance.loadAndShowAppOpenAd(
              context: navKey.currentContext ?? context,
              placement: 'app_open_1');
        }
        isAppHidden = false;
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

  @override
  Widget build(BuildContext context) {
    MexaAds.instance.adConstant.nativeAdHeightLayout1 =
        MediaQuery.of(context).size.height * 3 / 10;
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      home: const PreloadScreen(),
    );
  }
}
