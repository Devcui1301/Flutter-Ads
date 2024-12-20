package com.mexa.mexa_ads

import android.annotation.SuppressLint
import android.content.res.Resources
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.graphics.drawable.DrawableCompat
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.mexa.mexa_ads.R
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFullScreenFactory : GoogleMobileAdsPlugin.NativeAdFactory {
    private var layoutInflater: LayoutInflater

    constructor(layoutInflater: LayoutInflater) {
        this.layoutInflater = layoutInflater
    }

    @SuppressLint("UseCompatLoadingForDrawables")
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = layoutInflater.inflate(R.layout.native_ad_full_screen, null) as NativeAdView

        // Set the media view.
        adView.mediaView = adView.findViewById(R.id.media_view)

        // Set other ad assets.
        val mainAdView: ConstraintLayout = adView.findViewById(R.id.main_ad_view)
        adView.headlineView = adView.findViewById(R.id.primary)
        adView.bodyView = adView.findViewById(R.id.body)
        adView.callToActionView = adView.findViewById(R.id.cta)
        adView.iconView = adView.findViewById(R.id.icon)
//    adView.priceView = adView.findViewById(R.id.ad_price)
        adView.starRatingView = adView.findViewById(R.id.rating_bar)
//    adView.storeView = adView.findViewById(R.id.ad_store)
        adView.advertiserView = adView.findViewById(R.id.secondary)

        // The headline and mediaContent are guaranteed to be in every NativeAd.
        (adView.headlineView as TextView).text = nativeAd?.headline
        adView.mediaView?.mediaContent = nativeAd?.mediaContent

        // These assets aren't guaranteed to be in every NativeAd, so it's important to
        // check before trying to display them.
        if (nativeAd?.body == null) {
            adView.bodyView?.visibility = View.GONE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd?.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd?.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon!!.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd?.price == null) {
            adView.priceView?.visibility = View.INVISIBLE
        } else {
            adView.priceView?.visibility = View.VISIBLE
//      (adView.priceView as TextView).text = nativeAd.price
        }

        if (nativeAd?.store == null) {
            adView.storeView?.visibility = View.INVISIBLE
        } else {
            adView.storeView?.visibility = View.VISIBLE
//      (adView.storeView as TextView).text = nativeAd.store
        }

        if (nativeAd?.starRating == null) {
            adView.starRatingView?.visibility = View.GONE
        } else {
            (adView.starRatingView as RatingBar).rating = nativeAd.starRating!!.toFloat()
            adView.starRatingView?.visibility = View.VISIBLE
        }

        if (nativeAd?.advertiser == null) {
            adView.advertiserView?.visibility = View.INVISIBLE
        } else {
            adView.advertiserView?.visibility = View.VISIBLE
            (adView.advertiserView as TextView).text = nativeAd.advertiser
        }

        // This method tells the Google Mobile Ads SDK that you have finished populating your
        // native ad view with this native ad.
        if (nativeAd != null) {
            adView.setNativeAd(nativeAd)
        }

        if (customOptions != null) {
            if (customOptions["ad_height"] != null && customOptions["ad_height"] != -1) {
                mainAdView.layoutParams.height =
                    ((customOptions["ad_height"] as Int) * Resources.getSystem().displayMetrics.density).toInt()
            }
//            if (customOptions["bg_color"] != null) {
//                val wrappedDrawable = DrawableCompat.wrap(
//                    AdmobAdsPlugin.resources
//                        .getDrawable(R.drawable.bg_border_radius_8, null)
//                )
//                DrawableCompat.setTint(wrappedDrawable, Color.parseColor(customOptions["bg_color"] as String))
//
//                mainAdView.background = wrappedDrawable
//            }
            if (customOptions["cta_bg_color"] != null) {
                val wrappedDrawable = DrawableCompat.wrap(
                    MexaAdsPlugin.resources
                        .getDrawable(R.drawable.bg_border_radius_8, null)
                )
                DrawableCompat.setTint(wrappedDrawable, Color.parseColor(customOptions["cta_bg_color"] as String))


                (adView.callToActionView as Button).background = wrappedDrawable
            }
            if (customOptions["title_text_color"] != null) {
                (adView.headlineView as TextView).setTextColor(
                    Color.parseColor(customOptions["title_text_color"] as String)
                )
            }
            if (customOptions["body_text_color"] != null) {
                (adView.bodyView as TextView).setTextColor(
                    Color.parseColor(customOptions["body_text_color"] as String)
                )
            }
            if (customOptions["cta_text_color"] != null) {
                (adView.callToActionView as TextView).setTextColor(
                    Color.parseColor(customOptions["cta_text_color"] as String)
                )
            }
            if (customOptions["ad_banner_color"] != null) {
                val wrappedDrawable = DrawableCompat.wrap(
                    MexaAdsPlugin.resources
                        .getDrawable(R.drawable.bg_text_ad_no_border, null)
                )
                DrawableCompat.setTint(wrappedDrawable, Color.parseColor(customOptions["ad_banner_color"] as String))
                (adView.findViewById(R.id.ad_banner) as TextView).background =
                    wrappedDrawable

            }

        }

        return adView
    }
}