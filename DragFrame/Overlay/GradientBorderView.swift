import AppKit
import QuartzCore

final class GradientBorderView: NSView {
    static let contentInset: CGFloat = 14

    private let gradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()
    private let shadowLayer = CAShapeLayer()

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
        shadowLayer.frame = bounds
        borderMaskLayer.frame = bounds

        let lineWidth: CGFloat = 3
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
        shadowLayer.path = path
        shadowLayer.lineWidth = lineWidth
        shadowLayer.shadowPath = path

        CATransaction.commit()
    }

    private func configureLayers() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        shadowLayer.fillColor = NSColor.clear.cgColor
        shadowLayer.strokeColor = NSColor.systemPurple.withAlphaComponent(0.38).cgColor
        shadowLayer.shadowColor = NSColor.systemPurple.cgColor
        shadowLayer.shadowOpacity = 0.24
        shadowLayer.shadowRadius = 8
        shadowLayer.shadowOffset = .zero
        shadowLayer.masksToBounds = false

        borderMaskLayer.fillColor = NSColor.clear.cgColor
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

        layer?.addSublayer(shadowLayer)
        layer?.addSublayer(gradientLayer)
    }
}

