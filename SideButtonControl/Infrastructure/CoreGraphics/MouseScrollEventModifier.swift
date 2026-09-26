import CoreGraphics
import Foundation

/// Pure utility that determines whether a scroll event originated from a physical mouse wheel
/// (as opposed to a trackpad or continuous touch surface) and inverts its scroll deltas.
nonisolated struct MouseScrollEventModifier: Sendable {
    /// Inspects the given `CGEvent`. If `reverseScroll` is true and the event is confirmed to be
    /// from a discrete physical mouse wheel, inverts the vertical scroll deltas in-place.
    ///
    /// - Parameters:
    ///   - event: The `CGEvent` of type `.scrollWheel`.
    ///   - reverseScroll: Whether mouse scroll reversal is enabled.
    /// - Returns: `true` if the event was a physical mouse wheel and its deltas were inverted, `false` otherwise.
    @discardableResult
    static func processScrollWheel(event: CGEvent, reverseScroll: Bool) -> Bool {
        guard reverseScroll else {
            return false
        }

        // Differentiate physical wheel mouse from trackpad / smooth touch surfaces:
        // 1. Trackpad gestures are continuous (pixel-based): scrollWheelEventIsContinuous != 0
        // 2. Trackpad gestures report scroll phases (Began, Changed, Ended): scrollPhase != 0
        // 3. Trackpad gestures report momentum phases: momentumPhase != 0
        // Standard physical mouse wheels have isContinuous == 0, scrollPhase == 0, momentumPhase == 0.
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)

        guard !isContinuous && scrollPhase == 0 && momentumPhase == 0 else {
            return false
        }

        // Invert vertical scroll deltas:
        let delta1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let pointDelta1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let fixedPtDelta1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)

        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta1)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDelta1)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedPtDelta1)

        return true
    }
}
