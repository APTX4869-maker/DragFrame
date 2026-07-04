import AppKit
import Combine

struct OverlayStyle {
    static let `default` = OverlayStyle(
        lineWidth: 6,
        cornerRadius: 18,
        contentInset: 14,
        colors: [
            NSColor(calibratedRed: 1.00, green: 0.68, blue: 0.10, alpha: 1),
            NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.49, alpha: 1),
            NSColor(calibratedRed: 0.43, green: 0.31, blue: 1.00, alpha: 1)
        ],
        locations: [0, 0.52, 1],
        startPoint: CGPoint(x: 0, y: 1),
        endPoint: CGPoint(x: 1, y: 0)
    )

    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let contentInset: CGFloat
    let colors: [NSColor]
    let locations: [NSNumber]
    let startPoint: CGPoint
    let endPoint: CGPoint

    var appearanceSummary: String {
        "\(Int(lineWidth))pt 渐变描边 · \(Int(cornerRadius))pt 圆角 · 内部透明"
    }

    func replacingColors(_ colors: [NSColor]) -> OverlayStyle {
        OverlayStyle(
            lineWidth: lineWidth,
            cornerRadius: cornerRadius,
            contentInset: contentInset,
            colors: colors,
            locations: locations,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

enum OverlayStylePreset: String, CaseIterable, Identifiable {
    case vibrant
    case ocean
    case aurora
    case graphite
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vibrant:
            return "活力渐变"
        case .ocean:
            return "海蓝渐变"
        case .aurora:
            return "极光渐变"
        case .graphite:
            return "石墨白"
        case .custom:
            return "自定义"
        }
    }

    var colors: [NSColor] {
        switch self {
        case .vibrant:
            return OverlayStyle.default.colors
        case .ocean:
            return [
                NSColor(calibratedRed: 0.12, green: 0.43, blue: 1.00, alpha: 1),
                NSColor(calibratedRed: 0.10, green: 0.78, blue: 1.00, alpha: 1),
                NSColor(calibratedRed: 0.52, green: 0.93, blue: 1.00, alpha: 1)
            ]
        case .aurora:
            return [
                NSColor(calibratedRed: 0.23, green: 0.92, blue: 0.55, alpha: 1),
                NSColor(calibratedRed: 0.10, green: 0.68, blue: 1.00, alpha: 1),
                NSColor(calibratedRed: 0.58, green: 0.36, blue: 1.00, alpha: 1)
            ]
        case .graphite:
            return [
                NSColor(calibratedWhite: 1.00, alpha: 1),
                NSColor(calibratedWhite: 0.82, alpha: 1),
                NSColor(calibratedWhite: 0.62, alpha: 1)
            ]
        case .custom:
            return OverlayStylePreset.vibrant.colors
        }
    }
}

final class OverlayStyleSettings: ObservableObject {
    static let presetKey = "dragFrame.overlayStyle.preset"
    static let customStartColorKey = "dragFrame.overlayStyle.customStartColor"
    static let customMiddleColorKey = "dragFrame.overlayStyle.customMiddleColor"
    static let customEndColorKey = "dragFrame.overlayStyle.customEndColor"

    var onChange: ((OverlayStyle) -> Void)?

    @Published var selectedPreset: OverlayStylePreset {
        didSet {
            persistPreset()
            notifyChange()
        }
    }

    @Published var customStartColor: NSColor {
        didSet {
            persistColor(customStartColor, key: Self.customStartColorKey)
            notifyChange()
        }
    }

    @Published var customMiddleColor: NSColor {
        didSet {
            persistColor(customMiddleColor, key: Self.customMiddleColorKey)
            notifyChange()
        }
    }

    @Published var customEndColor: NSColor {
        didSet {
            persistColor(customEndColor, key: Self.customEndColorKey)
            notifyChange()
        }
    }

    private let defaults: UserDefaults

    var style: OverlayStyle {
        let colors = selectedPreset == .custom
            ? [customStartColor, customMiddleColor, customEndColor]
            : selectedPreset.colors
        return OverlayStyle.default.replacingColors(colors)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let rawPreset = defaults.string(forKey: Self.presetKey),
           let preset = OverlayStylePreset(rawValue: rawPreset) {
            selectedPreset = preset
        } else {
            selectedPreset = .vibrant
            defaults.set(OverlayStylePreset.vibrant.rawValue, forKey: Self.presetKey)
        }

        let fallbackColors = OverlayStylePreset.vibrant.colors
        customStartColor = Self.color(
            from: defaults.string(forKey: Self.customStartColorKey),
            fallback: fallbackColors[0]
        )
        customMiddleColor = Self.color(
            from: defaults.string(forKey: Self.customMiddleColorKey),
            fallback: fallbackColors[1]
        )
        customEndColor = Self.color(
            from: defaults.string(forKey: Self.customEndColorKey),
            fallback: fallbackColors[2]
        )
    }

    func resetToDefault() {
        selectedPreset = .vibrant
        customStartColor = OverlayStylePreset.vibrant.colors[0]
        customMiddleColor = OverlayStylePreset.vibrant.colors[1]
        customEndColor = OverlayStylePreset.vibrant.colors[2]
    }

    private func persistPreset() {
        defaults.set(selectedPreset.rawValue, forKey: Self.presetKey)
    }

    private func persistColor(_ color: NSColor, key: String) {
        defaults.set(color.hexRGBAString, forKey: key)
    }

    private func notifyChange() {
        onChange?(style)
    }

    private static func color(from hexString: String?, fallback: NSColor) -> NSColor {
        guard let hexString, let color = NSColor(hexRGBAString: hexString) else {
            return fallback
        }
        return color
    }
}

private extension NSColor {
    convenience init?(hexRGBAString: String) {
        let cleaned = hexRGBAString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 8,
              let value = UInt32(cleaned, radix: 16) else {
            return nil
        }

        let red = CGFloat((value & 0xFF00_0000) >> 24) / 255
        let green = CGFloat((value & 0x00FF_0000) >> 16) / 255
        let blue = CGFloat((value & 0x0000_FF00) >> 8) / 255
        let alpha = CGFloat(value & 0x0000_00FF) / 255

        self.init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }

    var hexRGBAString: String {
        let color = usingColorSpace(.deviceRGB) ?? self
        let red = Int((color.redComponent * 255).rounded())
        let green = Int((color.greenComponent * 255).rounded())
        let blue = Int((color.blueComponent * 255).rounded())
        let alpha = Int((color.alphaComponent * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
    }
}
