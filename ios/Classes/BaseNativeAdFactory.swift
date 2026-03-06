import Foundation
import google_mobile_ads

open class BaseNativeAdFactory: NSObject, FLTNativeAdFactory {
    open func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
        fatalError("Subclasses must override buildAdView")
    }

    public func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
        let style = NativeAdStyleOptions.from(customOptions)

        // Subclass provides the layout with constrained subviews
        let adView = buildAdView(style: style)

        // Populate common fields
        (adView.headlineView as? UILabel)?.text = nativeAd.headline

        (adView.bodyView as? UILabel)?.text = nativeAd.body
        adView.bodyView?.isHidden = nativeAd.body == nil

        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        adView.callToActionView?.isHidden = nativeAd.callToAction == nil

        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil

        adView.mediaView?.mediaContent = nativeAd.mediaContent
        adView.nativeAd = nativeAd

        return adView
    }
}
