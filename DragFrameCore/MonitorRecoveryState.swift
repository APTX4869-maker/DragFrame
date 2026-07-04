import Foundation

public struct MonitorRecoveryState: Equatable {
    public let maxRestartAttempts: Int
    public private(set) var restartFailureCount: Int

    public init(maxRestartAttempts: Int = 3, restartFailureCount: Int = 0) {
        self.maxRestartAttempts = max(1, maxRestartAttempts)
        self.restartFailureCount = max(0, restartFailureCount)
    }

    public var shouldSurfaceFailure: Bool {
        restartFailureCount >= maxRestartAttempts
    }

    public mutating func recordRestartFailure() {
        restartFailureCount += 1
    }

    public mutating func reset() {
        restartFailureCount = 0
    }
}
