import Combine
import Foundation

final class RuntimeStatus: ObservableObject {
    @Published private(set) var monitorErrorMessage: String?

    func reportMonitorFailure(_ message: String) {
        monitorErrorMessage = message
    }

    func clearMonitorFailure() {
        monitorErrorMessage = nil
    }
}
