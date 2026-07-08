//
//  RecipeSuggesting.swift
//  FoodStory
//
//  «Помощник по рецептам» — задел под будущего AI-агента.
//
//  Идея: экран помощника не знает, КТО именно придумывает рецепт. Он общается
//  с «поставщиком идей» через протокол RecipeSuggesting. Сегодня это простая
//  заглушка (StubRecipeSuggester) без интернета; завтра мы подставим настоящий
//  Claude (ClaudeRecipeSuggester) — и экран менять не придётся.
//
//  Это называется «программирование через протокол»: договариваемся об интерфейсе,
//  а конкретную реализацию выбираем отдельно.
//

import Foundation

/// Единый интерфейс «поставщика идей рецептов».
protocol RecipeSuggesting {
    /// По списку продуктов и пожеланию возвращает текст с идеей рецепта.
    func suggestRecipe(fromProducts products: [String], note: String) async throws -> String
}

/// Заглушка: работает без интернета и без ключей. Нужна, чтобы экран помощника
/// был живым уже сейчас, пока не подключён настоящий AI.
struct StubRecipeSuggester: RecipeSuggesting {
    func suggestRecipe(fromProducts products: [String], note: String) async throws -> String {
        // Небольшая пауза, чтобы визуально было похоже на «думает».
        try? await Task.sleep(nanoseconds: 600_000_000)

        let productsText = products.isEmpty
            ? "тех продуктов, что есть под рукой"
            : products.joined(separator: ", ")

        let wish = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let wishLine = wish.isEmpty ? "" : "\nУчитываю пожелание: «\(wish)»."

        return """
        Идея на основе \(productsText):\(wishLine)

        Попробуйте быстрое блюдо — обжарьте основные продукты на среднем огне,
        добавьте специи по вкусу и подавайте горячим. Готовится за 15–20 минут.

        💡 Это демо-режим помощника. Когда подключим Claude AI, здесь будут
        настоящие, подробные рецепты, подобранные именно под ваши продукты.
        """
    }
}
