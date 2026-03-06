import Flutter
import UIKit
import google_mobile_ads

public class MexaAdsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mexa_ads", binaryMessenger: registrar.messenger())
    let instance = MexaAdsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

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
    
    if let registry = UIApplication.shared.delegate as? FlutterPluginRegistry {
        for (factoryId, factory) in factories {
            FLTGoogleMobileAdsPlugin.registerNativeAdFactory(registry, factoryId: factoryId, nativeAdFactory: factory)
        }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
