import CoreGraphics
import Foundation

public struct DragStateMachine {
    public enum Output: Equatable {
        case none
        case show(CGRect)
        case hide
    }

    private enum State {
        case idle
        case pressed(origin: CGPoint)
        case dragging(origin: CGPoint)
    }

    public var requiredModifiers: ModifierShortcut
    public var movementThreshold: CGFloat

    private var state: State = .idle

    public init(
        requiredModifiers: ModifierShortcut = .default,
        movementThreshold: CGFloat = 3
    ) {
        self.requiredModifiers = requiredModifiers
        self.movementThreshold = movementThreshold
    }

    public mutating func mouseDown(
        at point: CGPoint,
        modifiers: ModifierShortcut
    ) -> Output {
        guard modifiers.contains(requiredModifiers), requiredModifiers.isValid else {
            state = .idle
            return .none
        }

        state = .pressed(origin: point)
        return .none
    }

    public mutating func mouseDragged(
        to point: CGPoint,
        modifiers: ModifierShortcut
    ) -> Output {
        guard modifiers.contains(requiredModifiers) else {
            return cancel()
        }

        switch state {
        case .idle:
            return .none

        case let .pressed(origin):
            guard distance(from: origin, to: point) > movementThreshold else {
                return .none
            }

            state = .dragging(origin: origin)
            return .show(Self.normalizedRect(from: origin, to: point))

        case let .dragging(origin):
            return .show(Self.normalizedRect(from: origin, to: point))
        }
    }

    public mutating func mouseUp() -> Output {
        defer { state = .idle }

        if case .dragging = state {
            return .hide
        }

        return .none
    }

    public mutating func flagsChanged(to modifiers: ModifierShortcut) -> Output {
        guard !modifiers.contains(requiredModifiers) else {
            return .none
        }

        return cancel()
    }

    public mutating func cancel() -> Output {
        defer { state = .idle }

        if case .dragging = state {
            return .hide
        }

        return .none
    }

    public static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        hypot(end.x - start.x, end.y - start.y)
    }
}

