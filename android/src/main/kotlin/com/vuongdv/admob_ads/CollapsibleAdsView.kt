package com.vuongdv.admob_ads

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.RECEIVER_NOT_EXPORTED
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import androidx.core.content.ContextCompat
import com.google.ads.mediation.admob.AdMobAdapter
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.OnPaidEventListener
import com.vuongdv.admob_ads.databinding.CollapsibleAdContainerBinding
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import java.util.Timer
import java.util.TimerTask
import java.util.UUID
import kotlin.time.Duration

@SuppressLint("ResourceType")
internal class CollapsibleAdsView(context: Context, id: Int, creationParams: Map<String?, Any?>?) :
    PlatformView {
    private var reloadTime: Int
    private val adView: AdView
    private var binding: CollapsibleAdContainerBinding
    private val collapsibleVisibilityReceiver = CollapsibleVisibilityReceiver()
    private lateinit var adRequest: AdRequest
    private var isDisposed = false
    private var isViewVisible = true
    private lateinit var timer: Timer
    private var currentTicker = 0

    override fun getView(): View {
        return binding.root
    }

    private fun getNewAdRequest(creationParams: Map<String?, Any?>?): AdRequest {
        val extras = Bundle()

        if (creationParams?.get("isBottom") == true) {
            extras.putString("collapsible", "bottom")
        }else{
            extras.putString("collapsible", "top")
        }
        if (creationParams?.get("isShowCollapseOnce") == true) {
            extras.putString("collapsible_request_id", UUID.randomUUID().toString())
        }
        adRequest =
            AdRequest.Builder().addNetworkExtrasBundle(AdMobAdapter::class.java, extras).build()
        return adRequest
    }

    private fun tickerFlow(period: Duration, initialDelay: Duration = Duration.ZERO) = flow {
        delay(initialDelay)
        while (true) {
            if (isDisposed) break
            emit(Unit)
            delay(period)
        }
    }

    @OptIn(DelicateCoroutinesApi::class)
    fun startTimer() {
        timer = Timer()
        timer.schedule(object : TimerTask() {
            override fun run() {
                GlobalScope.launch(Dispatchers.Main) {
                    adView.loadAd(adRequest)
                }
            }
        }, 200L)
        if (reloadTime != -1) {
            timer.scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    currentTicker++
                    if (isViewVisible && currentTicker % reloadTime == 0) {
                        GlobalScope.launch(Dispatchers.Main) {
                            adView.loadAd(adRequest)
                        }
                    }
                }
            }, 0, 1000)


