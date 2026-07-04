import CoreGraphics
import DragFrameCore
import Foundation

protocol GlobalEventMonitorDelegate: AnyObject {
    func globalEventMonitor(_ monitor: GlobalEventMonitor, received event: MonitoredInputEvent) -> Bool
    func globalEventMonitor(
        _ monitor: GlobalEventMonitor,
        wasDisabled reason: MonitorDisableReason,
        recoveredByReenable: Bool
    )
}

enum MonitoredInputEvent {
    case leftMouseDown(point: CGPoint, modifiers: ModifierShortcut)
    case leftMouseDragged(point: CGPoint, modifiers: ModifierShortcut)
    case leftMouseUp
    case flagsChanged(modifiers: ModifierShortcut)
}

enum MonitorDisableReason {
    case timeout
    case userInput
}

final class GlobalEventMonitor {
    weak var delegate: GlobalEventMonitorDelegate?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool {
        guard let eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    @discardableResult
    func start() -> Bool {
        if isRunning { return true }
        stop()

        let eventTypes: [CGEventType] = [
            .leftMouseDown,
            .leftMouseDragged,
            .leftMouseUp,
            .flagsChanged
        ]
        let eventMask = eventTypes.reduce(CGEventMask(0)) {
            $0 | (CGEventMask(1) << CGEventMask($1.rawValue))
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: globalEventTapCallback,
            userInfo: userInfo
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }

        runLoopSource = nil
        eventTap = nil
    }

    @discardableResult
    func reenable() -> Bool {
        guard let eventTap else { return false }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    @discardableResult
    func restart() -> Bool {
        stop()
        return start()
    }

    fileprivate func receive(type: CGEventType, event: CGEvent) -> Bool {
        if let disableReason = MonitorDisableReason(eventType: type) {
            let recovered = reenable()
            delegate?.globalEventMonitor(
                self,
                wasDisabled: disableReason,
                recoveredByReenable: recovered
            )
            return false
        }

        let modifiers = ModifierShortcut(cgEventFlags: event.flags)

        switch type {
        case .leftMouseDown:
            return delegate?.globalEventMonitor(
                self,
                received: .leftMouseDown(point: event.location, modifiers: modifiers)
            ) ?? false
        case .leftMouseDragged:
            return delegate?.globalEventMonitor(
                self,
                received: .leftMouseDragged(point: event.location, modifiers: modifiers)
            ) ?? false
        case .leftMouseUp:
            return delegate?.globalEventMonitor(self, received: .leftMouseUp) ?? false
        case .flagsChanged:
            return delegate?.globalEventMonitor(
                self,
                received: .flagsChanged(modifiers: modifiers)
            ) ?? false
        default:
            return false
        }
    }

    deinit {
        stop()
    }
}

private extension MonitorDisableReason {
    init?(eventType: CGEventType) {
        switch eventType {
        case .tapDisabledByTimeout:
            self = .timeout
        case .tapDisabledByUserInput:
            self = .userInput
        default:
            return nil
        }
    }
}

private func globalEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let monitor = Unmanaged<GlobalEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    let shouldSuppressEvent = monitor.receive(type: type, event: event)
    return shouldSuppressEvent ? nil : Unmanaged.passUnretained(event)
}
