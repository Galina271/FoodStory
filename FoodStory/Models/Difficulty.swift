//
//  Difficulty.swift
//  FoodStory
//
//  Сложность приготовления. Это `enum` — тип с заранее перечисленными вариантами.
//  У рецепта может быть ровно одно из трёх значений: лёгкий, средний или сложный.
//

import SwiftUI

/// `String` после имени означает, что каждый вариант хранится как строка ("easy" и т.д.).
/// Это важно для SwiftData — он умеет сохранять такие enum'ы в базу.
/// `Codable` — значит, значение можно сохранять/загружать.
/// `CaseIterable` — даёт нам список всех вариантов через `Difficulty.allCases` (удобно для пикеров).
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    /// `Identifiable` требует свойство `id`. Берём само значение как идентификатор.
    var id: String { rawValue }

    /// Человекочитаемое название на русском — то, что увидит пользователь.
    var title: String {
        switch self {
        case .easy:   return "Лёгкий"
        case .medium: return "Средний"
        case .hard:   return "Сложный"
        }
    }

    /// Подберём каждому уровню свой цвет — зелёный/оранжевый/красный.
    var color: Color {
        switch self {
        case .easy:   return Theme.green
        case .medium: return Theme.accent
        case .hard:   return Theme.tomato
        }
    }

    /// Иконка из набора SF Symbols (встроенные иконки Apple).
    var icon: String {
        switch self {
        case .easy:   return "leaf"
        case .medium: return "flame"
        case .hard:   return "flame.fill"
        }
    }
}
