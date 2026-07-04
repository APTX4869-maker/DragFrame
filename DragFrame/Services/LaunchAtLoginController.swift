import Combine
import Foundation
import ServiceManagement

final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }

            errorMessage = nil
            refresh()
        } catch {
            refresh()
            errorMessage = enabled
                ? "无法添加到登录项。请在系统设置中检查登录项权限。"
                : "无法从登录项移除。请在系统设置中手动关闭。"
        }
    }
}
