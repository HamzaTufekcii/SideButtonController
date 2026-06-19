import Foundation
import Observation

nonisolated struct DetectedMouseEventViewData: Identifiable, Equatable {
    let id: UUID
    let buttonNumber: String
    let phase: String
    let timestamp: String
    let location: String

    init(event: MouseButtonEvent) {
        self.id = event.id
        self.buttonNumber = event.button.description
        self.phase = event.phase.rawValue
        self.timestamp = String(format: "%.3fs", Double(event.uptimeNanoseconds) / 1_000_000_000)
        self.location = "x \(Int(event.location.x)), y \(Int(event.location.y))"
    }
}

@MainActor
@Observable
final class DetectionViewModel {
    private let useCase: SideButtonDetectionUseCase
    private let maxVisibleEvents: Int
    private var eventTask: Task<Void, Never>?

    private(set) var permissionSnapshot: InputPermissionSnapshot = .unknown
    private(set) var isRunning = false
    private(set) var isExternalDisplayAvailable = true
    private(set) var events: [DetectedMouseEventViewData] = []
    private(set) var lastErrorMessage: String?
    private(set) var bindings: ButtonBindingSet

    init(useCase: SideButtonDetectionUseCase, maxVisibleEvents: Int = 20) {
        self.useCase = useCase
        self.maxVisibleEvents = maxVisibleEvents
        self.bindings = useCase.bindings
    }

    func updateCommand(_ command: SideButtonCommand, for button: MouseButtonID) {
        useCase.updateCommand(command, for: button)
        bindings = useCase.bindings
    }

    var canStartDetection: Bool {
        !isRunning && isExternalDisplayAvailable
    }

    var futureRemapSummary: String {
        "AX \(label(for: permissionSnapshot.accessibility)) / Event Post \(label(for: permissionSnapshot.posting))"
    }

    var remapPermissionState: InputPermissionState {
        permissionSnapshot.canRemap ? .granted : .missing
    }

    func refreshPermissions() {
        permissionSnapshot = useCase.permissionSnapshot()
    }

    func setExternalDisplayAvailable(_ available: Bool) {
        isExternalDisplayAvailable = available
        if !available {
            lastErrorMessage = nil
        }
    }

    /// Diagnostics feed is only needed while the window is visible. Gating it keeps the
    /// event-tap callback from building view data on every click in the background.
    func beginEventObservation() {
        useCase.setEventsObserved(true)
    }

    func endEventObservation() {
        useCase.setEventsObserved(false)
    }

    func requestListeningPermission() {
        permissionSnapshot = useCase.requestRemapAccess()
        if !permissionSnapshot.canRemap {
            lastErrorMessage = missingRemapPermissionMessage
        }
    }

    func startDetectionIfAuthorized() {
        guard isExternalDisplayAvailable else {
            return
        }

        refreshPermissions()

        guard permissionSnapshot.canRemap else {
            lastErrorMessage = missingRemapPermissionMessage
            return
        }

        startMonitoring()
    }

    func startDetection() {
        guard isExternalDisplayAvailable else {
            lastErrorMessage = "Harici ekran bağlı değil."
            return
        }

        refreshPermissions()

        if !permissionSnapshot.canRemap {
            permissionSnapshot = useCase.requestRemapAccess()
            guard permissionSnapshot.canRemap else {
                lastErrorMessage = missingRemapPermissionMessage
                return
            }
        }

        startMonitoring()
    }

    private func startMonitoring() {
        do {
            try useCase.startDetection()
            isRunning = true
            lastErrorMessage = nil
            bindEvents()
        } catch let error as MouseEventMonitorError {
            isRunning = false
            lastErrorMessage = error.userMessage
        } catch {
            isRunning = false
            lastErrorMessage = error.localizedDescription
        }
    }

    func stopDetection() {
        eventTask?.cancel()
        eventTask = nil
        useCase.stopDetection()
        isRunning = false
    }

    func suspendDetection() {
        useCase.setEventsObserved(false)
        stopDetection()
        clearEvents()
        lastErrorMessage = nil
    }

    func clearEvents() {
        events.removeAll()
    }

    func openInputMonitoringSettings() {
        if !useCase.openListeningSettings() {
            lastErrorMessage = "Giriş İzleme ayarları açılamadı."
        }
    }

    private func bindEvents() {
        eventTask?.cancel()
        let stream = useCase.makeEventStream()
        eventTask = Task { @MainActor [weak self] in
            for await event in stream {
                guard let self, !Task.isCancelled else {
                    return
                }
                self.record(event)
            }
        }
    }

    private func record(_ event: MouseButtonEvent) {
        events.insert(DetectedMouseEventViewData(event: event), at: 0)
        if events.count > maxVisibleEvents {
            events.removeLast(events.count - maxVisibleEvents)
        }
    }

    private func label(for state: InputPermissionState) -> String {
        switch state {
        case .unknown:
            "Bilinmiyor"
        case .granted:
            "Verildi"
        case .missing:
            "Eksik"
        }
    }

    private var missingRemapPermissionMessage: String {
        "Remap için Giriş İzleme, Erişilebilirlik ve event gönderme izinleri gerekiyor."
    }
}
