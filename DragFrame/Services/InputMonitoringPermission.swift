import AppKit
import Combine
import CoreGraphics

final class InputMonitoringPermission: ObservableObject {
    @Published private(set) var isAuthorized = CGPreflightListenEventAccess()

    @discardableResult
    func refresh() -> Bool {
        let current = CGPreflightListenEventAccess()
        isAuthorized = current
        return current
    }

    @discardableResult
    func requestAccess() -> Bool {
        let granted = CGRequestListenEventAccess()
        isAuthorized = granted || CGPreflightListenEventAccess()
        return isAuthorized
    }

    func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent"
        ]

        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

