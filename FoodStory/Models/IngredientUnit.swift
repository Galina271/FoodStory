//
//  IngredientUnit.swift
//  FoodStory
//
//  Единицы измерения для ингредиентов: граммы, миллилитры, штуки и т.д.
//

import Foundation

enum IngredientUnit: String, Codable, CaseIterable, Identifiable {
    case gram          // г
    case kilogram      // кг
    case milliliter    // мл
    case liter         // л
    case piece         // шт
    case teaspoon      // ч.л.
    case tablespoon    // ст.л.
    case cup           // стакан
    case toTaste       // по вкусу

    var id: String { rawValue }

    /// Короткое название, которое показываем рядом с количеством: "200 г", "2 шт".
    var short: String {
        switch self {
        case .gram:       return "г"
        case .kilogram:   return "кг"
        case .milliliter: return "мл"
        case .liter:      return "л"
        case .piece:      return "шт"
        case .teaspoon:   return "ч.л."
        case .tablespoon: return "ст.л."
        case .cup:        return "стак."
        case .toTaste:    return "по вкусу"
        }
    }

    /// У «по вкусу» нет числа — это пригодится, чтобы не показывать "0 по вкусу".
    var hasAmount: Bool {
        self != .toTaste
    }
}
