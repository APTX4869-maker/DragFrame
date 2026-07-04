import AppKit
import DragFrameCore

final class DragCoordinator: GlobalEventMonitorDelegate {
    var onMonitorStartFailure: (() -> Void)?
    var onMonitorStarted: (() -> Void)?
    var onMonitorRecovered: (() -> Void)?
    var onMonitorRecoveryFailed: (() -> Void)?

    private let monitor: GlobalEventMonitor
    private let overlay: OverlayWindowController
    private var stateMachine: DragStateMachine
    private var captureState = DragCaptureState()
    private var recoveryState = MonitorRecoveryState()
    private var isRestartScheduled = false
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
            guard !recoveryState.shouldSurfaceFailure else {
                onMonitorStartFailure?()
                return
            }

            if monitor.start() {
                recoveryState.reset()
                onMonitorStarted?()
            } else {
                scheduleMonitorRestart()
            }
        } else {
            monitor.stop()
            captureState.cancel()
            recoveryState.reset()
            isRestartScheduled = false
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

    func globalEventMonitor(
        _ monitor: GlobalEventMonitor,
        wasDisabled reason: MonitorDisableReason,
        recoveredByReenable: Bool
    ) {
        captureState.cancel()
        apply(stateMachine.cancel())

        guard isEnabled else { return }

        if recoveredByReenable {
            recoveryState.reset()
            onMonitorRecovered?()
            return
        }

        scheduleMonitorRestart()
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

    private func scheduleMonitorRestart() {
        guard !isRestartScheduled else { return }

        isRestartScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.isRestartScheduled = false

            guard self.isEnabled else { return }

            if self.monitor.restart() {
                self.recoveryState.reset()
                self.onMonitorRecovered?()
            } else {
                self.recoveryState.recordRestartFailure()

                if self.recoveryState.shouldSurfaceFailure {
                    self.onMonitorRecoveryFailed?()
                } else {
                    self.scheduleMonitorRestart()
                }
            }
        }
    }
}
