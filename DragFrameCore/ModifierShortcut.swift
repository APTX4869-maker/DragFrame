import CoreGraphics
import Foundation

public struct ModifierShortcut: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let command = ModifierShortcut(rawValue: 1 << 0)
    public static let option = ModifierShortcut(rawValue: 1 << 1)
    public static let control = ModifierShortcut(rawValue: 1 << 2)
    public static let shift = ModifierShortcut(rawValue: 1 << 3)

    public static let supported: ModifierShortcut = [.command, .option, .shift]
    public static let `default`: ModifierShortcut = [.shift, .option]

    public init(cgEventFlags flags: CGEventFlags) {
        var shortcut: ModifierShortcut = []

        if flags.contains(.maskCommand) { shortcut.insert(.command) }
        if flags.contains(.maskAlternate) { shortcut.insert(.option) }
        if flags.contains(.maskControl) { shortcut.insert(.control) }
        if flags.contains(.maskShift) { shortcut.insert(.shift) }

        self = shortcut
    }

    public var isValid: Bool {
        !isEmpty && isSubset(of: .supported)
    }

    public var displayString: String {
        orderedModifiers.map(\.symbol).joined()
    }

    public var spokenDescription: String {
        orderedModifiers.map(\.name).joined(separator: " + ")
    }

    private var orderedModifiers: [(value: ModifierShortcut, symbol: String, name: String)] {
        [
            (.shift, "⇧", "Shift"),
            (.option, "⌥", "Option"),
            (.command, "⌘", "Command")
        ].filter { contains($0.value) }
    }
}
