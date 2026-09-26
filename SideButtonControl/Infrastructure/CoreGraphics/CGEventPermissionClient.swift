import ApplicationServices
import AppKit
import CoreGraphics

final class CGEventPermissionClient: InputPermissionChecking, InputPermissionSettingsOpening {
    private let accessibilityPromptOption = "AXTrustedCheckOptionPrompt"
    private let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    func snapshot() -> InputPermissionSnapshot {
        InputPermissionSnapshot(
            accessibility: AXIsProcessTrusted() ? .granted : .missing
        )
    }

    func requestAccess() -> InputPermissionSnapshot {
        AXIsProcessTrustedWithOptions([
            accessibilityPromptOption: true
        ] as CFDictionary)
        return snapshot()
    }

    func openSettings() -> Bool {
        NSWorkspace.shared.open(accessibilitySettingsURL)
    }
}
