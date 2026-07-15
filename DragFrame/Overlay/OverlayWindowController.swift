import AppKit
import QuartzCore

final class OverlayWindowController {
    private let panel: NSPanel
    private let borderView: GradientBorderView
    private let maskPanel: NSPanel
    private let maskView: SpotlightMaskView
    private var currentStyle: OverlayStyle
    private let fadeOutDuration: TimeInterval = 0.26
    private var animationGeneration = 0

    init(style: OverlayStyle = .default) {
        currentStyle = style
        borderView = GradientBorderView(frame: .zero, style: style)
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.contentView = borderView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .screenSaver
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        panel.sharingType = .none

        maskView = SpotlightMaskView(frame: .zero)
        maskPanel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        maskPanel.contentView = maskView
        maskPanel.isOpaque = false
        maskPanel.backgroundColor = .clear
        maskPanel.hasShadow = false
        maskPanel.ignoresMouseEvents = true
        maskPanel.hidesOnDeactivate = false
        maskPanel.isReleasedWhenClosed = false
        maskPanel.level = .screenSaver
        maskPanel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        maskPanel.sharingType = .none
    }

    func update(style: OverlayStyle) {
        currentStyle = style
        borderView.update(style: style)
    }

    func show(selectionRect: CGRect) {
        guard selectionRect.width > 0, selectionRect.height > 0 else {
            hide()
            return
        }

        animationGeneration += 1

        // 聚光灯遮罩层：绘制在边框之下；透明框模式时隐藏。
        if currentStyle.mode == .spotlight {
            let unionFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
            if unionFrame.width > 0, unionFrame.height > 0 {
                maskPanel.setFrame(unionFrame, display: false)
                maskView.frame = CGRect(origin: .zero, size: unionFrame.size)
                let holeRect = selectionRect.offsetBy(
                    dx: -unionFrame.minX,
                    dy: -unionFrame.minY
                )
                maskView.update(
                    holeRect: holeRect,
                    cornerRadius: currentStyle.cornerRadius,
                    opacity: currentStyle.maskOpacity
                )
                maskPanel.alphaValue = 1
                maskPanel.orderFrontRegardless()
            }
        } else if maskPanel.isVisible {
            maskPanel.orderOut(nil)
        }

        // 渐变边框层：始终显示，叠在遮罩之上。
        panel.alphaValue = 1
        let inset = borderView.contentInset
        let panelFrame = selectionRect.insetBy(dx: -inset, dy: -inset)
        panel.setFrame(panelFrame, display: true)
        borderView.frame = CGRect(origin: .zero, size: panelFrame.size)
        borderView.needsLayout = true
        panel.orderFrontRegardless()
    }

    func hide() {
        let borderVisible = panel.isVisible
        let maskVisible = maskPanel.isVisible

        guard borderVisible || maskVisible else {
            panel.alphaValue = 1
            maskPanel.alphaValue = 1
            return
        }

        animationGeneration += 1
        let currentGeneration = animationGeneration

        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            if borderVisible {
                panel.animator().alphaValue = 0
            }
            if maskVisible {
                maskPanel.animator().alphaValue = 0
            }
        } completionHandler: { [weak self] in
            guard let self else { return }
            guard self.animationGeneration == currentGeneration else { return }

            if borderVisible {
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
            }
            if maskVisible {
                self.maskPanel.orderOut(nil)
                self.maskPanel.alphaValue = 1
            }
        }
    }
}

/// 聚光灯遮罩视图：整屏填充半透明黑，并在选区位置挖出一个圆角透明洞。
private final class SpotlightMaskView: NSView {
    private let maskLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var isOpaque: Bool { false }

    func update(holeRect: CGRect, cornerRadius: CGFloat, opacity: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        maskLayer.frame = bounds

        let path = CGMutablePath()
        path.addRect(bounds)

        if holeRect.width > 0, holeRect.height > 0 {
            let radius = max(0, min(cornerRadius, min(holeRect.width, holeRect.height) / 2))
            let holePath = CGPath(
                roundedRect: holeRect,
                cornerWidth: radius,
                cornerHeight: radius,
                transform: nil
            )
            path.addPath(holePath)
        }

        maskLayer.path = path
        maskLayer.fillColor = NSColor.black.withAlphaComponent(opacity).cgColor

        CATransaction.commit()
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = true
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = NSColor.black.cgColor
        layer?.addSublayer(maskLayer)
    }
}
