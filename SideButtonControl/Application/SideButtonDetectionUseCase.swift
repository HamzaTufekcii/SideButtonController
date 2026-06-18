@MainActor
final class SideButtonDetectionUseCase {
    private let monitor: any MouseEventMonitoring
    private let permissionChecker: any InputPermissionChecking
    private let settingsOpener: (any InputPermissionSettingsOpening)?
    private let bindingStore: (any ButtonBindingStoring)?
    private(set) var bindings: ButtonBindingSet

    init(
        monitor: any MouseEventMonitoring,
        permissionChecker: any InputPermissionChecking,
        settingsOpener: (any InputPermissionSettingsOpening)? = nil,
        bindingStore: (any ButtonBindingStoring)? = nil
    ) {
        self.monitor = monitor
        self.permissionChecker = permissionChecker
        self.settingsOpener = settingsOpener
        self.bindingStore = bindingStore
        self.bindings = bindingStore?.load() ?? .standard
        monitor.setBindings(self.bindings)
    }

    func updateCommand(_ command: SideButtonCommand, for button: MouseButtonID) {
        bindings.setCommand(command, for: button)
        monitor.setBindings(bindings)
        bindingStore?.save(bindings)
    }

    func makeEventStream() -> AsyncStream<MouseButtonEvent> {
        monitor.makeEventStream()
    }

    func permissionSnapshot() -> InputPermissionSnapshot {
        permissionChecker.snapshot()
    }

    func requestListeningAccess() -> InputPermissionSnapshot {
        permissionChecker.requestListeningAccess()
    }

    func requestRemapAccess() -> InputPermissionSnapshot {
        permissionChecker.requestRemapAccess()
    }

    @discardableResult
    func openListeningSettings() -> Bool {
        settingsOpener?.openListeningSettings() ?? false
    }

    func setEventsObserved(_ observed: Bool) {
        monitor.setEventsObserved(observed)
    }

    func startDetection() throws {
        try monitor.start()
    }

    func stopDetection() {
        monitor.stop()
    }
}
