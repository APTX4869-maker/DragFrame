import AppKit
import DragFrameCore

final class StatusItemController: NSObject {
    var onEnabledChanged: ((Bool) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenPrivacySettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let enabledItem = NSMenuItem()
    private let shortcutItem = NSMenuItem()
    private let permissionMessageItem = NSMenuItem()
    private let privacySettingsItem = NSMenuItem()

    private(set) var isEnabled = true

    override init() {
        super.init()
        configureStatusItem()
        configureMenu()
    }

    func update(shortcut: ModifierShortcut) {
        shortcutItem.title = "当前快捷键：\(shortcut.displayString)"
    }

    func update(permissionGranted: Bool) {
        permissionMessageItem.isHidden = permissionGranted
        privacySettingsItem.isHidden = permissionGranted

        let symbolName = permissionGranted ? "rectangle.dashed" : "exclamationmark.rectangle"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "DragFrame")
        statusItem.button?.toolTip = permissionGranted
            ? "DragFrame 已就绪"
            : "DragFrame 需要输入监控权限"
    }

    func showMonitorStartFailure() {
        permissionMessageItem.title = "无法启动输入监听"
        permissionMessageItem.isHidden = false
        privacySettingsItem.isHidden = false
        statusItem.button?.image = NSImage(
            systemSymbolName: "exclamationmark.rectangle",
            accessibilityDescription: "DragFrame 监听失败"
        )
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "rectangle.dashed",
            accessibilityDescription: "DragFrame"
        )
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        enabledItem.title = "启用 DragFrame"
        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        enabledItem.state = .on
        enabledItem.isEnabled = true
        menu.addItem(enabledItem)

        shortcutItem.title = "当前快捷键：⌃⌥"
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(.separator())

        permissionMessageItem.title = "需要输入监控权限"
        permissionMessageItem.isEnabled = false
        permissionMessageItem.isHidden = true
        menu.addItem(permissionMessageItem)

        privacySettingsItem.title = "打开系统设置…"
        privacySettingsItem.target = self
        privacySettingsItem.action = #selector(openPrivacySettings)
        privacySettingsItem.isEnabled = true
        privacySettingsItem.isHidden = true
        menu.addItem(privacySettingsItem)

        let settingsItem = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 DragFrame", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enabledItem.state = isEnabled ? .on : .off
        onEnabledChanged?(isEnabled)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func openPrivacySettings() {
        onOpenPrivacySettings?()
    }

    @objc private func quit() {
        onQuit?()
    }
}

