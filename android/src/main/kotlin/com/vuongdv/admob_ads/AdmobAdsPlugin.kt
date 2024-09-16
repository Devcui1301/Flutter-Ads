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
    lateinit var collapsibleAdActionReceiver: CollapsibleAdActionReceiver
    private lateinit var applicationContext: Context

    companion object {
        lateinit var resources: Resources
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "admob_ads")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        resources = flutterPluginBinding.applicationContext.resources

        // config native collapsible ad view
        flutterPluginBinding.flutterEngine
                .platformViewsController
                .registry
                .registerViewFactory("admob_collapsible_ads",
                        CollapsibleAdsViewFactory()
                )

        EventChannel(flutterPluginBinding.flutterEngine.dartExecutor.binaryMessenger, "collapsible_event_callback").setStreamHandler(
                object : EventChannel.StreamHandler {

                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        val callback = object : CollapsibleAdActionCallback() {
                            override fun call(type: String, data: Any?) {
                                events?.success(hashMapOf(
                                        "type" to type,
                                        "data" to data,
                                ))
                            }
                        }
                        if (!this@AdmobAdsPlugin::collapsibleAdActionReceiver.isInitialized) {
                            collapsibleAdActionReceiver = CollapsibleAdActionReceiver()
                        }
                        collapsibleAdActionReceiver.setCallback(callback)

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            flutterPluginBinding.applicationContext.registerReceiver(
                                    collapsibleAdActionReceiver,
                                    IntentFilter("action.CollapsibleCallback"),
                                    Context.RECEIVER_NOT_EXPORTED
                            )
                        }else {
                            flutterPluginBinding.applicationContext.registerReceiver(
                                    collapsibleAdActionReceiver,
                                    IntentFilter("action.CollapsibleCallback")
                            )
                        }
                    }

                    override fun onCancel(arguments: Any?) {
                        flutterPluginBinding.applicationContext.unregisterReceiver(collapsibleAdActionReceiver)
                    }
                }
        )


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
        if (this::collapsibleAdActionReceiver.isInitialized) {
            try {
                binding.applicationContext.unregisterReceiver(collapsibleAdActionReceiver)
            } catch (_: Exception) {
            }
        }
        // GoogleMobileAdsPlugin.unregisterNativeAdFactory(binding.flutterEngine, "nativeAdFactory")
    }
}

class CollapsibleAdActionReceiver : BroadcastReceiver() {

    private lateinit var callback: CollapsibleAdActionCallback

    fun setCallback(callback: CollapsibleAdActionCallback) {
        this.callback = callback
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        val type = intent?.getStringExtra("type").toString()
        var data: Any? = null
        if ("adHeightChanged" == type) {
            data = intent?.getIntExtra("adHeight", 50)
        }
        if ("onPaidEvent" == type) {
            data = intent?.getDoubleExtra("value", 0.0)
        }
        callback.call(type = type, data = data)
    }
}

