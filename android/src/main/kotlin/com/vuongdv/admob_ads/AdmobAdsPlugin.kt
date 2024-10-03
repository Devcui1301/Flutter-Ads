package com.vuongdv.admob_ads

import NativeAdFullScreenFactory
import NativeAdMediumFactory
import NativeAdSmallFactory
import NativeAdSquareFactory
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Resources
import android.os.Build
import android.view.LayoutInflater
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/** AdmobAdsPlugin */
class AdmobAdsPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    companion object {
        lateinit var resources: Resources
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "admob_ads")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        resources = flutterPluginBinding.applicationContext.resources

        flutterPluginBinding.flutterEngine.plugins.add(GoogleMobileAdsPlugin())
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterPluginBinding.flutterEngine,
            "nativeAdSmallFactory",
            NativeAdSmallFactory(LayoutInflater.from(flutterPluginBinding.applicationContext))
        )

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterPluginBinding.flutterEngine,
            "nativeAdMediumFactory",
            NativeAdMediumFactory(LayoutInflater.from(flutterPluginBinding.applicationContext))
        )

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterPluginBinding.flutterEngine,
            "nativeAdSquareFactory",
            NativeAdSquareFactory(LayoutInflater.from(flutterPluginBinding.applicationContext))
        )

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterPluginBinding.flutterEngine,
            "nativeAdFullScreenFactory",
            NativeAdFullScreenFactory(LayoutInflater.from(flutterPluginBinding.applicationContext))
        )
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "pauseCollapsibleAdLoad") {
            Intent().apply {
                action = "action.CollapsibleVisibilityAction"
                setPackage(applicationContext.packageName)
                putExtra("type", "pauseCollapsibleAdLoad")
                putExtra("placement", (call.arguments as Map<*, *>)["placement"] as String)
                applicationContext.sendBroadcast(this)
            }
        } else if (call.method == "resumeCollapsibleAdLoad") {
            Intent().apply {
                action = "action.CollapsibleVisibilityAction"
                setPackage(applicationContext.packageName)
                putExtra("type", "resumeCollapsibleAdLoad")
                putExtra("placement", (call.arguments as Map<*, *>)["placement"] as String)
                applicationContext.sendBroadcast(this)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
