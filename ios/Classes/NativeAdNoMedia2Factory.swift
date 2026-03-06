import Foundation
import google_mobile_ads

public class NativeAdNoMedia2Factory: BaseNativeAdFactory {
    public override func buildAdView(style: NativeAdStyleOptions) -> NativeAdView {
                let adView = NativeAdView()
        adView.backgroundColor = style.backgroundColor
        adView.clipsToBounds = true

        // Icon 36x36
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        adView.addSubview(iconView)
        adView.iconView = iconView

        // Badge
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

        // CTA — full width, below body with 12dp margin
        let ctaButton = GradientButton(type: .custom)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitleColor(style.ctaTextColor, for: .normal)
        ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        ctaButton.isUserInteractionEnabled = false
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton
        style.applyCTABackground(to: ctaButton)

        NSLayoutConstraint.activate([
            // Icon
            iconView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            // Badge
            adBadge.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
            adBadge.heightAnchor.constraint(equalToConstant: 16),

            // Headline
            headlineView.leadingAnchor.constraint(equalTo: adBadge.trailingAnchor, constant: 4),
            headlineView.centerYAnchor.constraint(equalTo: adBadge.centerYAnchor),
            headlineView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // Body
            bodyView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 2),
            bodyView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            bodyView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

            // CTA: full width, 12dp below body
            ctaButton.topAnchor.constraint(equalTo: bodyView.bottomAnchor, constant: 12),
            ctaButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
            ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return adView
    }
}
