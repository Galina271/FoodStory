//
//  AIRecipeParser.swift
//  FoodStory
//
//  Превращает текст рецепта от нейросети (название, список ингредиентов, шаги)
//  в настоящий Recipe, чтобы его можно было сохранить в свои рецепты.
//
//  Текст от AI приходит «человеческий» (с заголовками «Ингредиенты», «Шаги»,
//  маркерами списка и нумерацией), поэтому разбираем его аккуратно и терпимо к
//  разным форматам. Что не удалось распознать точно — не теряем, а кладём как есть;
//  потом рецепт всегда можно поправить в редакторе.
//

import Foundation

enum AIRecipeParser {

    /// Разбирает текст рецепта в Recipe (ещё не вставленный в базу).
    static func recipe(from text: String) -> Recipe {
        let lines = text.components(separatedBy: .newlines).map { clean($0) }

        // Название — первая непустая строка.
        let title = lines.first(where: { !$0.isEmpty }) ?? "Рецепт от AI"

        var ingredients: [Ingredient] = []
        var steps: [Step] = []
        var section: Section = .none

        for (index, line) in lines.enumerated() {
            if line.isEmpty { continue }
            if index == 0 { continue }   // это название, уже взяли

            let lower = line.lowercased()
            // Переключаемся по заголовкам разделов.
            if lower.contains("ингредиент") { section = .ingredients; continue }
            if lower.contains("пригот") || lower.contains("шаг") { section = .steps; continue }

            switch section {
            case .ingredients:
                if let ingredient = parseIngredient(line) { ingredients.append(ingredient) }
            case .steps:
                let stepText = stripLeadingNumber(line)
                if !stepText.isEmpty { steps.append(Step(order: steps.count + 1, text: stepText)) }
            case .none:
                break
            }
        }

        // Если структуру распознать не удалось — сохраняем весь текст в описание,
        // чтобы ничего не потерялось.
        let summary = (ingredients.isEmpty && steps.isEmpty) ? text : ""

        // Категорию угадываем нашим определителем (Core ML или ключевые слова).
        let category = CategoryPredictorFactory.make()
            .predictCategory(title: title, ingredients: ingredients.map { $0.name }) ?? .other

        return Recipe(
            title: title.isEmpty ? "Рецепт от AI" : title,
            summary: summary,
            category: category,
            ingredients: ingredients,
            steps: steps
        )
    }

    private enum Section { case none, ingredients, steps }

    // MARK: - Разбор строк

    // Убираем markdown (**, #) и маркеры списка по краям.
    private static func clean(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespaces)
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "#", with: "")
        for prefix in ["* ", "- ", "• ", "– ", "— "] {
            if t.hasPrefix(prefix) { t = String(t.dropFirst(prefix.count)) }
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    // "1. текст" или "1) текст" → "текст".
    private static func stripLeadingNumber(_ s: String) -> String {
        if let r = s.range(of: #"^\d+[.)]\s*"#, options: .regularExpression) {
            return String(s[r.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return s
    }

    // "яйца — 3 штуки" → name="яйца", amount=3, unit=.piece.
    private static func parseIngredient(_ line: String) -> Ingredient? {
        var t = line.trimmingCharacters(in: .whitespaces)
        while let last = t.last, last == ";" || last == "." { t = String(t.dropLast()) }
        if t.isEmpty { return nil }

        for sep in [" — ", " – ", " - ", ": "] {
            if let range = t.range(of: sep) {
                let name = String(t[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let amountPart = String(t[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if let (amount, unit) = parseAmount(amountPart) {
                    return Ingredient(name: name, amount: amount, unit: unit)
                }
                // Количество не распозналось (например, «по вкусу») — оставляем имя.
                return Ingredient(name: name, amount: 0, unit: .toTaste)
            }
        }
        // Разделителя нет — вся строка как название.
        return Ingredient(name: t, amount: 0, unit: .toTaste)
    }

    // "3 штуки" → (3, .piece); "50 г" → (50, .gram).
    private static func parseAmount(_ s: String) -> (Double, IngredientUnit)? {
        guard let numRange = s.range(of: #"^\d+([.,]\d+)?"#, options: .regularExpression) else { return nil }
        let numStr = String(s[numRange]).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(numStr) else { return nil }
        let rest = s[numRange.upperBound...].lowercased()
        return (value, matchUnit(String(rest)))
    }

    // Слово-единица → наш IngredientUnit. Специфичные проверяем раньше коротких.
    private static func matchUnit(_ s: String) -> IngredientUnit {
        let pairs: [(String, IngredientUnit)] = [
            ("миллилитр", .milliliter), ("мл", .milliliter),
            ("килограмм", .kilogram), ("кг", .kilogram),
            ("столов", .tablespoon), ("ст.л", .tablespoon),
            ("чайн", .teaspoon), ("ч.л", .teaspoon),
            ("стакан", .cup),
            ("штук", .piece), ("шт", .piece),
            ("грамм", .gram),
            ("литр", .liter),
            ("г", .gram),
            ("л", .liter),
        ]
        for (keyword, unit) in pairs where s.contains(keyword) { return unit }
        return .piece   // число есть, но единица непонятна — считаем штуками
    }
}
