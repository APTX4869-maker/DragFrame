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
        openWelcomeGuide: { [weak self] in self?.presentWelcomeGuide(markAsShown: false) },
        openPrivacySettings: { [weak self] in self?.openPrivacySettings() }
    )
    private lazy var welcomeWindowController = WelcomeWindowController(
        permission: permission,
        shortcutSettings: shortcutSettings,
        openPrivacySettings: { [weak self] in self?.openPrivacySettings() }
    )

    private var permissionTimer: Timer?
    private var didPresentRecoveryWindow = false
    private let welcomeGuideKey = "dragFrame.didShowWelcomeGuide"
    private let monitorStartFailureMessage = "macOS 拒绝了 DragFrame 的全局输入监听。通常是旧授权记录绑定了旧签名。请在输入监控中关闭再重新打开 DragFrame，然后重启应用。"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureCallbacks()
        statusController.update(shortcut: shortcutSettings.shortcut)
        overlayController.update(style: overlayStyleSettings.style)
        refreshPermissionState()
        launchAtLogin.refresh()
        startPermissionTimer()
        if !presentWelcomeGuideIfNeeded() {
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

    private func presentWelcomeGuide(markAsShown: Bool) {
        if markAsShown {
            UserDefaults.standard.set(true, forKey: welcomeGuideKey)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.welcomeWindowController.present()
        }
    }

    @discardableResult
    private func presentWelcomeGuideIfNeeded() -> Bool {
        guard !permission.isAuthorized else { return false }
        guard !UserDefaults.standard.bool(forKey: welcomeGuideKey) else {
            presentRecoveryWindowIfNeeded()
            return true
        }

        presentWelcomeGuide(markAsShown: true)
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
