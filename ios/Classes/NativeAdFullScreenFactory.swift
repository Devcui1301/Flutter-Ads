import Foundation
import google_mobile_ads

public class NativeAdFullScreenFactory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
                let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // Content at top: icon(50) + headline + body
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView

        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.font = UIFont.boldSystemFont(ofSize: 14)
        headlineView.textColor = style.titleTextColor
        headlineView.numberOfLines = 1
        adView.addSubview(headlineView)
        adView.headlineView = headlineView

        let bodyView = UILabel()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = UIFont.systemFont(ofSize: 12)
        bodyView.textColor = style.bodyTextColor
        bodyView.numberOfLines = 3
        adView.addSubview(bodyView)
        adView.bodyView = bodyView

        // Media — expanded
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // CTA — full width at bottom
        let ctaButton = GradientButton(type: .custom)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitleColor(style.ctaTextColor, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ctaButton.isUserInteractionEnabled = false
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        style.applyCTABackground(to: ctaButton)

        // Make mediaView expand to fill available space
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        // Make content labels and CTA resist compression (stay at natural size)
        ctaButton.setContentHuggingPriority(.required, for: .vertical)
        ctaButton.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Icon: top with margin 36
            iconView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 36),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50),

            // Headline: right of icon
            headlineView.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // Body: below headline
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 4),
            bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            bodyView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // Media: expanded between content and CTA
            mediaView.topAnchor.constraint(equalTo: bodyView.bottomAnchor, constant: 16),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -16),

            // CTA
            ctaButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        return adView
    }
}
