import AppKit

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
}
