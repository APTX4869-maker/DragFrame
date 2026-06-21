import CoreGraphics
import DragFrameCore
import Foundation

protocol GlobalEventMonitorDelegate: AnyObject {
    func globalEventMonitor(_ monitor: GlobalEventMonitor, received event: MonitoredInputEvent)
    func globalEventMonitorWasDisabled(_ monitor: GlobalEventMonitor)
}

enum MonitoredInputEvent {
    case leftMouseDown(point: CGPoint, modifiers: ModifierShortcut)
    case leftMouseDragged(point: CGPoint, modifiers: ModifierShortcut)
    case leftMouseUp
    case flagsChanged(modifiers: ModifierShortcut)
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
            options: .listenOnly,
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

    fileprivate func receive(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            delegate?.globalEventMonitorWasDisabled(self)
            return
        }

        let modifiers = ModifierShortcut(cgEventFlags: event.flags)

        switch type {
        case .leftMouseDown:
            delegate?.globalEventMonitor(
                self,
                received: .leftMouseDown(point: event.location, modifiers: modifiers)
            )
        case .leftMouseDragged:
            delegate?.globalEventMonitor(
                self,
                received: .leftMouseDragged(point: event.location, modifiers: modifiers)
            )
        case .leftMouseUp:
            delegate?.globalEventMonitor(self, received: .leftMouseUp)
        case .flagsChanged:
            delegate?.globalEventMonitor(self, received: .flagsChanged(modifiers: modifiers))
        default:
            break
        }
    }

    deinit {
        stop()
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
    monitor.receive(type: type, event: event)
    return Unmanaged.passUnretained(event)
}

