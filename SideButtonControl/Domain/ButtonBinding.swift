/// A single button-to-command assignment.
nonisolated struct ButtonBinding: Equatable, Sendable, Codable, Identifiable {
    let button: MouseButtonID
    var command: SideButtonCommand

    var id: Int64 { button.rawValue }

    init(button: MouseButtonID, command: SideButtonCommand) {
        self.button = button
        self.command = command
    }
}

/// The full set of button assignments. Replaces the old fixed remap policy; the default
/// reproduces the original behaviour (button 3 = Back, button 4 = Forward).
nonisolated struct ButtonBindingSet: Equatable, Sendable, Codable {
    private(set) var bindings: [ButtonBinding]

    static let standard = ButtonBindingSet(bindings: [
        ButtonBinding(button: MouseButtonID(rawValue: 3), command: .navigateBack),
        ButtonBinding(button: MouseButtonID(rawValue: 4), command: .navigateForward)
    ])

    init(bindings: [ButtonBinding]) {
        self.bindings = bindings
    }

    func command(for button: MouseButtonID) -> SideButtonCommand {
        bindings.first(where: { $0.button == button })?.command ?? .none
    }

    mutating func setCommand(_ command: SideButtonCommand, for button: MouseButtonID) {
        if let index = bindings.firstIndex(where: { $0.button == button }) {
            bindings[index].command = command
        } else {
            bindings.append(ButtonBinding(button: button, command: command))
        }
    }

    func decision(forButton button: MouseButtonID, phase: MouseButtonPhase) -> SideButtonRemapDecision {
        let command = command(for: button)
        return SideButtonRemapDecision(
            shouldConsumeOriginalEvent: command.consumesOriginalEvent,
            action: phase == .down ? command.navigationAction : nil
        )
    }
}
