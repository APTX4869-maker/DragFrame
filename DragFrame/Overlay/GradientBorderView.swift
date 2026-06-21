import AppKit
import QuartzCore

final class GradientBorderView: NSView {
    static let contentInset: CGFloat = 14

    private let gradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
    }

    override var isOpaque: Bool { false }

    override func layout() {
        super.layout()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        gradientLayer.frame = bounds
        borderMaskLayer.frame = bounds

        let lineWidth: CGFloat = 6
        let rect = bounds.insetBy(
            dx: Self.contentInset + lineWidth / 2,
            dy: Self.contentInset + lineWidth / 2
        )
        let radius = max(0, min(18, min(rect.width, rect.height) / 2))
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

        gradientLayer.colors = [
            NSColor(calibratedRed: 1.00, green: 0.68, blue: 0.10, alpha: 1).cgColor,
            NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.49, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.43, green: 0.31, blue: 1.00, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.52, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.mask = borderMaskLayer

        layer?.addSublayer(gradientLayer)
    }
}
