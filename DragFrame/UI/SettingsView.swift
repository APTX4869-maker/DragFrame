import AppKit
import DragFrameCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var permission: InputMonitoringPermission
    @ObservedObject var runtimeStatus: RuntimeStatus
    @ObservedObject var launchAtLogin: LaunchAtLoginController
    @ObservedObject var overlayStyleSettings: OverlayStyleSettings
    let openWelcomeGuide: () -> Void
    let openPrivacySettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            GroupBox {
                statusRow
            }

            GroupBox("快捷键") {
                shortcutSection
            }

            GroupBox("启动") {
                launchSection
            }

            GroupBox("外观") {
                appearanceSection
            }

            GroupBox("权限") {
                permissionSection
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 620, height: 640)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DragFrame")
                .font(.largeTitle.weight(.semibold))
            Text("按住快捷键并拖动鼠标左键，在任何应用上方临时框选重点。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var statusRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: runtimeStatus.state.symbolName)
                .font(.system(size: 22, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(runtimeStatus.state.title)
                    .font(.headline)
                Text(runtimeStatus.state.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if runtimeStatus.state.needsPrivacyAction {
                Button("打开输入监控设置") {
                    openPrivacySettings()
                }
            }
        }
        .padding(8)
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                modifierToggle("Option ⌥", modifier: .option)
                modifierToggle("Shift ⇧", modifier: .shift)
                modifierToggle("Command ⌘", modifier: .command)
                Spacer()
                Text(shortcutSettings.shortcut.displayString)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Control 不可用，因为 macOS 会把 Control-click 解释为右键。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("恢复默认") {
                    shortcutSettings.resetToDefault()
                }
                .controlSize(.small)
            }

            if let message = shortcutSettings.validationMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(8)
    }

    private var launchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(
                "登录时自动启动 DragFrame",
                isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                )
            )
            .toggleStyle(.switch)

            Text("适合常驻菜单栏使用；关闭后仍可手动启动应用。")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let errorMessage = launchAtLogin.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(8)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                stylePreview(width: 58, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("边框颜色")
                        .fontWeight(.medium)
                    Text("\(overlayStyleSettings.style.appearanceSummary) · 框内始终透明")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button("恢复默认") {
                    overlayStyleSettings.resetToDefault()
                }
                .controlSize(.small)
            }

            Picker("颜色方案", selection: $overlayStyleSettings.selectedPreset) {
                ForEach(OverlayStylePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)

            if overlayStyleSettings.selectedPreset == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    ColorPicker(
                        "起始颜色",
                        selection: colorBinding(\.customStartColor),
                        supportsOpacity: false
                    )
                    ColorPicker(
                        "中间颜色",
                        selection: colorBinding(\.customMiddleColor),
                        supportsOpacity: false
                    )
                    ColorPicker(
                        "结束颜色",
                        selection: colorBinding(\.customEndColor),
                        supportsOpacity: false
                    )
                }
                .padding(12)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(8)
    }

    private var permissionSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: permission.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(permission.isAuthorized ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(permission.isAuthorized ? "输入监控权限已授予" : "需要输入监控权限")
                    .fontWeight(.medium)
                Text(permission.isAuthorized
                     ? "DragFrame 可以监听全局快捷键拖拽。"
                     : "授予权限后，DragFrame 才能在所有应用中工作。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button("打开欢迎引导") {
                    openWelcomeGuide()
                }

                if !permission.isAuthorized {
                    Button("打开系统设置") {
                        openPrivacySettings()
                    }
                }
            }
            .controlSize(.small)
        }
        .padding(8)
    }

    private var statusColor: Color {
        switch runtimeStatus.state {
        case .ready:
            return .green
        case .paused:
            return .secondary
        case .permissionMissing, .monitorFailed:
            return .orange
        }
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

    private func stylePreview(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                LinearGradient(
                    colors: overlayStyleSettings.style.colors.map(Color.init),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                lineWidth: 4
            )
            .background(.clear)
            .frame(width: width, height: height)
    }

    private func colorBinding(_ keyPath: ReferenceWritableKeyPath<OverlayStyleSettings, NSColor>) -> Binding<Color> {
        Binding(
            get: {
                Color(nsColor: overlayStyleSettings[keyPath: keyPath])
            },
            set: { newValue in
                overlayStyleSettings[keyPath: keyPath] = NSColor(newValue)
            }
        )
    }
}
