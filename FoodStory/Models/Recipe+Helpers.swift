//
//  Recipe+Helpers.swift
//  FoodStory
//
//  Небольшие удобные операции над рецептом, которые не хочется держать в самой
//  модели: сделать копию рецепта и собрать его в виде обычного текста
//  (для кнопки «Поделиться» и, в будущем, для отправки AI-помощнику).
//
//  Это `extension` — «дополнение» к уже существующему классу Recipe. Так код
//  модели остаётся коротким, а помощники лежат рядом и легко находятся.
//

import Foundation

extension Recipe {

    /// Создаёт независимую копию рецепта (со свежими ингредиентами и шагами).
    /// Новый объект НЕ вставлен в базу — это делает вызывающая сторона.
    func makeCopy() -> Recipe {
        Recipe(
            title: title + " (копия)",
            summary: summary,
            difficulty: difficulty,
            category: category,
            cookingMinutes: cookingMinutes,
            servings: servings,
            imageData: imageData,
            ingredients: ingredients.map {
                Ingredient(name: $0.name, amount: $0.amount, unit: $0.unit)
            },
            steps: sortedSteps.map {
                Step(order: $0.order, text: $0.text, timerSeconds: $0.timerSeconds, prep: $0.prep)
            }
        )
    }

    /// Рецепт в виде простого текста — им можно поделиться или вставить куда угодно.
    var shareText: String {
        var lines: [String] = []
        lines.append(title)
        if !summary.isEmpty { lines.append(summary) }
        lines.append("")
        lines.append("⏱ \(cookingTimeText) · 👤 \(servings) порц. · \(difficulty.title)")
        lines.append("")
        lines.append("Ингредиенты:")
        for ingredient in ingredients {
            lines.append("• \(ingredient.name) — \(ingredient.displayAmount)")
        }
        let prep = sortedSteps
            .map { $0.prep.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !prep.isEmpty {
            lines.append("")
            lines.append("Подготовка:")
            for item in prep {
                lines.append("• \(item)")
            }
        }
        lines.append("")
        lines.append("Приготовление:")
        for step in sortedSteps {
            lines.append("\(step.order). \(step.text)")
        }
        return lines.joined(separator: "\n")
    }
}
