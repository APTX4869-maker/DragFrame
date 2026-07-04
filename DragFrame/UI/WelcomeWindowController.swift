import AppKit
import DragFrameCore
import SwiftUI

final class WelcomeWindowController: NSWindowController, NSWindowDelegate {
    init(
        permission: InputMonitoringPermission,
        shortcutSettings: ShortcutSettings,
        openPrivacySettings: @escaping () -> Void
    ) {
        let dismissProxy = WelcomeDismissProxy()
        let rootView = WelcomeView(
            permission: permission,
            shortcutSettings: shortcutSettings,
            openPrivacySettings: openPrivacySettings,
            dismiss: {
                dismissProxy.dismiss()
            }
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "欢迎使用 DragFrame"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .unifiedCompact
        window.center()

        super.init(window: window)
        dismissProxy.window = window
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

private final class WelcomeDismissProxy {
    weak var window: NSWindow?

    func dismiss() {
        window?.close()
    }
}
