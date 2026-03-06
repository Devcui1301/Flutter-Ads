package com.mexa.mexa_ads

import android.content.res.Resources
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.graphics.drawable.DrawableCompat
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

abstract class BaseNativeAdFactory(protected val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    abstract val layoutId: Int

    override fun createNativeAd(
        nativeAd: NativeAd?, customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(layoutId, null) as NativeAdView

        // Set the media view if it exists in the layout.
        val mediaView = adView.findViewById<com.google.android.gms.ads.nativead.MediaView>(R.id.ad_media)
        if (mediaView != null) {
            adView.mediaView = mediaView
            adView.mediaView?.mediaContent = nativeAd?.mediaContent
        }

        // Set other ad assets.
        val mainAdView: ConstraintLayout? = adView.findViewById(R.id.main_ad_view)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
//        val priceView = adView.findViewById<TextView>(R.id.ad_price)
//        val storeView = adView.findViewById<TextView>(R.id.ad_store)

        if (headlineView != null) {
            adView.headlineView = headlineView
            headlineView.text = nativeAd?.headline
        }

        if (bodyView != null) {
            adView.bodyView = bodyView
            if (nativeAd?.body == null) {
                // Different layouts use INVISIBLE or GONE, defaulting to GONE here for safety, 
                // but some layouts specifically expected INVISIBLE. We'll use INVISIBLE to match the majority of old factories.
                bodyView.visibility = View.INVISIBLE
            } else {
                bodyView.visibility = View.VISIBLE
                bodyView.text = nativeAd.body
            }
        }

        if (callToActionView != null) {
            adView.callToActionView = callToActionView
            if (nativeAd?.callToAction == null) {
                callToActionView.visibility = View.INVISIBLE
            } else {
                callToActionView.visibility = View.VISIBLE
                callToActionView.text = nativeAd.callToAction
            }
        }

        if (iconView != null) {
            adView.iconView = iconView
            if (nativeAd?.icon == null) {
                iconView.visibility = View.GONE
            } else {
                iconView.setImageDrawable(nativeAd.icon?.drawable)
                iconView.visibility = View.VISIBLE
            }
        }

//        if (priceView != null) {
//            adView.priceView = priceView
//            if (nativeAd?.price == null) {
//                priceView.visibility = View.INVISIBLE
//            } else {
//                priceView.visibility = View.VISIBLE
//                // priceView.text = nativeAd.price 
//            }
//        }
//
//        if (storeView != null) {
//            adView.storeView = storeView
//            if (nativeAd?.store == null) {
//                storeView.visibility = View.INVISIBLE
//            } else {
//                storeView.visibility = View.VISIBLE
//                // storeView.text = nativeAd.store
//            }
//        }

        // Handle custom options
        if (customOptions != null && mainAdView != null) {
            if (customOptions["ad_height"] != null) {
                val heightObj = customOptions["ad_height"]
                val heightInt = if (heightObj is Int) heightObj else (heightObj as? Double)?.toInt() ?: -1
                if (heightInt != -1) {
                    mainAdView.layoutParams.height =
                        (heightInt * Resources.getSystem().displayMetrics.density).toInt()
                }
            }
            if (customOptions["bg_color"] != null) {
                val gradientDrawable = GradientDrawable()
                gradientDrawable.setColor(Color.parseColor(customOptions["bg_color"] as String))
                gradientDrawable.cornerRadius = 12f * Resources.getSystem().displayMetrics.density
                mainAdView.background = gradientDrawable
            }
        }

        if (customOptions != null) {
            if (customOptions["cta_bg_color"] != null && callToActionView != null) {
                val colors = customOptions["cta_bg_color"] as List<String>
                val bRadiusObj = customOptions["cta_border_radius"]
                val passedRadius = if (bRadiusObj is Int) bRadiusObj.toFloat() else 12f
                val cornerRadiusPixels = passedRadius * Resources.getSystem().displayMetrics.density

                if (colors.size >= 2) {
                    val intColors = colors.map { Color.parseColor(it) }.toIntArray()
                    val gradientOrientation = when (customOptions["gradient_orientation"] as? String) {
                        "LEFT_RIGHT" -> GradientDrawable.Orientation.LEFT_RIGHT
                        "TOP_BOTTOM" -> GradientDrawable.Orientation.TOP_BOTTOM
                        "RIGHT_LEFT" -> GradientDrawable.Orientation.RIGHT_LEFT
                        "BOTTOM_TOP" -> GradientDrawable.Orientation.BOTTOM_TOP
                        "BL_TR" -> GradientDrawable.Orientation.BL_TR
                        "BR_TL" -> GradientDrawable.Orientation.BR_TL
                        "TL_BR" -> GradientDrawable.Orientation.TL_BR
                        "TR_BL" -> GradientDrawable.Orientation.TR_BL
                        else -> GradientDrawable.Orientation.LEFT_RIGHT
                    }
                    val gradientDrawable = GradientDrawable(gradientOrientation, intColors)
                    gradientDrawable.cornerRadius = cornerRadiusPixels
                    callToActionView.background = gradientDrawable
                } else {
                    val colorHex = if (colors.isNotEmpty()) colors[0] else "#FF6200EE"
                    val gradientDrawable = GradientDrawable()
                    gradientDrawable.setColor(Color.parseColor(colorHex))
                    gradientDrawable.cornerRadius = cornerRadiusPixels
                    callToActionView.background = gradientDrawable
                }
            }

            if (customOptions["title_text_color"] != null && headlineView != null) {
                headlineView.setTextColor(Color.parseColor(customOptions["title_text_color"] as String))
            }
            if (customOptions["body_text_color"] != null && bodyView != null) {
                bodyView.setTextColor(Color.parseColor(customOptions["body_text_color"] as String))
            }
            if (customOptions["cta_text_color"] != null && callToActionView != null) {
                callToActionView.setTextColor(Color.parseColor(customOptions["cta_text_color"] as String))
            }
            
            val adBannerView = adView.findViewById<TextView>(R.id.ad_banner)
            if (customOptions["ad_banner_color"] != null && adBannerView != null) {
                val wrappedDrawable = DrawableCompat.wrap(
                    MexaAdsPlugin.resources.getDrawable(R.drawable.bg_text_ad, null)
                )
                DrawableCompat.setTint(
                    wrappedDrawable,
                    Color.parseColor(customOptions["ad_banner_color"] as String)
                )
                adBannerView.background = wrappedDrawable
            }
        }

        if (nativeAd != null) {
            adView.setNativeAd(nativeAd)
        }

        return adView
    }
}
