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
    var reverseMouseScroll: Bool

    static let standard = ButtonBindingSet(
        bindings: [
            ButtonBinding(button: MouseButtonID(rawValue: 3), command: .navigateBack),
            ButtonBinding(button: MouseButtonID(rawValue: 4), command: .navigateForward)
        ],
        reverseMouseScroll: true
    )

    init(bindings: [ButtonBinding], reverseMouseScroll: Bool = true) {
        self.bindings = bindings
        self.reverseMouseScroll = reverseMouseScroll
    }

    enum CodingKeys: String, CodingKey {
        case bindings
        case reverseMouseScroll
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bindings = try container.decode([ButtonBinding].self, forKey: .bindings)
        self.reverseMouseScroll = try container.decodeIfPresent(Bool.self, forKey: .reverseMouseScroll) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bindings, forKey: .bindings)
        try container.encode(reverseMouseScroll, forKey: .reverseMouseScroll)
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

    mutating func setReverseMouseScroll(_ enabled: Bool) {
        reverseMouseScroll = enabled
    }

    func decision(forButton button: MouseButtonID, phase: MouseButtonPhase) -> SideButtonRemapDecision {
        let command = command(for: button)
        return SideButtonRemapDecision(
            shouldConsumeOriginalEvent: command.consumesOriginalEvent,
            action: phase == .down ? command.navigationAction : nil
        )
    }
}
