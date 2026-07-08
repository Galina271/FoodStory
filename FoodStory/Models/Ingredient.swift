//
//  Ingredient.swift
//  FoodStory
//
//  Один ингредиент рецепта: название, количество, единица измерения.
//
//  ВАЖНО про SwiftData:
//  Аннотация @Model превращает обычный класс в «сохраняемый» — SwiftData сам
//  заведёт под него таблицу в базе данных на телефоне. Тебе не нужно писать SQL.
//  (В твоём первоначальном плане было «локальное хранение (SQLite)» — SwiftData
//  как раз и есть современная надстройка над SQLite от Apple.)
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    // Свойства модели — это «колонки» в таблице.
    var name: String
    var amount: Double
    var unit: IngredientUnit

    init(name: String, amount: Double, unit: IngredientUnit) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }

    /// Готовая строка для показа, например "200 г" или "Соль — по вкусу".
    /// Вычисляемое свойство (computed) — оно не хранится, а собирается на лету.
    var displayAmount: String {
        guard unit.hasAmount else { return unit.short }
        // Если число целое (2.0) — покажем "2", иначе "2.5".
        let number = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(amount)
        return "\(number) \(unit.short)"
    }

    /// Количество, пересчитанное под другое число порций.
    /// Например, при factor = 2 (порций стало вдвое больше) «200 г» станет «400 г».
    /// У «по вкусу» количества нет — возвращаем как есть.
    func scaledDisplayAmount(_ factor: Double) -> String {
        guard unit.hasAmount else { return unit.short }
        let scaled = amount * factor
        // Целое показываем без дробей ("400 г"), иначе — с одним знаком ("2.5 ст.л.").
        let number = scaled.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(scaled))
            : String(format: "%.1f", scaled)
        return "\(number) \(unit.short)"
    }
}
