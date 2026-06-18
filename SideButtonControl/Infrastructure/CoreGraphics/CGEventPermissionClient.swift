import ApplicationServices
import AppKit
import CoreGraphics

final class CGEventPermissionClient: InputPermissionChecking, InputPermissionSettingsOpening {
    private let accessibilityPromptOption = "AXTrustedCheckOptionPrompt"
    private let inputMonitoringSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
    )!

    func snapshot() -> InputPermissionSnapshot {
        InputPermissionSnapshot(
            listening: CGPreflightListenEventAccess() ? .granted : .missing,
            posting: CGPreflightPostEventAccess() ? .granted : .missing,
            accessibility: AXIsProcessTrusted() ? .granted : .missing
        )
    }

    func requestListeningAccess() -> InputPermissionSnapshot {
        _ = CGRequestListenEventAccess()
        return snapshot()
    }

    func requestRemapAccess() -> InputPermissionSnapshot {
        _ = CGRequestListenEventAccess()
        _ = CGRequestPostEventAccess()
        AXIsProcessTrustedWithOptions([
            accessibilityPromptOption: true
        ] as CFDictionary)
        return snapshot()
    }

    func openListeningSettings() -> Bool {
        NSWorkspace.shared.open(inputMonitoringSettingsURL)
    }
}
