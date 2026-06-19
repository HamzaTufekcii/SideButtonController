import Foundation

nonisolated struct ExternalDisplaySnapshot: Equatable, Sendable {
    let hasExternalDisplay: Bool
}

@MainActor
protocol ExternalDisplayMonitoring: AnyObject {
    func currentSnapshot() -> ExternalDisplaySnapshot
    func start(onChange: @escaping @MainActor (ExternalDisplaySnapshot) -> Void)
    func stop()
}
