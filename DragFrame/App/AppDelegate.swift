import AppKit
import DragFrameCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shortcutSettings = ShortcutSettings()
    private let permission = InputMonitoringPermission()
    private let runtimeStatus = RuntimeStatus()
    private lazy var coordinator = DragCoordinator(shortcut: shortcutSettings.shortcut)
    private lazy var statusController = StatusItemController()
    private lazy var settingsWindowController = SettingsWindowController(
        shortcutSettings: shortcutSettings,
        permission: permission,
        runtimeStatus: runtimeStatus,
        openPrivacySettings: { [weak self] in self?.openPrivacySettings() }
    )

    private var permissionTimer: Timer?
    private var didPresentRecoveryWindow = false
    private let explanationKey = "dragFrame.didExplainInputMonitoring"
    private let missingPermissionMessage = "当前版本的 DragFrame 还没有可用的输入监控权限。请在系统设置 → 隐私与安全性 → 输入监控 中打开 DragFrame；如果它已经打开，请先关闭再重新打开。"
    private let monitorStartFailureMessage = "macOS 拒绝了 DragFrame 的全局输入监听。通常是旧授权记录绑定了旧签名。请在输入监控中关闭再重新打开 DragFrame，然后重启应用。"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureCallbacks()
        statusController.update(shortcut: shortcutSettings.shortcut)
        refreshPermissionState()
        startPermissionTimer()
        if !presentPermissionExplanationIfNeeded() {
            presentRecoveryWindowIfNeeded()
        }
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
            guard let self else { return }
            self.runtimeStatus.reportMonitorFailure(self.monitorStartFailureMessage)
            self.statusController.showMonitorStartFailure()
            self.presentRecoveryWindowIfNeeded()
        }

        coordinator.onMonitorStarted = { [weak self] in
            guard let self else { return }
            self.runtimeStatus.clearMonitorFailure()
            self.didPresentRecoveryWindow = false
            self.statusController.update(permissionGranted: self.permission.isAuthorized)
        }
    }

    private func refreshPermissionState() {
        let granted = permission.refresh()
        if granted {
            runtimeStatus.clearMonitorFailure()
        } else {
            runtimeStatus.reportMonitorFailure(missingPermissionMessage)
        }
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

    @discardableResult
    private func presentPermissionExplanationIfNeeded() -> Bool {
        guard !permission.isAuthorized else { return false }
        guard !UserDefaults.standard.bool(forKey: explanationKey) else {
            presentRecoveryWindowIfNeeded()
            return true
        }

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
                self.presentRecoveryWindowIfNeeded()
            }
        }

        return true
    }

    private func presentRecoveryWindowIfNeeded() {
        guard !permission.isAuthorized || runtimeStatus.monitorErrorMessage != nil else { return }
        guard !didPresentRecoveryWindow else { return }

        didPresentRecoveryWindow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.settingsWindowController.present()
        }
    }

    private func openPrivacySettings() {
        if !permission.requestAccess() {
            permission.openSystemSettings()
        }
        refreshPermissionState()
    }
}
