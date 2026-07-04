import AppKit
import DragFrameCore

final class DragCoordinator: GlobalEventMonitorDelegate {
    var onMonitorStartFailure: (() -> Void)?
    var onMonitorStarted: (() -> Void)?

    private let monitor: GlobalEventMonitor
    private let overlay: OverlayWindowController
    private var stateMachine: DragStateMachine
    private var captureState = DragCaptureState()
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
            if monitor.start() {
                onMonitorStarted?()
            } else {
                onMonitorStartFailure?()
            }
        } else {
            monitor.stop()
            captureState.cancel()
            apply(stateMachine.cancel())
        }
    }

    func updatePermission(granted: Bool) {
        setEnabled(isEnabled, permissionGranted: granted)
    }

    func updateShortcut(_ shortcut: ModifierShortcut) {
        captureState.cancel()
        apply(stateMachine.cancel())
        stateMachine.requiredModifiers = shortcut
    }

    func globalEventMonitor(_ monitor: GlobalEventMonitor, received event: MonitoredInputEvent) -> Bool {
        guard isEnabled else { return false }

        switch event {
        case let .leftMouseDown(point, modifiers):
            let shouldSuppress = captureState.mouseDown(
                modifiers: modifiers,
                requiredModifiers: stateMachine.requiredModifiers
            )
            apply(stateMachine.mouseDown(at: appKitPoint(from: point), modifiers: modifiers))
            return shouldSuppress

        case let .leftMouseDragged(point, modifiers):
            apply(stateMachine.mouseDragged(to: appKitPoint(from: point), modifiers: modifiers))
            return captureState.mouseDragged()

        case .leftMouseUp:
            apply(stateMachine.mouseUp())
            return captureState.mouseUp()

        case let .flagsChanged(modifiers):
            apply(stateMachine.flagsChanged(to: modifiers))
            return false
        }
    }

    func globalEventMonitorWasDisabled(_ monitor: GlobalEventMonitor) {
        captureState.cancel()
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
