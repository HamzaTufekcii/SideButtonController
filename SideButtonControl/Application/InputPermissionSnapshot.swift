nonisolated enum InputPermissionState: Equatable, Sendable {
    case unknown
    case granted
    case missing

    var isGranted: Bool {
        self == .granted
    }
}

nonisolated struct InputPermissionSnapshot: Equatable, Sendable {
    let accessibility: InputPermissionState

    static let unknown = InputPermissionSnapshot(
        accessibility: .unknown
    )

    var canRemap: Bool {
        accessibility.isGranted
    }
}