//            tickerFlow(reloadTime.toDuration(DurationUnit.SECONDS))
//                .map {
//                    Log.d("Collapsible ≥≥≥≥≥≥≥≥", "tick: ")
//                }
//                .filter {
//                    isViewVisible
//                }
//                .onEach {
//                    Log.d("Collapsible ≥≥≥≥≥≥≥≥", adRequest.hashCode().toString())
//                    Log.d("Collapsible ≥≥≥≥≥≥≥≥", "tick: "+ Calendar.getInstance().time.toString() + ", request: " + adRequest.hashCode())
//                    adView.loadAd(adRequest)
//                }
//                .onCompletion {
//
//                }
//                .launchIn(CoroutineScope(Dispatchers.Main))
        } else {
            adView.loadAd(adRequest)
        }
    }

    init {
        binding = CollapsibleAdContainerBinding.inflate(LayoutInflater.from(context))
        adView = binding.adView
        adView.setBackgroundColor(Color.TRANSPARENT)
        getNewAdRequest(creationParams)

        reloadTime = creationParams?.get("reload_time_in_seconds") as Int
//        startTimer()
        adView.adListener = object : AdListener() {
            override fun onAdClicked() {
                // Code to be executed when the user clicks on an ad.
                sendCollapsibleAdEventCallback(context, "onAdClicked")
            }

            override fun onAdClosed() {
                sendCollapsibleAdEventCallback(context, "onAdClosed")
            }

            override fun onAdFailedToLoad(adError: LoadAdError) {
                // Code to be executed when an ad request fails.
                Log.d("Collapsible ≥≥≥≥≥≥≥≥", "failed to load: $adError")
                sendCollapsibleAdEventCallback(context, "onAdFailedToLoad")
            }

            override fun onAdImpression() {
                // Code to be executed when an impression is recorded
                // for an ad.
                sendCollapsibleAdEventCallback(context, "onAdImpression")
            }

            override fun onAdLoaded() {
                sendEventResize(context)
                // Code to be executed when an ad finishes loading.
                sendCollapsibleAdEventCallback(context, "onAdLoaded")
            }

            override fun onAdOpened() {
                // Code to be executed when an ad opens an overlay that
                // covers the screen.
                sendCollapsibleAdEventCallback(context, "onAdOpened")
            }


        }

        adView.onPaidEventListener = OnPaidEventListener {
            // Code to be executed when an ad is paid.
            sendCollapsibleAdEventCallback(context, "onPaidEvent", value = it.valueMicros / 1000000.0)

        }


        /// add receiver when ad visibility changed
        val callback = object : CollapsibleAdActionCallback() {
            override fun pauseCollapsibleAdLoad() {
                if (this@CollapsibleAdsView::timer.isInitialized) timer.cancel()
                isViewVisible = false
                isDisposed = true
                adView.pause()
                Log.d("Collapsible ≥≥≥≥≥≥≥≥", "pause load ad...")
            }

            override fun resumeCollapsibleAdLoad() {
                isViewVisible = true
                isDisposed = false
                adView.resume()
                currentTicker = 0
                startTimer()
                Log.d("Collapsible ≥≥≥≥≥≥≥≥", "resume load ad...")

            }
        }
        collapsibleVisibilityReceiver.setCallback(callback)
        collapsibleVisibilityReceiver.setPlacement(creationParams["placement"] as String)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            adView.context.registerReceiver(
                    collapsibleVisibilityReceiver,
                    IntentFilter("action.CollapsibleVisibilityAction"),
                    RECEIVER_NOT_EXPORTED
            )
        }else {
            adView.context.registerReceiver(
                    collapsibleVisibilityReceiver,
                    IntentFilter("action.CollapsibleVisibilityAction")
            )
        }

    }

    override fun dispose() {
        Log.d("Collapsible ≥≥≥≥≥≥≥≥", "dispose...")
        isDisposed = true
        if (this::timer.isInitialized) timer.cancel()
        adView.context.unregisterReceiver(collapsibleVisibilityReceiver)
    }

    private fun sendCollapsibleAdEventCallback(context: Context, type: String) {
        Intent().also {
            it.action = "action.CollapsibleCallback"
            it.setPackage(context.packageName)
            it.putExtra("type", type)
            context.sendBroadcast(it)
        }
    }

    private fun sendCollapsibleAdEventCallback(context: Context, type: String, value: Double) {
        Intent().also {
            it.action = "action.CollapsibleCallback"
            it.setPackage(context.packageName)
            it.putExtra("type", type)
            it.putExtra("value", value)
            context.sendBroadcast(it)
        }
    }

    private fun sendEventResize(context: Context) {
        Intent().also {
            it.action = "action.CollapsibleCallback"
            it.setPackage(context.packageName)
            it.putExtra("type", "adHeightChanged")
            it.putExtra("adHeight", adView.adSize?.height ?: 0)
            context.sendBroadcast(it)
        }
    }
}

class CollapsibleVisibilityReceiver : BroadcastReceiver() {

    private lateinit var callback: CollapsibleAdActionCallback
    private lateinit var placement: String

    fun setCallback(callback: CollapsibleAdActionCallback) {
        this.callback = callback
    }

    fun setPlacement(placement: String) {
        this.placement = placement
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "action.CollapsibleVisibilityAction") {
            if(intent.getStringExtra("placement").equals(placement)) {
                when (intent.getStringExtra("type")) {
                    "pauseCollapsibleAdLoad" -> callback.pauseCollapsibleAdLoad()
                    "resumeCollapsibleAdLoad" -> callback.resumeCollapsibleAdLoad()
                }
            }
        }
    }

}
