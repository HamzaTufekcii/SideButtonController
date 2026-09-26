import AppKit
import CoreGraphics

private let displayReconfigurationCallback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
    guard let userInfo = userInfo else { return }
    if flags.contains(.beginConfigurationFlag) {
        return
    }
    let monitor = Unmanaged<AppKitExternalDisplayMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    DispatchQueue.main.async {
        monitor.emitIfChanged()
    }
}

@MainActor
final class AppKitExternalDisplayMonitor: ExternalDisplayMonitoring {
    private var onChange: ((ExternalDisplaySnapshot) -> Void)?
    private var lastSnapshot: ExternalDisplaySnapshot?
    private var activityToken: NSObjectProtocol?
    private var isRegistered = false
    private var observer: NSObjectProtocol?

    func currentSnapshot() -> ExternalDisplaySnapshot {
        ExternalDisplaySnapshot(hasExternalDisplay: Self.hasExternalDisplay())
    }

    func start(onChange: @escaping @MainActor (ExternalDisplaySnapshot) -> Void) {
        self.onChange = onChange

        if activityToken == nil {
            activityToken = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiated, .latencyCritical],
                reason: "Monitoring external display connection changes"
            )
        }

        if !isRegistered {
            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            let status = CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, selfPointer)
            if status == .success {
                isRegistered = true
            } else {
                registerNotificationObserver()
            }
        }

        emitIfChanged(force: true)
    }

    private func registerNotificationObserver() {
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
    }

    func stop() {
        if isRegistered {
            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, selfPointer)
            isRegistered = false
        }

        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }

        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }

        onChange = nil
        lastSnapshot = nil
    }

    fileprivate func emitIfChanged(force: Bool = false) {
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

