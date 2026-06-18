import Carbon.HIToolbox
import CoreGraphics

nonisolated enum CGKeyboardShortcutActionDispatchError: Error, Equatable, Sendable {
    case keyboardEventCreationFailed
}

nonisolated enum CGKeyboardShortcutStyle: Equatable, Sendable {
    case commandBracket
    case commandOptionArrow
}

nonisolated struct CGKeyboardShortcutRoutingPolicy: Equatable, Sendable {
    private let commandBracketBundleIdentifiers: Set<String>
    private let commandOptionArrowBundleIdentifiers: Set<String>

    static let standard = CGKeyboardShortcutRoutingPolicy(
        commandBracketBundleIdentifiers: [
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.SafariTechnologyPreview",
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "com.brave.Browser",
            "com.microsoft.edgemac",
            "company.thebrowser.Browser",
            "org.mozilla.firefox",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi"
        ],
        commandOptionArrowBundleIdentifiers: [
            "com.spotify.client"
        ]
    )

    init(
        commandBracketBundleIdentifiers: Set<String>,
        commandOptionArrowBundleIdentifiers: Set<String>
    ) {
        self.commandBracketBundleIdentifiers = commandBracketBundleIdentifiers
        self.commandOptionArrowBundleIdentifiers = commandOptionArrowBundleIdentifiers
    }

    func shortcutStyle(for application: FrontmostApplication) -> CGKeyboardShortcutStyle? {
        guard let bundleIdentifier = application.bundleIdentifier else {
            return nil
        }

        if commandOptionArrowBundleIdentifiers.contains(bundleIdentifier) {
            return .commandOptionArrow
        }

        if commandBracketBundleIdentifiers.contains(bundleIdentifier) {
            return .commandBracket
        }

        return nil
    }
}

nonisolated struct CGKeyboardShortcutActionDispatcher: SideButtonActionDispatching {
    private let frontmostApplicationProvider: any FrontmostApplicationProviding
    private let routingPolicy: CGKeyboardShortcutRoutingPolicy

    init(
        frontmostApplicationProvider: any FrontmostApplicationProviding,
        routingPolicy: CGKeyboardShortcutRoutingPolicy = .standard
    ) {
        self.frontmostApplicationProvider = frontmostApplicationProvider
        self.routingPolicy = routingPolicy
    }

    func dispatch(_ action: SideButtonAction) throws {
        let frontmostApplication = frontmostApplicationProvider.frontmostApplication()
        guard let shortcutStyle = routingPolicy.shortcutStyle(for: frontmostApplication) else {
            return
        }

        let keyCode = keyCode(for: action, style: shortcutStyle)
        let flags = flags(for: shortcutStyle)
        try postKeyboardShortcut(keyCode: keyCode, flags: flags)
    }

    private func keyCode(
        for action: SideButtonAction,
        style: CGKeyboardShortcutStyle
    ) -> CGKeyCode {
        switch (action, style) {
        case (.back, .commandBracket):
            CGKeyCode(kVK_ANSI_LeftBracket)
        case (.forward, .commandBracket):
            CGKeyCode(kVK_ANSI_RightBracket)
        case (.back, .commandOptionArrow):
            CGKeyCode(kVK_LeftArrow)
        case (.forward, .commandOptionArrow):
            CGKeyCode(kVK_RightArrow)
        }
    }

    private func flags(for style: CGKeyboardShortcutStyle) -> CGEventFlags {
        switch style {
        case .commandBracket:
            .maskCommand
        case .commandOptionArrow:
            [.maskCommand, .maskAlternate]
        }
    }

    private func postKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) throws {
        guard
            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        else {
            throw CGKeyboardShortcutActionDispatchError.keyboardEventCreationFailed
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
