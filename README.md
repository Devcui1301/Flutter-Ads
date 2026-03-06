# MEXA ADS

A Flutter plugin project for Google Admob and Adjust SDK Integration.

## 1. Installation

Open the `pubspec.yaml` file and add the git dependency to install the plugin:

```yaml
  dependencies:
    mexa_ads:
      git:
        url: <your_url_here>
        ref: develop
```
        
## 2. Android Configuration

### AdMob App ID Setup
Open the `<project_root>/android/app/src/main/AndroidManifest.xml` file and add the Google AdMob Application ID metadata inside the `<application>` tag. We will use a `@string/admob_id` resource variable to support different IDs per build flavor:

```xml
<application>
    <!-- Add this metadata tag -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="@string/admob_id" />
</application>
```

Next, open your `build.gradle` or `build.gradle.kts` in your app module:

1. **Enable MultiDex**: If your `minSdkVersion` is lower than 21, enable `multiDexEnabled true` in `defaultConfig`.
2. **Assign AdMob IDs**: Provide the actual `admob_id` string resource for each build type:

```groovy
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        resValue("string", "admob_id", "ca-app-pub-xxx~xxx") // Your Release App ID
    }
    debug {
        resValue("string", "admob_id", "ca-app-pub-3940256099942544~3347511713") // Test App ID
    }
}
```

## 3. iOS Configuration

### AdMob App ID Setup
Open `<project_root>/ios/Runner/Info.plist` and add the `GADApplicationIdentifier` key with your AdMob App ID.

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxx~xxx</string> <!-- Replace with your actual iOS AdMob App ID -->
<key>SKAdNetworkItems</key>
<array>
  <!-- Provide Google's and other third-party SDK SKAdNetwork IDs here -->
</array>
```

### App Tracking Transparency
To display customized ads, you must ask for tracking permission under iOS 14+. Add the `NSUserTrackingUsageDescription` key in `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

