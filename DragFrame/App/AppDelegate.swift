import AppKit
import DragFrameCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shortcutSettings = ShortcutSettings()
    private let permission = InputMonitoringPermission()
    private lazy var coordinator = DragCoordinator(shortcut: shortcutSettings.shortcut)
    private lazy var statusController = StatusItemController()
    private lazy var settingsWindowController = SettingsWindowController(
        shortcutSettings: shortcutSettings,
        permission: permission,
        openPrivacySettings: { [weak self] in self?.openPrivacySettings() }
    )

    private var permissionTimer: Timer?
    private let explanationKey = "dragFrame.didExplainInputMonitoring"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureCallbacks()
        statusController.update(shortcut: shortcutSettings.shortcut)
        refreshPermissionState()
        startPermissionTimer()
        presentPermissionExplanationIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        coordinator.setEnabled(false, permissionGranted: false)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshPermissionState()
    }

    private func configureCallbacks() {
        shortcutSettings.onChange = { [weak self] shortcut in
            self?.coordinator.updateShortcut(shortcut)
            self?.statusController.update(shortcut: shortcut)
        }

        statusController.onEnabledChanged = { [weak self] enabled in
            guard let self else { return }
            self.coordinator.setEnabled(enabled, permissionGranted: self.permission.isAuthorized)
        }
        statusController.onOpenSettings = { [weak self] in
            self?.settingsWindowController.present()
        }
        statusController.onOpenPrivacySettings = { [weak self] in
            self?.openPrivacySettings()
        }
        statusController.onQuit = {
            NSApp.terminate(nil)
        }

        coordinator.onMonitorStartFailure = { [weak self] in
            self?.statusController.showMonitorStartFailure()
        }
    }

    private func refreshPermissionState() {
        let granted = permission.refresh()
        statusController.update(permissionGranted: granted)
        coordinator.updatePermission(granted: granted)
    }

    private func startPermissionTimer() {
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshPermissionState()
        }
        permissionTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func presentPermissionExplanationIfNeeded() {
        guard !permission.isAuthorized else { return }
        guard !UserDefaults.standard.bool(forKey: explanationKey) else { return }

        UserDefaults.standard.set(true, forKey: explanationKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }

            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "允许 DragFrame 监听拖拽"
            alert.informativeText = "DragFrame 只读取修饰键和鼠标拖动，用来显示渐变方框；不会拦截、修改或保存输入内容。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "继续授权")
            alert.addButton(withTitle: "稍后")

            if alert.runModal() == .alertFirstButtonReturn {
                if !self.permission.requestAccess() {
                    self.permission.openSystemSettings()
                }
                self.refreshPermissionState()
            }
        }
    }

    private func openPrivacySettings() {
        if !permission.requestAccess() {
            permission.openSystemSettings()
        }
        refreshPermissionState()
    }
}

