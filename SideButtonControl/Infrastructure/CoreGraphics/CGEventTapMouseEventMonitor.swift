import CoreGraphics
import Foundation

final class CGEventTapMouseEventMonitor: MouseEventMonitoring {
    private let callbackContext: EventTapCallbackContext
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        bindings: ButtonBindingSet = .standard,
        actionDispatcher: any SideButtonActionDispatching
    ) {
        self.callbackContext = EventTapCallbackContext(
            bindings: bindings,
            actionDispatcher: actionDispatcher
        )
    }

    func setBindings(_ bindings: ButtonBindingSet) {
        callbackContext.setBindings(bindings)
    }

    func makeEventStream() -> AsyncStream<MouseButtonEvent> {
        let context = callbackContext
        return AsyncStream(bufferingPolicy: .bufferingNewest(100)) { continuation in
            context.setContinuation(continuation)
        }
    }

    func start() throws {
        guard eventTap == nil else {
            return
        }

        let eventMask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.otherMouseUp.rawValue)
        let userInfo = Unmanaged.passUnretained(callbackContext).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: sideButtonEventTapCallback,
            userInfo: userInfo
        ) else {
            throw MouseEventMonitorError.eventTapCreationFailed
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            throw MouseEventMonitorError.runLoopSourceCreationFailed
        }

        eventTap = tap
        runLoopSource = source
        callbackContext.setRegisteredTap(tap)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }

        callbackContext.setRegisteredTap(nil)
        runLoopSource = nil
        eventTap = nil
    }

    func setEventsObserved(_ observed: Bool) {
        callbackContext.setObserving(observed)
    }

    deinit {
        callbackContext.finish()
    }
}

// This is the only unchecked Sendable boundary. It is isolated to the
// CoreGraphics C callback bridge and carries callback-only state.
private nonisolated final class EventTapCallbackContext: @unchecked Sendable {
    private let actionDispatcher: any SideButtonActionDispatching
    // Touched only from the main run loop (callback + start/stop + observe toggles + subscribe + bindings).
    private var bindings: ButtonBindingSet
    private var continuation: AsyncStream<MouseButtonEvent>.Continuation?
    private var registeredTap: CFMachPort?
    private var observing = false

    init(
        bindings: ButtonBindingSet,
        actionDispatcher: any SideButtonActionDispatching
    ) {
        self.bindings = bindings
        self.actionDispatcher = actionDispatcher
    }

    func setBindings(_ newBindings: ButtonBindingSet) {
        bindings = newBindings
    }

    var isObserving: Bool {
        observing
    }

    func setObserving(_ value: Bool) {
        observing = value
    }

    func setRegisteredTap(_ tap: CFMachPort?) {
        registeredTap = tap
    }

    func reenableTap() {
        guard let registeredTap else {
            return
        }
        CGEvent.tapEnable(tap: registeredTap, enable: true)
    }

    func setContinuation(_ newContinuation: AsyncStream<MouseButtonEvent>.Continuation) {
        continuation?.finish()
        continuation = newContinuation
    }

    func yield(_ event: MouseButtonEvent) {
        continuation?.yield(event)
    }

    func handle(button: MouseButtonID, phase: MouseButtonPhase) -> Bool {
        let decision = bindings.decision(forButton: button, phase: phase)

        if let action = decision.action {
            try? actionDispatcher.dispatch(action)
        }

        return decision.shouldConsumeOriginalEvent
    }

    func finish() {
        continuation?.finish()
        continuation = nil
    }
}

private nonisolated func sideButtonEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let context = Unmanaged<EventTapCallbackContext>.fromOpaque(userInfo).takeUnretainedValue()

    // The system disables the tap if a callback runs long or after wake from sleep.
    // Re-enable it so remapping keeps working instead of silently dying.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        context.reenableTap()
        return nil
    }

    guard type == .otherMouseDown || type == .otherMouseUp else {
        return Unmanaged.passUnretained(event)
    }

    let button = MouseButtonID(rawValue: event.getIntegerValueField(.mouseEventButtonNumber))
    let phase: MouseButtonPhase = type == .otherMouseDown ? .down : .up
    let shouldConsumeOriginalEvent = context.handle(button: button, phase: phase)

    // Building the diagnostics event (UUID + view strings on the consumer) is pure
    // overhead while the diagnostics window is closed, so only emit when observed.
    if context.isObserving {
        let point = event.location
        context.yield(
            MouseButtonEvent(
                button: button,
                phase: phase,
                uptimeNanoseconds: event.timestamp,
                location: MouseLocation(x: point.x, y: point.y)
            )
        )
    }

    return shouldConsumeOriginalEvent ? nil : Unmanaged.passUnretained(event)
}
