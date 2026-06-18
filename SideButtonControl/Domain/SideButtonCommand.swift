/// A user-assignable function for a mouse side button.
///
/// Today the only commands are navigation, but this is the extension point: new cases
/// (e.g. a keyboard shortcut, launching an app, a system action) get added here and the
/// executors/UI updated to handle them.
nonisolated enum SideButtonCommand: Equatable, Hashable, Sendable, Codable {
    /// No remap — the original button event passes through untouched.
    case none
    case navigateBack
    case navigateForward

    /// Commands offered to the user in pickers. Listed explicitly (rather than via
    /// `CaseIterable`) so future cases with associated values stay compatible.
    static let selectableCases: [SideButtonCommand] = [.none, .navigateBack, .navigateForward]

    /// The navigation action this command performs, if any.
    var navigationAction: SideButtonAction? {
        switch self {
        case .navigateBack:
            .back
        case .navigateForward:
            .forward
        case .none:
            nil
        }
    }

    /// Whether the original mouse-button event should be swallowed when this is bound.
    var consumesOriginalEvent: Bool {
        self != .none
    }
}
