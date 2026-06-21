import AppKit
import DragFrameCore

final class DragCoordinator: GlobalEventMonitorDelegate {
    var onMonitorStartFailure: (() -> Void)?

    private let monitor: GlobalEventMonitor
    private let overlay: OverlayWindowController
    private var stateMachine: DragStateMachine
    private(set) var isEnabled = true

    init(
        shortcut: ModifierShortcut,
        monitor: GlobalEventMonitor = GlobalEventMonitor(),
        overlay: OverlayWindowController = OverlayWindowController()
    ) {
        self.monitor = monitor
        self.overlay = overlay
        stateMachine = DragStateMachine(requiredModifiers: shortcut)
        monitor.delegate = self
    }

    func setEnabled(_ enabled: Bool, permissionGranted: Bool) {
        isEnabled = enabled

        if enabled && permissionGranted {
            if !monitor.start() {
                onMonitorStartFailure?()
            }
        } else {
            monitor.stop()
            apply(stateMachine.cancel())
        }
    }

    func updatePermission(granted: Bool) {
        setEnabled(isEnabled, permissionGranted: granted)
    }

    func updateShortcut(_ shortcut: ModifierShortcut) {
        apply(stateMachine.cancel())
        stateMachine.requiredModifiers = shortcut
    }

    func globalEventMonitor(_ monitor: GlobalEventMonitor, received event: MonitoredInputEvent) {
        guard isEnabled else { return }

        switch event {
        case let .leftMouseDown(point, modifiers):
            apply(stateMachine.mouseDown(at: appKitPoint(from: point), modifiers: modifiers))

        case let .leftMouseDragged(point, modifiers):
            apply(stateMachine.mouseDragged(to: appKitPoint(from: point), modifiers: modifiers))

        case .leftMouseUp:
            apply(stateMachine.mouseUp())

        case let .flagsChanged(modifiers):
            apply(stateMachine.flagsChanged(to: modifiers))
        }
    }

    func globalEventMonitorWasDisabled(_ monitor: GlobalEventMonitor) {
        apply(stateMachine.cancel())
    }

    private func appKitPoint(from quartzPoint: CGPoint) -> CGPoint {
        let primaryScreenMaxY = NSScreen.screens.first?.frame.maxY ?? 0
        return CoordinateConverter.appKitPoint(
            fromQuartz: quartzPoint,
            primaryScreenMaxY: primaryScreenMaxY
        )
    }

    private func apply(_ output: DragStateMachine.Output) {
        switch output {
        case .none:
            break
        case let .show(rect):
            overlay.show(selectionRect: rect)
        case .hide:
            overlay.hide()
        }
    }
}
