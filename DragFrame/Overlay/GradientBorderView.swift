import AppKit
import QuartzCore

final class GradientBorderView: NSView {
    static let contentInset = OverlayStyle.default.contentInset

    private let gradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()
    private var style: OverlayStyle

    init(frame frameRect: NSRect, style: OverlayStyle = .default) {
        self.style = style
        super.init(frame: frameRect)
        configureLayers()
    }

    required init?(coder: NSCoder) {
        style = .default
        super.init(coder: coder)
        configureLayers()
    }

    override var isOpaque: Bool { false }

    var contentInset: CGFloat {
        style.contentInset
    }

    func update(style: OverlayStyle) {
        self.style = style
        applyStyle()
        needsLayout = true
    }

    override func layout() {
        super.layout()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        gradientLayer.frame = bounds
        borderMaskLayer.frame = bounds

        let lineWidth = style.lineWidth
        let rect = bounds.insetBy(
            dx: style.contentInset + lineWidth / 2,
            dy: style.contentInset + lineWidth / 2
        )
        let radius = max(0, min(style.cornerRadius, min(rect.width, rect.height) / 2))
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        borderMaskLayer.path = path
        borderMaskLayer.lineWidth = lineWidth

        CATransaction.commit()
    }

    private func configureLayers() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        borderMaskLayer.fillColor = nil
        borderMaskLayer.strokeColor = NSColor.white.cgColor
        borderMaskLayer.lineCap = .round
        borderMaskLayer.lineJoin = .round

        applyStyle()
        gradientLayer.mask = borderMaskLayer

        layer?.addSublayer(gradientLayer)
    }

    private func applyStyle() {
        gradientLayer.colors = style.colors.map(\.cgColor)
        gradientLayer.locations = style.locations
        gradientLayer.startPoint = style.startPoint
        gradientLayer.endPoint = style.endPoint
    }
}
