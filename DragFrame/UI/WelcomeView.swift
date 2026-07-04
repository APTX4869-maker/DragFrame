import DragFrameCore
import SwiftUI

struct WelcomeView: View {
    @ObservedObject var permission: InputMonitoringPermission
    @ObservedObject var shortcutSettings: ShortcutSettings
    let openPrivacySettings: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            VStack(alignment: .leading, spacing: 16) {
                onboardingRow(
                    symbol: "rectangle.dashed",
                    title: "框选屏幕重点",
                    detail: "按住快捷键并拖动鼠标左键，即可在任何应用上方显示内部透明的渐变方框。"
                )

                onboardingRow(
                    symbol: permission.isAuthorized ? "checkmark.shield.fill" : "hand.raised.fill",
                    title: "需要输入监控权限",
                    detail: "DragFrame 只读取修饰键和鼠标拖动，用来显示方框并避免底层内容被误选中，不会保存输入内容。"
                )

                onboardingRow(
                    symbol: "cursorarrow.motionlines",
                    title: "试一下",
                    detail: permission.isAuthorized
                        ? "按住 \(shortcutSettings.shortcut.displayString) 并拖动鼠标左键试试看。"
                        : "授权完成后，回到任意应用，按住 \(shortcutSettings.shortcut.displayString) 并拖动鼠标左键。"
                )
            }

            Divider()

            HStack {
                Button("稍后") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(permission.isAuthorized ? "开始使用" : "打开输入监控设置") {
                    if permission.isAuthorized {
                        dismiss()
                    } else {
                        openPrivacySettings()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(width: 560)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("欢迎使用 DragFrame")
                .font(.largeTitle.weight(.semibold))

            Text("一个轻量、安静的 macOS 屏幕重点框选工具。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func onboardingRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
