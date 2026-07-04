import Combine
import Foundation

enum RuntimeState: Equatable {
    case ready
    case paused
    case permissionMissing(message: String)
    case monitorFailed(message: String)

    var title: String {
        switch self {
        case .ready:
            return "已就绪"
        case .paused:
            return "已暂停"
        case .permissionMissing:
            return "需要输入监控权限"
        case .monitorFailed:
            return "输入监听未启动"
        }
    }

    var detail: String {
        switch self {
        case .ready:
            return "按住快捷键并拖动鼠标左键，即可显示全局渐变方框。"
        case .paused:
            return "DragFrame 当前已暂停，不会监听或接管拖拽。"
        case let .permissionMissing(message):
            return message
        case let .monitorFailed(message):
            return message
        }
    }

    var symbolName: String {
        switch self {
        case .ready:
            return "rectangle.dashed"
        case .paused:
            return "pause.rectangle"
        case .permissionMissing:
            return "exclamationmark.rectangle"
        case .monitorFailed:
            return "exclamationmark.rectangle"
        }
    }

    var needsPrivacyAction: Bool {
        switch self {
        case .permissionMissing, .monitorFailed:
            return true
        case .ready, .paused:
            return false
        }
    }
}

final class RuntimeStatus: ObservableObject {
    static let defaultPermissionMessage = "当前版本的 DragFrame 还没有可用的输入监控权限。请在系统设置 → 隐私与安全性 → 输入监控 中打开 DragFrame；如果它已经打开，请先关闭再重新打开。"

    @Published private(set) var monitorErrorMessage: String?
    @Published private(set) var state: RuntimeState = .permissionMissing(message: RuntimeStatus.defaultPermissionMessage)

    func reportMonitorFailure(_ message: String) {
        monitorErrorMessage = message
    }

    func clearMonitorFailure() {
        monitorErrorMessage = nil
    }

    func update(enabled: Bool, permissionGranted: Bool) {
        if !enabled {
            state = .paused
            return
        }

        if !permissionGranted {
            state = .permissionMissing(message: monitorErrorMessage ?? Self.defaultPermissionMessage)
            return
        }

        if let monitorErrorMessage {
            state = .monitorFailed(message: monitorErrorMessage)
            return
        }

        state = .ready
    }
}
