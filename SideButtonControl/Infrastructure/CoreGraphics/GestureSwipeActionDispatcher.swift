import CoreGraphics

/// Dispatches side-button actions as discrete navigation swipe gestures instead of
/// keyboard shortcuts. A swipe with nowhere to go is silently ignored by the system,
/// so there is no "unhandled shortcut" beep at history boundaries or on the desktop,
/// and it works system-wide without a per-app routing list.
nonisolated struct GestureSwipeActionDispatcher: SideButtonActionDispatching {
    func dispatch(_ action: SideButtonAction) throws {
        switch action {
        case .back:
            _ = SBCPostNavigationSwipe(SBCNavigationSwipeLeft)
        case .forward:
            _ = SBCPostNavigationSwipe(SBCNavigationSwipeRight)
        }
    }
}
