import Combine
import Foundation

public final class ShortcutSettings: ObservableObject {
    public static let storageKey = "dragFrame.modifierShortcut"

    @Published public private(set) var shortcut: ModifierShortcut
    @Published public private(set) var validationMessage: String?

    public var onChange: ((ModifierShortcut) -> Void)?

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let stored = defaults.object(forKey: Self.storageKey) as? NSNumber {
            let candidate = ModifierShortcut(rawValue: stored.uintValue)
            shortcut = candidate.isValid ? candidate : .default
        } else {
            shortcut = .default
        }
    }

    @discardableResult
    public func set(_ modifier: ModifierShortcut, enabled: Bool) -> Bool {
        var candidate = shortcut

        if enabled {
            candidate.insert(modifier)
        } else {
            candidate.remove(modifier)
        }

        guard candidate.isValid else {
            validationMessage = "至少需要选择一个修饰键。"
            return false
        }

        save(candidate)
        return true
    }

    public func resetToDefault() {
        save(.default)
    }

    public func clearValidationMessage() {
        validationMessage = nil
    }

    private func save(_ value: ModifierShortcut) {
        shortcut = value
        validationMessage = nil
        defaults.set(NSNumber(value: value.rawValue), forKey: Self.storageKey)
        onChange?(value)
    }
}

