import Foundation

enum Position: String, Codable {
    case sitting
    case standing

    var label: String {
        switch self {
        case .sitting: "Sitting"
        case .standing: "Standing"
        }
    }

    var sfSymbol: String {
        switch self {
        case .sitting: "figure.seated.side"
        case .standing: "figure.stand"
        }
    }

    var verb: String {
        switch self {
        case .sitting: "Sit"
        case .standing: "Stand"
        }
    }

    var next: Position {
        switch self {
        case .sitting: .standing
        case .standing: .sitting
        }
    }
}
