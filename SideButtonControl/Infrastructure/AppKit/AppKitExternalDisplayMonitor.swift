import AppKit
import CoreGraphics

@MainActor
final class AppKitExternalDisplayMonitor: ExternalDisplayMonitoring {
    private var observer: NSObjectProtocol?
    private var onChange: ((ExternalDisplaySnapshot) -> Void)?
    private var lastSnapshot: ExternalDisplaySnapshot?

    func currentSnapshot() -> ExternalDisplaySnapshot {
        ExternalDisplaySnapshot(hasExternalDisplay: Self.hasExternalDisplay())
    }

    func start(onChange: @escaping @MainActor (ExternalDisplaySnapshot) -> Void) {
        self.onChange = onChange

        if observer == nil {
            observer = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.emitIfChanged()
                }
            }
        }

        emitIfChanged(force: true)
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        onChange = nil
        lastSnapshot = nil
    }

    private func emitIfChanged(force: Bool = false) {
        let snapshot = currentSnapshot()
        guard force || snapshot != lastSnapshot else {
            return
        }

        lastSnapshot = snapshot
        onChange?(snapshot)
    }

    private static func hasExternalDisplay() -> Bool {
        NSScreen.screens.contains { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }

            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            return CGDisplayIsBuiltin(displayID) == 0
        }
    }
}
