import Foundation

nonisolated struct MouseButtonID: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    let rawValue: Int64

    var description: String {
        "\(rawValue)"
    }
}

nonisolated enum MouseButtonPhase: String, Codable, Sendable {
    case down
    case up
}

nonisolated struct MouseLocation: Equatable, Codable, Sendable {
    let x: Double
    let y: Double
}

nonisolated struct MouseButtonEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let button: MouseButtonID
    let phase: MouseButtonPhase
    let uptimeNanoseconds: UInt64
    let location: MouseLocation

    init(
        id: UUID = UUID(),
        button: MouseButtonID,
        phase: MouseButtonPhase,
        uptimeNanoseconds: UInt64,
        location: MouseLocation
    ) {
        self.id = id
        self.button = button
        self.phase = phase
        self.uptimeNanoseconds = uptimeNanoseconds
        self.location = location
    }
}

nonisolated enum SideButtonAction: Equatable, Sendable {
    case back
    case forward
}

nonisolated struct SideButtonRemapDecision: Equatable, Sendable {
    let shouldConsumeOriginalEvent: Bool
    let action: SideButtonAction?
}
