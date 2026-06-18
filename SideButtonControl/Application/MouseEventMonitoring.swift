import Foundation

enum MouseEventMonitorError: Error, Equatable, Sendable {
    case eventTapCreationFailed
    case runLoopSourceCreationFailed

    var userMessage: String {
        switch self {
        case .eventTapCreationFailed:
            "Event tap could not be created. Check Input Monitoring permission and sandbox settings."
        case .runLoopSourceCreationFailed:
            "Event tap run loop source could not be created."
        }
    }
}

nonisolated protocol SideButtonActionDispatching: Sendable {
    func dispatch(_ action: SideButtonAction) throws
}

nonisolated struct FrontmostApplication: Equatable, Sendable {
    let bundleIdentifier: String?
}

nonisolated protocol FrontmostApplicationProviding: Sendable {
    func frontmostApplication() -> FrontmostApplication
}

protocol MouseEventMonitoring: AnyObject {
    /// Returns a fresh event stream each call. The monitor redirects emitted events to
    /// the most recent stream, so re-subscribing (e.g. after stop/start) stays live.
    func makeEventStream() -> AsyncStream<MouseButtonEvent>

    func start() throws
    func stop()
    func setEventsObserved(_ observed: Bool)

    /// Updates the button assignments the running tap applies, taking effect immediately.
    func setBindings(_ bindings: ButtonBindingSet)
}

extension MouseEventMonitoring {
    func setEventsObserved(_ observed: Bool) {}
    func setBindings(_ bindings: ButtonBindingSet) {}
}

protocol InputPermissionChecking: AnyObject {
    func snapshot() -> InputPermissionSnapshot
    func requestListeningAccess() -> InputPermissionSnapshot
    func requestRemapAccess() -> InputPermissionSnapshot
}

protocol InputPermissionSettingsOpening: AnyObject {
    @discardableResult
    func openListeningSettings() -> Bool
}
