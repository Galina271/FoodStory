import Foundation

enum IngredientUnit: String, Codable, CaseIterable {
    case gram
    case kilogram
    case milliliter
    case liter
    case piece
    case teaspoon
    case tablespoon
    case toTaste
    case pinch
    case clove
}

extension IngredientUnit {
    var title: String {
        switch self {
        case .gram:
            return "г"
        case .kilogram:
            return "кг"
        case .milliliter:
            return "мл"
        case .liter:
            return "л"
        case .piece:
            return "шт"
        case .teaspoon:
            return "ч.л."
        case .tablespoon:
            return "ст.л."
        case .toTaste:
            return "по вкусу"
        case .pinch:
            return "щепотка"

        case .clove:
            return "зубчик"
        }
    }
}
