//
//  FoodStoryTests.swift
//  FoodStoryTests
//
//  Здесь пишутся юнит-тесты (проверки логики). Пока один пример-заглушка.
//

import Testing
@testable import FoodStory

struct FoodStoryTests {

    @Test func recipeCookingTimeFormatsCorrectly() async throws {
        let recipe = Recipe(title: "Тест", cookingMinutes: 75)
        // 75 минут должно показываться как "1 ч 15 мин".
        #expect(recipe.cookingTimeText == "1 ч 15 мин")
    }
}
