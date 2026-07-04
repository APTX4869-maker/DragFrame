import Foundation

public struct DragCaptureState {
    public private(set) var isCapturingMouseSequence = false

    public init() {}

    @discardableResult
    public mutating func mouseDown(
        modifiers: ModifierShortcut,
        requiredModifiers: ModifierShortcut
    ) -> Bool {
        isCapturingMouseSequence = requiredModifiers.isValid
            && modifiers.contains(requiredModifiers)
        return isCapturingMouseSequence
    }

    public func mouseDragged() -> Bool {
        isCapturingMouseSequence
    }

    @discardableResult
    public mutating func mouseUp() -> Bool {
        defer { isCapturingMouseSequence = false }
        return isCapturingMouseSequence
    }

    public mutating func cancel() {
        isCapturingMouseSequence = false
    }
}
