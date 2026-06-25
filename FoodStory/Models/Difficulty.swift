import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
}

extension Difficulty {
    var title: String {
        switch self {
        case .easy:
            return "Легко ★☆☆"
        case .medium:
            return "Средне ★★☆"
        case .hard:
            return "Сложно ★★★"
        }
    }
}
