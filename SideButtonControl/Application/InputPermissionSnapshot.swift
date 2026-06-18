nonisolated enum InputPermissionState: Equatable, Sendable {
    case unknown
    case granted
    case missing

    var isGranted: Bool {
        self == .granted
    }
}

nonisolated struct InputPermissionSnapshot: Equatable, Sendable {
    let listening: InputPermissionState
    let posting: InputPermissionState
    let accessibility: InputPermissionState

    static let unknown = InputPermissionSnapshot(
        listening: .unknown,
        posting: .unknown,
        accessibility: .unknown
    )

    var canRemap: Bool {
        listening.isGranted && posting.isGranted && accessibility.isGranted
    }
}
