import Foundation
import google_mobile_ads

public class NativeAdFullScreenCustom2Factory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {

        // Parse styling from Flutter customOptions
                // 1. Container (full screen)
        let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // 2. MediaView — fills the ENTIRE background (match_parent in both dimensions)
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // 3. Content overlay at bottom (headline + body, NO icon)
        // marginTop=36dp from bottom of CTA, marginHorizontal=16
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(contentView)

        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.font = UIFont.boldSystemFont(ofSize: 14)
        headlineView.textColor = style.titleTextColor
        headlineView.numberOfLines = 1
        contentView.addSubview(headlineView)
        adView.headlineView = headlineView

        let bodyView = UILabel()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = UIFont.systemFont(ofSize: 12)
        bodyView.textColor = style.bodyTextColor
        bodyView.numberOfLines = 3
        contentView.addSubview(bodyView)
        adView.bodyView = bodyView

        // 4. CTA Button — centered, wrap-content width (with horizontal padding)
        let callToActionView = GradientButton(type: .custom)
        callToActionView.translatesAutoresizingMaskIntoConstraints = false
        callToActionView.setTitleColor(style.ctaTextColor, for: .normal)
        callToActionView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        callToActionView.contentEdgeInsets = UIEdgeInsets(top: 14, left: 32, bottom: 14, right: 32)
        callToActionView.isUserInteractionEnabled = false
        adView.addSubview(callToActionView) 
        adView.callToActionView = callToActionView
        style.applyCTABackground(to: callToActionView)
        callToActionView.layer.cornerRadius = 26
        callToActionView.clipsToBounds = true

        // 5. Constraints
        // Layout: MediaView fills entire view → content (headline+body) overlaid above CTA → CTA centered at bottom
        NSLayoutConstraint.activate([
            // Media: fill entire view (with 30pt bottom margin as in Android)
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -30),

            // Content: above CTA, horizontal margins 16px
            contentView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: callToActionView.topAnchor, constant: -16),

            // Headline: full width, top of content
            headlineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            headlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headlineView.topAnchor.constraint(equalTo: contentView.topAnchor),

            // Body: below headline
            bodyView.leadingAnchor.constraint(equalTo: headlineView.leadingAnchor),
            bodyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 4),
            bodyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // CTA: centered horizontally, wrap-content width, at bottom
            callToActionView.centerXAnchor.constraint(equalTo: adView.centerXAnchor),
            callToActionView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16)
        ])

        // 6. Populate ad data
        return adView
    }
}
