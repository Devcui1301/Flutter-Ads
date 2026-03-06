import Foundation
import google_mobile_ads

public class NativeLayout3Factory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
                let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // Icon 48x48 — top left, no padding
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView

        // Badge — right of icon, top
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

        // Headline — right of badge
        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.font = UIFont.boldSystemFont(ofSize: 12)
        headlineView.textColor = style.titleTextColor
        headlineView.numberOfLines = 1
        adView.addSubview(headlineView)
        adView.headlineView = headlineView

        // Body — below headline, full width right of icon
        let bodyView = UILabel()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = UIFont.systemFont(ofSize: 11)
        bodyView.textColor = style.bodyTextColor
        bodyView.numberOfLines = 2
        adView.addSubview(bodyView)
        adView.bodyView = bodyView

        // MediaView — expanded
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // CTA — RIGHT-ALIGNED, wrap-content width
        let ctaButton = GradientButton(type: .custom)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitleColor(style.ctaTextColor, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        ctaButton.isUserInteractionEnabled = false
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        style.applyCTABackground(to: ctaButton)

        NSLayoutConstraint.activate([
            // Icon: top-left, 48x48
            iconView.topAnchor.constraint(equalTo: adView.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            // Badge: right of icon
            adBadge.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            // Headline: right of badge
            headlineView.leadingAnchor.constraint(equalTo: adBadge.trailingAnchor, constant: 8),
            headlineView.centerYAnchor.constraint(equalTo: adBadge.centerYAnchor),
            headlineView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // Body: below headline, leading from icon trailing
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 2),
            bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            bodyView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // CTA: RIGHT-ALIGNED, wrap-content, explicitly define height constraint
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Media: expanded, 16dp vertical margins, below icon and body, ABOVE the CTA
            // Use equalTo constraints with lower priority to encourage expansion without breaking layout
            mediaView.topAnchor.constraint(greaterThanOrEqualTo: iconView.bottomAnchor, constant: 16),
            mediaView.topAnchor.constraint(greaterThanOrEqualTo: bodyView.bottomAnchor, constant: 16),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -16),
            
            // Explicitly give mediaView a minimum height/width constraint so AutoLayout doesn't crush it
            mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            mediaView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        
        // Critical for iOS AutoLayout: give MediaView a low vertical hugging priority 
        // so it willingly expands, but high compression resistance so it doesn't get crushed by the adView bounds
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        return adView
    }
}
