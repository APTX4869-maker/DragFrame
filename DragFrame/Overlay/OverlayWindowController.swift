import AppKit

final class OverlayWindowController {
    private let panel: NSPanel
    private let borderView: GradientBorderView

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

        let inset = borderView.contentInset
        let panelFrame = selectionRect.insetBy(dx: -inset, dy: -inset)
        panel.setFrame(panelFrame, display: true)
        borderView.frame = CGRect(origin: .zero, size: panelFrame.size)
        borderView.needsLayout = true
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}
