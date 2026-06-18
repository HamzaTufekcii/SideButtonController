/// Routes a side-button action to the right mechanism for the frontmost app.
///
/// Most apps (browsers, Finder, Preview…) navigate via the discrete swipe gesture,
/// which produces no beep and needs no per-app configuration. A few apps — notably
/// Spotify — ignore the navigation swipe and only respond to their keyboard shortcut,
/// so those are routed to the keyboard dispatcher instead.
nonisolated struct CompositeNavigationActionDispatcher: SideButtonActionDispatching {
    private let frontmostApplicationProvider: any FrontmostApplicationProviding
    private let keyboardRoutedBundleIdentifiers: Set<String>
    private let keyboardDispatcher: any SideButtonActionDispatching
    private let gestureDispatcher: any SideButtonActionDispatching

    init(
        frontmostApplicationProvider: any FrontmostApplicationProviding,
        keyboardRoutedBundleIdentifiers: Set<String>,
        keyboardDispatcher: any SideButtonActionDispatching,
        gestureDispatcher: any SideButtonActionDispatching
    ) {
        self.frontmostApplicationProvider = frontmostApplicationProvider
        self.keyboardRoutedBundleIdentifiers = keyboardRoutedBundleIdentifiers
        self.keyboardDispatcher = keyboardDispatcher
        self.gestureDispatcher = gestureDispatcher
    }

    func dispatch(_ action: SideButtonAction) throws {
        let application = frontmostApplicationProvider.frontmostApplication()

        if let bundleIdentifier = application.bundleIdentifier,
           keyboardRoutedBundleIdentifiers.contains(bundleIdentifier) {
            try keyboardDispatcher.dispatch(action)
        } else {
            try gestureDispatcher.dispatch(action)
        }
    }
}
