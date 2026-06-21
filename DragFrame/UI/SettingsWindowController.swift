import AppKit
import DragFrameCore
import SwiftUI

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init(
        shortcutSettings: ShortcutSettings,
        permission: InputMonitoringPermission,
        openPrivacySettings: @escaping () -> Void
    ) {
        let rootView = SettingsView(
            shortcutSettings: shortcutSettings,
            permission: permission,
            openPrivacySettings: openPrivacySettings
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "DragFrame 设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

