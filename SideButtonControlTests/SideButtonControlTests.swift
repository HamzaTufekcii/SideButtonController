//
//  SideButtonControlTests.swift
//  SideButtonControlTests
//
//  Created by Hamza Tüfekçi on 18.06.2026.
//

import Foundation
import Testing
@testable import SideButtonControl

struct SideButtonControlTests {

    @Test
    @MainActor
    func missingRemapPermissionsPreventStart() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .missing,
                posting: .missing,
                accessibility: .missing
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetection()

        #expect(monitor.startCallCount == 0)
        #expect(permissions.requestRemapCallCount == 1)
        #expect(viewModel.isRunning == false)
        #expect(viewModel.lastErrorMessage == "Remap için Giriş İzleme, Erişilebilirlik ve event gönderme izinleri gerekiyor.")
    }

    @Test
    @MainActor
    func grantedListeningPermissionStartsMonitor() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetection()

        #expect(monitor.startCallCount == 1)
        #expect(viewModel.isRunning)
        #expect(viewModel.lastErrorMessage == nil)
    }

    @Test
    @MainActor
    func authorizedAutoStartStartsMonitorWithoutRequestingPermissions() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetectionIfAuthorized()

        #expect(monitor.startCallCount == 1)
        #expect(permissions.requestCallCount == 0)
        #expect(permissions.requestRemapCallCount == 0)
        #expect(viewModel.isRunning)
    }

    @Test
    @MainActor
    func missingAutoStartPermissionsDoNotRequestPermissions() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .missing,
                posting: .missing,
                accessibility: .missing
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetectionIfAuthorized()

        #expect(monitor.startCallCount == 0)
        #expect(permissions.requestCallCount == 0)
        #expect(permissions.requestRemapCallCount == 0)
        #expect(viewModel.isRunning == false)
    }

    @Test
    @MainActor
    func receivedEventsArePresentedNewestFirst() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetection()
        monitor.send(
            MouseButtonEvent(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                button: MouseButtonID(rawValue: 3),
                phase: .down,
                uptimeNanoseconds: 1_500_000_000,
                location: MouseLocation(x: 125.4, y: 44.8)
            )
        )

        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.events.count == 1)
        #expect(viewModel.events[0].buttonNumber == "3")
        #expect(viewModel.events[0].phase == "down")
        #expect(viewModel.events[0].timestamp == "1.500s")
        #expect(viewModel.events[0].location == "x 125, y 44")
    }

    @Test
    @MainActor
    func eventListIsCappedAtMaxVisibleEvents() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(
            monitor: monitor,
            permissions: permissions,
            maxVisibleEvents: 3
        )

        viewModel.startDetection()

        for buttonNumber in 1...5 {
            monitor.send(
                MouseButtonEvent(
                    button: MouseButtonID(rawValue: Int64(buttonNumber)),
                    phase: .down,
                    uptimeNanoseconds: UInt64(buttonNumber),
                    location: MouseLocation(x: 0, y: 0)
                )
            )
        }

        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.events.map(\.buttonNumber) == ["5", "4", "3"])
    }

    @Test
    @MainActor
    func stopCancelsDetectionAndStopsMonitor() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetection()
        viewModel.stopDetection()

        #expect(viewModel.isRunning == false)
        #expect(monitor.stopCallCount == 1)
    }

    @Test
    func standardBindingsConsumeBackButtonAndDispatchBackOnDown() {
        let decision = ButtonBindingSet.standard.decision(
            forButton: MouseButtonID(rawValue: 3),
            phase: .down
        )

        #expect(decision.shouldConsumeOriginalEvent)
        #expect(decision.action == .back)
    }

    @Test
    func standardBindingsConsumeForwardButtonAndDispatchForwardOnDown() {
        let decision = ButtonBindingSet.standard.decision(
            forButton: MouseButtonID(rawValue: 4),
            phase: .down
        )

        #expect(decision.shouldConsumeOriginalEvent)
        #expect(decision.action == .forward)
    }

    @Test
    func standardBindingsConsumeSideButtonUpWithoutDispatchingAction() {
        let backDecision = ButtonBindingSet.standard.decision(
            forButton: MouseButtonID(rawValue: 3),
            phase: .up
        )
        let forwardDecision = ButtonBindingSet.standard.decision(
            forButton: MouseButtonID(rawValue: 4),
            phase: .up
        )

        #expect(backDecision.shouldConsumeOriginalEvent)
        #expect(backDecision.action == nil)
        #expect(forwardDecision.shouldConsumeOriginalEvent)
        #expect(forwardDecision.action == nil)
    }

    @Test
    func unboundButtonsPassThrough() {
        let decision = ButtonBindingSet.standard.decision(
            forButton: MouseButtonID(rawValue: 5),
            phase: .down
        )

        #expect(decision.shouldConsumeOriginalEvent == false)
        #expect(decision.action == nil)
    }

    @Test
    func assigningNoneUnbindsAButton() {
        var bindings = ButtonBindingSet.standard
        bindings.setCommand(.none, for: MouseButtonID(rawValue: 3))

        let decision = bindings.decision(forButton: MouseButtonID(rawValue: 3), phase: .down)

        #expect(decision.shouldConsumeOriginalEvent == false)
        #expect(decision.action == nil)
    }

    @Test
    func reassigningButtonChangesDispatchedAction() {
        var bindings = ButtonBindingSet.standard
        bindings.setCommand(.navigateForward, for: MouseButtonID(rawValue: 3))

        let decision = bindings.decision(forButton: MouseButtonID(rawValue: 3), phase: .down)

        #expect(decision.action == .forward)
    }

    @Test
    @MainActor
    func userDefaultsStoreRoundTripsBindings() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsButtonBindingStore(defaults: defaults)

        #expect(store.load() == ButtonBindingSet.standard)

        var bindings = ButtonBindingSet.standard
        bindings.setCommand(.none, for: MouseButtonID(rawValue: 3))
        bindings.setCommand(.navigateBack, for: MouseButtonID(rawValue: 6))
        store.save(bindings)

        #expect(store.load() == bindings)
    }

    @Test
    @MainActor
    func updatingCommandPushesToMonitorAndPersists() {
        let monitor = FakeMouseEventMonitor()
        let store = FakeButtonBindingStore()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(listening: .granted, posting: .granted, accessibility: .granted)
        )
        let useCase = SideButtonDetectionUseCase(
            monitor: monitor,
            permissionChecker: permissions,
            bindingStore: store
        )
        let viewModel = DetectionViewModel(useCase: useCase)

        viewModel.updateCommand(.none, for: MouseButtonID(rawValue: 3))

        #expect(viewModel.bindings.command(for: MouseButtonID(rawValue: 3)) == SideButtonCommand.none)
        #expect(monitor.lastBindings?.command(for: MouseButtonID(rawValue: 3)) == SideButtonCommand.none)
        #expect(store.saved?.command(for: MouseButtonID(rawValue: 3)) == SideButtonCommand.none)
    }

    @Test
    func shortcutRoutingUsesCommandBracketForSafari() {
        let style = CGKeyboardShortcutRoutingPolicy.standard.shortcutStyle(
            for: FrontmostApplication(bundleIdentifier: "com.apple.Safari")
        )

        #expect(style == .commandBracket)
    }

    @Test
    func shortcutRoutingUsesCommandOptionArrowForSpotify() {
        let style = CGKeyboardShortcutRoutingPolicy.standard.shortcutStyle(
            for: FrontmostApplication(bundleIdentifier: "com.spotify.client")
        )

        #expect(style == .commandOptionArrow)
    }

    @Test
    func shortcutRoutingSuppressesUnsupportedApplications() {
        let style = CGKeyboardShortcutRoutingPolicy.standard.shortcutStyle(
            for: FrontmostApplication(bundleIdentifier: "com.example.Unsupported")
        )

        #expect(style == nil)
    }

    @Test
    @MainActor
    func eventsKeepFlowingAfterStopAndRestart() async throws {
        let monitor = FakeMouseEventMonitor()
        let permissions = FakePermissionChecker(
            snapshot: InputPermissionSnapshot(
                listening: .granted,
                posting: .granted,
                accessibility: .granted
            )
        )
        let viewModel = makeViewModel(monitor: monitor, permissions: permissions)

        viewModel.startDetection()
        viewModel.stopDetection()
        viewModel.startDetection()

        monitor.send(
            MouseButtonEvent(
                button: MouseButtonID(rawValue: 4),
                phase: .down,
                uptimeNanoseconds: 1,
                location: MouseLocation(x: 0, y: 0)
            )
        )

        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.events.count == 1)
        #expect(viewModel.events[0].buttonNumber == "4")
    }

    @Test
    func compositeRoutesKeyboardAppsToKeyboardDispatcher() throws {
        let keyboard = RecordingActionDispatcher()
        let gesture = RecordingActionDispatcher()
        let dispatcher = CompositeNavigationActionDispatcher(
            frontmostApplicationProvider: StubFrontmostApplicationProvider(bundleIdentifier: "com.spotify.client"),
            keyboardRoutedBundleIdentifiers: ["com.spotify.client"],
            keyboardDispatcher: keyboard,
            gestureDispatcher: gesture
        )

        try dispatcher.dispatch(.back)

        #expect(keyboard.dispatchedActions == [.back])
        #expect(gesture.dispatchedActions.isEmpty)
    }

    @Test
    func compositeRoutesOtherAppsToGestureDispatcher() throws {
        let keyboard = RecordingActionDispatcher()
        let gesture = RecordingActionDispatcher()
        let dispatcher = CompositeNavigationActionDispatcher(
            frontmostApplicationProvider: StubFrontmostApplicationProvider(bundleIdentifier: "com.apple.Safari"),
            keyboardRoutedBundleIdentifiers: ["com.spotify.client"],
            keyboardDispatcher: keyboard,
            gestureDispatcher: gesture
        )

        try dispatcher.dispatch(.forward)

        #expect(gesture.dispatchedActions == [.forward])
        #expect(keyboard.dispatchedActions.isEmpty)
    }

    @MainActor
    private func makeViewModel(
        monitor: FakeMouseEventMonitor,
        permissions: FakePermissionChecker,
        maxVisibleEvents: Int = 20
    ) -> DetectionViewModel {
        let useCase = SideButtonDetectionUseCase(
            monitor: monitor,
            permissionChecker: permissions
        )
        return DetectionViewModel(useCase: useCase, maxVisibleEvents: maxVisibleEvents)
    }

}

