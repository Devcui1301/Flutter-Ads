import Foundation
import google_mobile_ads

public class NativeAdFullScreenCustom1Factory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {

        // Parse styling from Flutter customOptions
                // 1. Container (full screen)
        let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // 2. MediaView — fills top, expands to fill available space
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // 3. Content row: icon (50x50 square) | headline + body
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(contentView)

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)
        adView.iconView = iconView

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

        // 4. CTA Button — full width at bottom
        let callToActionView = GradientButton(type: .custom)
        callToActionView.translatesAutoresizingMaskIntoConstraints = false
        callToActionView.setTitleColor(style.ctaTextColor, for: .normal)
        callToActionView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        callToActionView.isUserInteractionEnabled = false
        adView.addSubview(callToActionView)
        adView.callToActionView = callToActionView
        style.applyCTABackground(to: callToActionView)

        // 5. Constraints
        // Layout: MediaView(top, expands) → contentView(16margin) → CTA(full width, bottom)

        // Make mediaView expand to fill available space
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        // Make content and CTA resist compression (stay at natural size)
        contentView.setContentHuggingPriority(.required, for: .vertical)
        contentView.setContentCompressionResistancePriority(.required, for: .vertical)
        callToActionView.setContentHuggingPriority(.required, for: .vertical)
        callToActionView.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Media: top, leading, trailing, flexible height
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: -16),

            // Content row: between media and CTA, 16px horizontal margin
            contentView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: callToActionView.topAnchor, constant: -16),

            // Icon: 50x50 square, left-aligned in content
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50),

            // Headline: right of icon, top aligned
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headlineView.topAnchor.constraint(equalTo: contentView.topAnchor),

            // Body: below headline
            bodyView.leadingAnchor.constraint(equalTo: headlineView.leadingAnchor),
            bodyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 4),
            bodyView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            // CTA: full width, bottom
            callToActionView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            callToActionView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            callToActionView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16),
            callToActionView.heightAnchor.constraint(equalToConstant: 48)
        ])

        // 6. Populate ad data
        return adView
    }
}
