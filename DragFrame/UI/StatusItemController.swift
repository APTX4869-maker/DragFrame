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
    private let statusMessageItem = NSMenuItem()
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

    func update(runtimeState: RuntimeState) {
        statusMessageItem.title = "状态：\(runtimeState.title)"
        statusMessageItem.isHidden = false
        privacySettingsItem.isHidden = !runtimeState.needsPrivacyAction

        statusItem.button?.image = statusImage(
            named: runtimeState.symbolName,
            accessibilityDescription: "DragFrame"
        )
        statusItem.button?.toolTip = "DragFrame \(runtimeState.title)"
    }

    func showMonitorStartFailure() {
        update(runtimeState: .monitorFailed(message: "输入监听未启动"))
    }

    private func configureStatusItem() {
        statusItem.button?.image = statusImage(
            named: "rectangle.dashed",
            accessibilityDescription: "DragFrame"
        )
    }

    private func statusImage(named symbolName: String, accessibilityDescription: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription)
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        return image
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

        shortcutItem.title = "当前快捷键：⇧⌥"
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(.separator())

        statusMessageItem.title = "状态：正在检查…"
        statusMessageItem.isEnabled = false
        statusMessageItem.isHidden = false
        menu.addItem(statusMessageItem)

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