### Adjust SDK specific iOS Frameworks
According to the [Adjust SDK Guidelines](https://dev.adjust.com/en/sdk/flutter/v4/#add-ios-frameworks), `AdSupport`, `AdServices`, `StoreKit`, and `AppTrackingTransparency` frameworks are natively required to track ad revenue metrics successfully. 

> **Great News**: You do NOT need to configure these manually inside your app's Xcode project. The `mexa_ads` plugin automatically links these frameworks directly via its `.podspec` file during `pod install`. So they are handled for you!

---

## 4. Usage / Examples

### 4.1. Initialization 

First, initialize the plugin before accessing any ad functions. This setup configures AdMob IDs for different ad formats and initializes integration with the Adjust SDK environment.

```dart
import 'package:mexa_ads/mexa_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MexaAds.instance.initialize(
    adjustkey: "your_adjust_app_token", 
    value: AdConstant(
      interstitialId: {
        'inter_1': ['ca-app-pub-xxx/yyy', 'ca-app-pub-xxx/zzz'], // Supports waterfall Ad IDs
      },
      nativeId: {
        'native_1': '/6499/example/native',
      },
      appOpenId: {
        'app_open_1': 'ca-app-pub-3940256099942544/9257395921',
      },
      bannerAnchorId: {
        'banner_1': 'ca-app-pub-3940256099942544/6300978111',
      },
      inlineId: {
        'inline_1': 'ca-app-pub-3940256099942544/9214589741',
      },
      rewardedAdId: {
        'rewarded_1': 'ca-app-pub-3940256099942544/5224354917',
      },
      bannerCollapsibleId: {
        'collap_1': 'ca-app-pub-3940256099942544/2014213617',
      },
      interstitialOffsetTime: const Duration(seconds: 30),
      appOpenOffsetTime: const Duration(seconds: 30),
      timeoutLoadAd: const Duration(seconds: 30),
    ),
  );
  
  // Customizing default configurations like Native App CTAs / Colors
  MexaAds.instance
    ..primaryColor = const Color(0xffFFA17A)
    ..nativeTitleStyle = const TextStyle(color: Colors.black);

  runApp(const MyApp());
}
```
+ `interstitialOffsetTime`: Duration enforced between displaying multiple Interstitial Ads.
+ `appOpenOffsetTime`: Duration enforced between displaying multiple App Open Ads.

---

### 4.2. Preloading Ads
To reduce latency before showing ads later in the app's lifecycle, ad pre-loading is heavily recommended, especially for Native layouts.

#### Preload Native Ad
```dart
MexaAds.instance.preloadNative(
  placement: "native_1",
  size: NativeAdSize.layout1, // The ad layout size: layout1 -> layout4, noMedia, noMedia2, fullScreen
  adHeight: 280, // Optional custom height, otherwise uses predefined AdConstant heights
  adBackgrounColor: Colors.white, // Custom background color
  adBannerColor: Colors.blue, // Primary color for banner/badges
  adCTABackgroundColor: [Color(0xffFFA17A), Color(0xffB50AC1)], // Gradient colors for Call-To-Action button
  adCTATextColor: Colors.white, // Text color for CTA
  adTitleTextColor: Colors.black, // Title text color
  adBodyTextColor: Colors.grey, // Body text color
  gradientOrientation: GradientOrientation.leftToRight, // Gradient direction for CTA
  borderRadius: 12, // Border radius for the Call-To-Action button
  onAdLoaded: () => print('Preload successfully'),
  onAdFailedToLoad: () => print('Preload failed'),
  onAdClicked: () => print('Ad clicked'),
  onAdClosed: () => print('Ad closed'),
  onRevenuePaid: (ad, valueMicros, precision, currencyCode, adType) {
    print('Earned revenue: $valueMicros $currencyCode');
  }
);
```

---

### 4.3. Full-Screen Ads (Interstitial, App Open, Rewarded)

For all full-screen ads, the plugin provides 3 granular methods:
- **`loadX`**: Preloads the ad blindly into memory. Recommended calling ahead of time.
- **`showX`**: Shows the preloaded ad immediately if it exists.
- **`loadAndShowX`**: Loads the ad, shows a loading overlay screen, and then presents the ad immediately once loaded (or fails after a timeout).

#### Interstitial Ad

**1. Load Interstitial Ad**:
```dart
bool isSuccess = await MexaAds.instance.loadInterAd(
  placement: 'inter_1',
  onAdLoaded: () => print('Interstitial ad loaded in background'),
  onAdFailToLoad: () => print('Interstitial failed to load'),
);
```

**2. Show Interstitial Ad**:
```dart
MexaAds.instance.showInterAd(
  placement: 'inter_1',
  forceShow: false, // If false, the ad won't show if the `interstitialOffsetTime` has not elapsed since the last ad
  reloadAfterShow: true, // Automatically triggers another `loadInterAd` upon ad dismissal
  recordLastTimeShowAd: true, // Updates the `lastestTimeShowInterstitialAd` timestamp after dismissing
  onShowInOffsetTime: () => print('Did not show due to offset time restrict'),
  onAdDisplay: () => print('Ad displayed'),
  onAdClicked: () => print('Ad clicked'),
  onAdDismissedFullScreenContent: () => print('Ad closed'),
  onAdFailedToShow: () => print('Ad failed to show'),
);
``` 

**3. Load & Show Interstitial Ad**:
```dart
MexaAds.instance.loadAndShowInterAd(
  context: context,
  placement: 'inter_1',
  showLoading: true, // Whether to show a transparent LoadingOverlay while fetching the ad
  customLoadingOverlay: null, // Custom MaterialPageRoute or transparent Route for the loading screen
  forceShow: false, // Discards offset time limit if true
  reloadAfterShow: true,
  onAdLoaded: () => print('Ad loaded'),
  onAdFailToLoad: () => print('Failed to load ad'),
  onAdDisplay: () => print('Ad displayed on screen'),
  onAdDismissedFullScreenContent: () => print('Ad dismissed'),
);
```

#### App Open Ad
App Open Ads are intended for the app's `AppLifecycleState.resumed` state. Make sure to check `MexaAds.instance.isShowingFullScreenAd` before invoking.

**1. Load App Open Ad**:
```dart
await MexaAds.instance.loadAppOpenAd(
  placement: 'app_open_1',
  onAdLoaded: () => print('AOA Loaded'),
  onAdFailToLoad: () => print('AOA Failed'),
);
```

**2. Show App Open Ad**:
```dart
MexaAds.instance.showAppOpenAd(
  context: context,
  placement: 'app_open_1',
  forceShow: false, // Honors `appOpenOffsetTime` constraint if false
  reloadAfterShow: true,
  recordLastTimeShowAd: true,
  onShowInOffsetTime: () => print('Blocked by offset time'),
  onAdDisplay: () => print('AOA showing'),
  onAdDismissedFullScreenContent: () => print('AOA dismissed'),
);
```

**3. Load & Show App Open Ad**:
```dart
MexaAds.instance.loadAndShowAppOpenAd(
  context: context, // Context required for placeholder navigation
  placement: 'app_open_1',
  showLoading: true, 
  forceShow: true, // Overrides the offset time rule
  onAdLoaded: () => print('Ad loaded'),
  onAdFailToLoad: () => print('Ad failed to load'),
  onAdDisplay: () => print('Ad displayed'),
  onAdDismissedFullScreenContent: () => print('Ad closed'),
);
```

#### Rewarded Ad

**1. Load Rewarded Ad**:
```dart
await MexaAds.instance.loadRewardAd(
  placement: 'rewarded_1',
  onAdLoaded: () => print('Reward Loaded'),
  onAdFailToLoad: () => print('Reward Failed'),
);
```

**2. Show Rewarded Ad**:
```dart
MexaAds.instance.showRewardAd(
  placement: 'rewarded_1',
  reloadAfterShow: true, // Reload automatically upon closure
  onAdDisplay: () => print('Reward Ad Showing'),
  onAdClicked: () => print('Ad Clicked'),
  onAdDismissedFullScreenContent: () => print('Reward Ad Dismissed'),
  onAdFailedToShow: () => print('Failed to show'),
);
```

**3. Load & Show Rewarded Ad**:
```dart
MexaAds.instance.loadAndShowRewardAd(
  context: context,
  placement: 'rewarded_1',
  showLoading: true,
  reloadAfterShow: true,
  onAdLoaded: () => print('Reward ad loaded via showAndLoad'),
  onAdFailToLoad: () => print('Failed to load reward ad'),
  onAdDisplay: () => print('Appeared!'),
  onAdDismissedFullScreenContent: () => print('Gone!'),
);
```

---

### 4.4. Native Ad Widget
Presents highly customizable Native layout templates directly inside your widget tree/lists. If `preloadNative` was called earlier with the same `placement`, this widget will immediately render the cached ad.

```dart
NativeAdWidget(
  placement: 'native_1',
  size: NativeAdSize.layout1, // Supported templates: layout1 -> layout4, noMedia, noMedia2, fullScreen
  showCloseButton: false, // Shows a top-right close button for `fullScreen` sizes
  adHeight: 280, // Dynamic forced height. Otherwise determined strictly by `size`
  
  // Custom Styles overrides for this specific placement:
  adCTABackgroundColor: [Colors.orange, Colors.red],
  adCTATextColor: Colors.white,
  adTitleTextColor: Colors.black,
  adBodyTextColor: Colors.black54,
  adBannerColor: Colors.green,
  adBackgrounColor: Colors.grey[100],
  
  gradientOrientation: GradientOrientation.leftToRight,
  borderRadius: 12, // Accepts: 12, 16, 20, 24, 28, 30
  
  // View Callbacks
  onAdLoaded: () => print('Native loaded onto view'),
  onAdFailedToLoad: () => print('Native failed rendering'),
  onAdClicked: () => print('Native tapped'),
  onAdClosed: () => print('Native closed entirely'),
  onRevenuePaid: (ad, valueMicros, precision, currencyCode, adType) {
    print('Ad revenue captured: $valueMicros $currencyCode');
  },
);
```

---

### 4.5. Banner Anchor Ad Widget
A traditional bottom/top fixed width Smart Banner layout.

```dart
BannerAnchorAdWidget(
  placement: 'banner_1',
  onAdLoaded: () => print('Banner Loaded'),
);
```

---

### 4.6. Banner Collapsible Ad Widget
Presents a collapsing banner which provides a superior user experience if a banner ad sits over application content.

```dart
CollapsibleAdWidget(
  placement: 'collap_1',
  isBottom: true, // Anchor position
  isCollapsOnce: true, // Only collapse automatically once 
  reloadTimeInSeconds: 30, // Or -1 to use Admob Console auto reload
);
```

---

### 4.7. Inline Adaptive Ad Widget
Creates an inline adaptive banner ideal for scrolling contents (like ListViews) without taking fixed overlay real estates.

```dart
InlineAdaptiveAdWidget(
  placement: 'inline_1',
  insetsPadding: 16.0,
);
```

---

### Additional Integrations: Ad Inspector
Developers can use AdMob's Ad Inspector to examine ad loading flows for all registered mediations immediately inside the platform:
```dart
MexaAds.instance.openAdInspector();
```
