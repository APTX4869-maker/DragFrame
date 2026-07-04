import AppKit
import DragFrameCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shortcutSettings = ShortcutSettings()
    private let permission = InputMonitoringPermission()
    private let runtimeStatus = RuntimeStatus()
    private let launchAtLogin = LaunchAtLoginController()
    private let overlayStyleSettings = OverlayStyleSettings()
    private lazy var overlayController = OverlayWindowController(style: overlayStyleSettings.style)
    private lazy var coordinator = DragCoordinator(
        shortcut: shortcutSettings.shortcut,
        overlay: overlayController
    )
    private lazy var statusController = StatusItemController()
    private lazy var settingsWindowController = SettingsWindowController(
        shortcutSettings: shortcutSettings,
        permission: permission,
        runtimeStatus: runtimeStatus,
        launchAtLogin: launchAtLogin,
        overlayStyleSettings: overlayStyleSettings,
        openPrivacySettings: { [weak self] in self?.openPrivacySettings() }
    )

    private var permissionTimer: Timer?
    private var didPresentRecoveryWindow = false
    private let explanationKey = "dragFrame.didExplainInputMonitoring"
    private let monitorStartFailureMessage = "macOS 拒绝了 DragFrame 的全局输入监听。通常是旧授权记录绑定了旧签名。请在输入监控中关闭再重新打开 DragFrame，然后重启应用。"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureCallbacks()
        statusController.update(shortcut: shortcutSettings.shortcut)
        overlayController.update(style: overlayStyleSettings.style)
        refreshPermissionState()
        launchAtLogin.refresh()
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

        overlayStyleSettings.onChange = { [weak self] style in
            self?.overlayController.update(style: style)
        }

        statusController.onEnabledChanged = { [weak self] enabled in
            guard let self else { return }
            self.coordinator.setEnabled(enabled, permissionGranted: self.permission.isAuthorized)
            self.updateRuntimePresentation()
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
            self.updateRuntimePresentation()
            self.presentRecoveryWindowIfNeeded()
        }

        coordinator.onMonitorStarted = { [weak self] in
            guard let self else { return }
            self.runtimeStatus.clearMonitorFailure()
            self.didPresentRecoveryWindow = false
            self.updateRuntimePresentation()
        }
    }

    private func refreshPermissionState() {
        let granted = permission.refresh()
        if granted {
            runtimeStatus.clearMonitorFailure()
        } else {
            runtimeStatus.reportMonitorFailure(RuntimeStatus.defaultPermissionMessage)
        }
        coordinator.updatePermission(granted: granted)
        updateRuntimePresentation()
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
            alert.informativeText = "DragFrame 会读取修饰键和鼠标拖动，用来显示渐变方框；仅在快捷键框选期间接管这一段左键拖拽，避免底层内容被选中，不会保存输入内容。"
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

    private func updateRuntimePresentation() {
        runtimeStatus.update(
            enabled: statusController.isEnabled,
            permissionGranted: permission.isAuthorized
        )
        statusController.update(runtimeState: runtimeStatus.state)
    }
}
