import Foundation
import google_mobile_ads

public class NativeAdNoMediaFactory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
                let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // Badge — top left
        let adBadge = PaddedLabel()
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.text = "Ad"
        adBadge.font = UIFont.italicSystemFont(ofSize: 8)
        adBadge.textColor = .white
        adBadge.backgroundColor = style.adBannerColor
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.textInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        adBadge.setContentHuggingPriority(.required, for: .horizontal)
        adBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        adView.addSubview(adBadge)

        // Icon 36x36
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView

        // Headline
        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        headlineView.font = UIFont.boldSystemFont(ofSize: 12)
        headlineView.textColor = style.titleTextColor
        headlineView.numberOfLines = 1
        adView.addSubview(headlineView)
        adView.headlineView = headlineView

        // Body
        let bodyView = UILabel()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = UIFont.systemFont(ofSize: 11)
        bodyView.textColor = style.bodyTextColor
        bodyView.numberOfLines = 2
        adView.addSubview(bodyView)
        adView.bodyView = bodyView

        // CTA — fixed width 110, right-aligned, vertically centered
        let ctaButton = GradientButton(type: .custom)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitleColor(style.ctaTextColor, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        ctaButton.titleLabel?.lineBreakMode = .byTruncatingTail
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        ctaButton.isUserInteractionEnabled = false
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        style.applyCTABackground(to: ctaButton)

        NSLayoutConstraint.activate([
            // Badge: top left, height 16
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            // Icon: below badge, left
            iconView.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 4),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            // Headline: right of icon
            headlineView.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineView.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),

            // Body: below headline
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 2),
            bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            bodyView.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),

            // CTA: right-aligned, fixed 110 width, vertically centered to icon
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            ctaButton.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            ctaButton.widthAnchor.constraint(equalToConstant: 110)
        ])

        return adView
    }
}