@MainActor
private final class FakeButtonBindingStore: ButtonBindingStoring {
    private(set) var saved: ButtonBindingSet?
    private var stored: ButtonBindingSet

    init(stored: ButtonBindingSet = .standard) {
        self.stored = stored
    }

    func load() -> ButtonBindingSet {
        stored
    }

    func save(_ bindings: ButtonBindingSet) {
        saved = bindings
        stored = bindings
    }
}

@MainActor
private final class FakeMouseEventMonitor: MouseEventMonitoring {
    private var continuation: AsyncStream<MouseButtonEvent>.Continuation?
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastBindings: ButtonBindingSet?

    func setBindings(_ bindings: ButtonBindingSet) {
        lastBindings = bindings
    }

    func makeEventStream() -> AsyncStream<MouseButtonEvent> {
        var captured: AsyncStream<MouseButtonEvent>.Continuation!
        let stream = AsyncStream<MouseButtonEvent> { captured = $0 }
        continuation = captured
        return stream
    }

    func start() throws {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func send(_ event: MouseButtonEvent) {
        continuation?.yield(event)
    }
}

private final class RecordingActionDispatcher: SideButtonActionDispatching, @unchecked Sendable {
    private(set) var dispatchedActions: [SideButtonAction] = []

    func dispatch(_ action: SideButtonAction) throws {
        dispatchedActions.append(action)
    }
}

private struct StubFrontmostApplicationProvider: FrontmostApplicationProviding {
    let bundleIdentifier: String?

    func frontmostApplication() -> FrontmostApplication {
        FrontmostApplication(bundleIdentifier: bundleIdentifier)
    }
}

@MainActor
private final class FakePermissionChecker: InputPermissionChecking {
    private var currentSnapshot: InputPermissionSnapshot
    private(set) var requestCallCount = 0
    private(set) var requestRemapCallCount = 0

    init(snapshot: InputPermissionSnapshot) {
        self.currentSnapshot = snapshot
    }

    func snapshot() -> InputPermissionSnapshot {
        currentSnapshot
    }

    func requestListeningAccess() -> InputPermissionSnapshot {
        requestCallCount += 1
        return currentSnapshot
    }

    func requestRemapAccess() -> InputPermissionSnapshot {
        requestRemapCallCount += 1
        return currentSnapshot
    }
}
