import Foundation
import UIKit

/// Shared helper to parse the customOptions Dictionary sent from Flutter's NativeAdWidget
/// into UIColors, so each Factory class can apply them consistently.
public struct NativeAdStyleOptions {
    public var backgroundColor: UIColor
    public var ctaBackgroundColors: [UIColor]   // supports gradient (2+ colors)
    public var ctaTextColor: UIColor
    public var titleTextColor: UIColor
    public var bodyTextColor: UIColor
    public var adBannerColor: UIColor
    public var ctaBorderRadius: CGFloat
    public var gradientOrientation: String     // "LEFT_RIGHT", "TOP_BOTTOM" etc.

    public init(
        backgroundColor: UIColor = UIColor(red: 244/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0),
        ctaBackgroundColors: [UIColor] = [UIColor(red: 214/255.0, green: 249/255.0, blue: 5/255.0, alpha: 1.0)],
        ctaTextColor: UIColor = .black,
        titleTextColor: UIColor = .black,
        bodyTextColor: UIColor = UIColor(white: 0.53, alpha: 1.0),
        adBannerColor: UIColor = UIColor(red: 250/255.0, green: 200/255.0, blue: 0, alpha: 1.0),
        ctaBorderRadius: CGFloat = 8,
        gradientOrientation: String = "LEFT_RIGHT"
    ) {
        self.backgroundColor = backgroundColor
        self.ctaBackgroundColors = ctaBackgroundColors
        self.ctaTextColor = ctaTextColor
        self.titleTextColor = titleTextColor
        self.bodyTextColor = bodyTextColor
        self.adBannerColor = adBannerColor
        self.ctaBorderRadius = ctaBorderRadius
        self.gradientOrientation = gradientOrientation
    }

    /// Parse from the customOptions dictionary forwarded by Flutter's google_mobile_ads plugin.
    /// Note: colorToHexString() in Dart emits 8-char ARGB hex: #AARRGGBB
    /// Note: cta_bg_color is always passed as [String] (convertColorsToHex returns List<String>)
    public static func from(_ customOptions: [AnyHashable: Any]?) -> NativeAdStyleOptions {
        var opts = NativeAdStyleOptions()
        guard let dict = customOptions else { return opts }

        if let hex = dict["bg_color"] as? String, !hex.isEmpty {
            opts.backgroundColor = UIColor(argbHexString: hex) ?? opts.backgroundColor
        }
        // cta_bg_color is always a [String] list from Flutter (convertColorsToHex)
        if let arr = dict["cta_bg_color"] as? [String], !arr.isEmpty {
            opts.ctaBackgroundColors = arr.compactMap { UIColor(argbHexString: $0) }
        }
        if let hex = dict["cta_text_color"] as? String, !hex.isEmpty {
            opts.ctaTextColor = UIColor(argbHexString: hex) ?? opts.ctaTextColor
        }
        if let hex = dict["title_text_color"] as? String, !hex.isEmpty {
            opts.titleTextColor = UIColor(argbHexString: hex) ?? opts.titleTextColor
        }
        if let hex = dict["body_text_color"] as? String, !hex.isEmpty {
            opts.bodyTextColor = UIColor(argbHexString: hex) ?? opts.bodyTextColor
        }
        if let hex = dict["ad_banner_color"] as? String, !hex.isEmpty {
            opts.adBannerColor = UIColor(argbHexString: hex) ?? opts.adBannerColor
        }
        if let radius = dict["cta_border_radius"] as? Int {
            opts.ctaBorderRadius = CGFloat(radius)
        } else if let radius = dict["cta_border_radius"] as? Double {
            opts.ctaBorderRadius = CGFloat(radius)
        }
        if let orient = dict["gradient_orientation"] as? String {
            opts.gradientOrientation = orient
        }
        return opts
    }

    public func applyCTABackground(to button: UIButton) {
        button.layer.cornerRadius = ctaBorderRadius
        button.clipsToBounds = true

        if ctaBackgroundColors.count >= 2 {
            // Gradient — remove any previous gradient layer
            button.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }

            let gradient = CAGradientLayer()
            gradient.colors = ctaBackgroundColors.map { $0.cgColor }
            gradient.cornerRadius = ctaBorderRadius

            switch gradientOrientation {
            case "TOP_BOTTOM":
                gradient.startPoint = CGPoint(x: 0.5, y: 0); gradient.endPoint = CGPoint(x: 0.5, y: 1)
            case "RIGHT_LEFT":
                gradient.startPoint = CGPoint(x: 1, y: 0.5); gradient.endPoint = CGPoint(x: 0, y: 0.5)
            case "BOTTOM_TOP":
                gradient.startPoint = CGPoint(x: 0.5, y: 1); gradient.endPoint = CGPoint(x: 0.5, y: 0)
            case "TL_BR":
                gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
            case "TR_BL":
                gradient.startPoint = CGPoint(x: 1, y: 0); gradient.endPoint = CGPoint(x: 0, y: 1)
            case "BL_TR":
                gradient.startPoint = CGPoint(x: 0, y: 1); gradient.endPoint = CGPoint(x: 1, y: 0)
            case "BR_TL":
                gradient.startPoint = CGPoint(x: 1, y: 1); gradient.endPoint = CGPoint(x: 0, y: 0)
            default: // LEFT_RIGHT
                gradient.startPoint = CGPoint(x: 0, y: 0.5); gradient.endPoint = CGPoint(x: 1, y: 0.5)
            }
            button.backgroundColor = .clear

            if let gradButton = button as? GradientButton {
                gradButton.gradientLayer = gradient
            } else {
                button.layer.insertSublayer(gradient, at: 0)
                DispatchQueue.main.async {
                    gradient.frame = button.bounds
                }
            }
        } else {
            button.backgroundColor = ctaBackgroundColors.first
                ?? UIColor(red: 214/255.0, green: 249/255.0, blue: 5/255.0, alpha: 1.0)
        }
    }
}

public class GradientButton: UIButton {
    public var gradientLayer: CAGradientLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let layer = gradientLayer {
                self.layer.insertSublayer(layer, at: 0)
                layer.frame = bounds
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
}

// MARK: - UIColor ARGB hex extension
// Flutter's colorToHexString emits #AARRGGBB (alpha first), unlike CSS #RRGGBBAA
extension UIColor {
    convenience init?(argbHexString: String) {
        var hex = argbHexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }

        let a, r, g, b: CGFloat
        switch hex.count {
        case 6: // RRGGBB — no alpha
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8)  / 255.0
            b = CGFloat(rgb & 0x0000FF)          / 255.0
            a = 1.0
        case 8: // AARRGGBB — Flutter's format
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x0000FF00) >> 8)  / 255.0
            b = CGFloat(rgb & 0x000000FF)          / 255.0
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - PaddedLabel
/// UILabel subclass with text insets for internal padding (used for Ad badge)
class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
