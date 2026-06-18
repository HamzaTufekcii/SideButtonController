import SwiftUI

extension SideButtonCommand {
    var displayName: String {
        switch self {
        case .none:
            "Yok"
        case .navigateBack:
            "Geri"
        case .navigateForward:
            "İleri"
        }
    }

    var symbolName: String {
        switch self {
        case .none:
            "circle.slash"
        case .navigateBack:
            "arrow.left"
        case .navigateForward:
            "arrow.right"
        }
    }

    var tint: Color {
        switch self {
        case .none:
            .gray
        case .navigateBack, .navigateForward:
            .accentColor
        }
    }
}
