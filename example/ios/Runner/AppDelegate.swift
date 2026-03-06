import Flutter
import UIKit
import google_mobile_ads
import mexa_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)

    let factories: [String: FLTNativeAdFactory] = [
        "nativeLayout1Factory": NativeLayout1Factory(),
        "nativeLayout2Factory": NativeLayout2Factory(),
        "nativeLayout3Factory": NativeLayout3Factory(),
        "nativeLayout4Factory": NativeLayout4Factory(),
        "nativeAdFullScreenFactory": NativeAdFullScreenFactory(),
        "nativeAdNoMediaFactory": NativeAdNoMediaFactory(),
        "nativeAdNoMedia2Factory": NativeAdNoMedia2Factory(),
        "nativeAdFullScreenCustom1Factory": NativeAdFullScreenCustom1Factory(),
        "nativeAdFullScreenCustom2Factory": NativeAdFullScreenCustom2Factory()
    ]

    for (factoryId, factory) in factories {
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(registry, factoryId: factoryId, nativeAdFactory: factory)
    }
  }
}
