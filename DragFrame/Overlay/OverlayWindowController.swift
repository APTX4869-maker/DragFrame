import AppKit
import QuartzCore

final class OverlayWindowController {
    private let panel: NSPanel
    private let borderView: GradientBorderView
    private let fadeOutDuration: TimeInterval = 0.26
    private var animationGeneration = 0

    init(style: OverlayStyle = .default) {
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
    }

    func update(style: OverlayStyle) {
        borderView.update(style: style)
    }

    func show(selectionRect: CGRect) {
        guard selectionRect.width > 0, selectionRect.height > 0 else {
            hide()
            return
        }

        animationGeneration += 1
        panel.alphaValue = 1

        let inset = borderView.contentInset
        let panelFrame = selectionRect.insetBy(dx: -inset, dy: -inset)
        panel.setFrame(panelFrame, display: true)
        borderView.frame = CGRect(origin: .zero, size: panelFrame.size)
        borderView.needsLayout = true
        panel.orderFrontRegardless()
    }

    func hide() {
        guard panel.isVisible else {
            panel.alphaValue = 1
            return
        }

        animationGeneration += 1
        let currentGeneration = animationGeneration

        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self else { return }
            guard self.animationGeneration == currentGeneration else { return }

            self.panel.orderOut(nil)
            self.panel.alphaValue = 1
        }
    }
}
