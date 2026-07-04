import DragFrameCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var permission: InputMonitoringPermission
    @ObservedObject var runtimeStatus: RuntimeStatus
    let openPrivacySettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DragFrame 设置")
                    .font(.title2.weight(.semibold))
                Text("按住快捷键并拖动鼠标左键，即可显示全局渐变方框。")
                    .foregroundStyle(.secondary)
            }

            GroupBox("触发快捷键") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        modifierToggle("Option ⌥", modifier: .option)
                        modifierToggle("Shift ⇧", modifier: .shift)
                        modifierToggle("Command ⌘", modifier: .command)
                    }

                    Text("Control 不可用，因为 macOS 会把 Control-click 解释为右键。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("当前组合")
                            .foregroundStyle(.secondary)
                        Text(shortcutSettings.shortcut.displayString)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                        Spacer()
                        Button("恢复默认") {
                            shortcutSettings.resetToDefault()
                        }
                    }

                    if let message = shortcutSettings.validationMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
                .padding(8)
            }

            if let message = runtimeStatus.monitorErrorMessage {
                GroupBox("需要处理") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DragFrame 还不能在所有应用中生效")
                                .fontWeight(.medium)
                            Text(message)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("打开输入监控设置") {
                                openPrivacySettings()
                            }
                            .padding(.top, 2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                }
            }

            GroupBox("系统权限") {
                HStack(spacing: 12) {
                    Image(systemName: permission.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permission.isAuthorized ? .green : .orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(permission.isAuthorized ? "输入监控权限已授予" : "需要输入监控权限")
                            .fontWeight(.medium)
                        Text(permission.isAuthorized
                             ? "DragFrame 可以监听全局拖拽。"
                             : "授予权限后，DragFrame 才能在所有应用中工作。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !permission.isAuthorized {
                        Button("打开系统设置") {
                            openPrivacySettings()
                        }
                    }
                }
                .padding(8)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 560, height: 460)
    }

    private func modifierToggle(_ title: String, modifier: ModifierShortcut) -> some View {
        Toggle(
            title,
            isOn: Binding(
                get: { shortcutSettings.shortcut.contains(modifier) },
                set: { shortcutSettings.set(modifier, enabled: $0) }
            )
        )
        .toggleStyle(.checkbox)
    }
}
