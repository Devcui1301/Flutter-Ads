import Foundation
import google_mobile_ads

public class NativeLayout2Factory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
                let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // Ad badge — top left
        let adBadge = PaddedLabel()
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.text = "Ad"
        adBadge.font = UIFont.italicSystemFont(ofSize: 10)
        adBadge.textColor = .white
        adBadge.backgroundColor = style.adBannerColor
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.textInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        adBadge.setContentHuggingPriority(.required, for: .horizontal)
        adBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        adView.addSubview(adBadge)

        // Content area (left side) — icon + headline + body vertical stack
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView

        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.font = UIFont.boldSystemFont(ofSize: 12)
        headlineView.textColor = style.titleTextColor
        headlineView.numberOfLines = 2
        adView.addSubview(headlineView)
        adView.headlineView = headlineView

        let bodyView = UILabel()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = UIFont.systemFont(ofSize: 11)
        bodyView.textColor = style.bodyTextColor
        bodyView.numberOfLines = 2
        adView.addSubview(bodyView)
        adView.bodyView = bodyView

        // Media (right side)
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

        // Layout: badge on top, then row [content | media], then CTA
        // Media takes ~50% width
        NSLayoutConstraint.activate([
            // Badge: top left
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            // Icon: left side, below badge
            iconView.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 4),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            // Headline: right of icon
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineView.trailingAnchor.constraint(equalTo: mediaView.leadingAnchor, constant: -8),
            headlineView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            // Body: below icon row
            bodyView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            bodyView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
            bodyView.trailingAnchor.constraint(equalTo: mediaView.leadingAnchor, constant: -8),

            // Media: right side, from badge bottom to CTA top
            mediaView.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 2),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),
            mediaView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -8),
            mediaView.widthAnchor.constraint(equalTo: adView.widthAnchor, multiplier: 0.45),
            mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            mediaView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            // CTA: full width at bottom
            ctaButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            ctaButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        return adView
    }
}
