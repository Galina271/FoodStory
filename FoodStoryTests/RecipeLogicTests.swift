//
//  RecipeLogicTests.swift
//  FoodStoryTests
//
//  Проверяем «чистую» логику моделей: форматирование времени, порядок шагов,
//  копирование рецепта, текст для «Поделиться», отображение количества и
//  справочники (единицы, сложность, категории).
//

import Testing
import Foundation
@testable import FoodStory

struct RecipeLogicTests {

    // MARK: - Recipe

    @Test func cookingTimeFormatting() {
        #expect(Recipe(title: "a", cookingMinutes: 25).cookingTimeText == "25 мин")
        #expect(Recipe(title: "a", cookingMinutes: 60).cookingTimeText == "1 ч")
        #expect(Recipe(title: "a", cookingMinutes: 75).cookingTimeText == "1 ч 15 мин")
        #expect(Recipe(title: "a", cookingMinutes: 120).cookingTimeText == "2 ч")
    }

    @Test func stepsAreSortedByOrder() {
        let recipe = Recipe(title: "a", steps: [
            Step(order: 3, text: "третий"),
            Step(order: 1, text: "первый"),
            Step(order: 2, text: "второй"),
        ])
        #expect(recipe.sortedSteps.map(\.order) == [1, 2, 3])
        #expect(recipe.sortedSteps.first?.text == "первый")
    }

    @Test func makeCopyDuplicatesContent() {
        let original = Recipe(
            title: "Паста",
            category: .main,
            ingredients: [Ingredient(name: "спагетти", amount: 200, unit: .gram)],
            steps: [Step(order: 1, text: "варить")]
        )
        let copy = original.makeCopy()
        #expect(copy.title == "Паста (копия)")
        #expect(copy.ingredients.count == original.ingredients.count)
        #expect(copy.steps.count == original.steps.count)
        #expect(copy.category == .main)
    }

    @Test func shareTextContainsKeyParts() {
        let recipe = Recipe(
            title: "Омлет",
            category: .breakfast,
            ingredients: [Ingredient(name: "яйца", amount: 2, unit: .piece)],
            steps: [Step(order: 1, text: "взбить яйца")]
        )
        let text = recipe.shareText
        #expect(text.contains("Омлет"))
        #expect(text.contains("яйца"))
        #expect(text.contains("взбить яйца"))
    }

    // MARK: - Ingredient / IngredientUnit

    @Test func ingredientDisplayAmount() {
        #expect(Ingredient(name: "мука", amount: 200, unit: .gram).displayAmount == "200 г")
        #expect(Ingredient(name: "соль", amount: 0, unit: .toTaste).displayAmount == "по вкусу")
        #expect(Ingredient(name: "молоко", amount: 1.5, unit: .liter).displayAmount == "1.5 л")
    }

    @Test func unitHasAmountFlag() {
        #expect(IngredientUnit.gram.hasAmount == true)
        #expect(IngredientUnit.toTaste.hasAmount == false)
    }

    @Test func scaledAmountRecalculates() {
        let flour = Ingredient(name: "мука", amount: 200, unit: .gram)
        #expect(flour.scaledDisplayAmount(1) == "200 г")   // без изменений
        #expect(flour.scaledDisplayAmount(2) == "400 г")   // вдвое больше
        #expect(flour.scaledDisplayAmount(0.5) == "100 г") // вдвое меньше
        // «По вкусу» не масштабируется.
        let salt = Ingredient(name: "соль", amount: 0, unit: .toTaste)
        #expect(salt.scaledDisplayAmount(3) == "по вкусу")
    }

    // MARK: - Справочники

    @Test func difficultyTitles() {
        #expect(Difficulty.easy.title == "Лёгкий")
        #expect(Difficulty.medium.title == "Средний")
        #expect(Difficulty.hard.title == "Сложный")
    }

    @Test func categoriesAreComplete() {
        #expect(RecipeCategory.allCases.count == 8)
        // У каждой категории есть непустое название и иконка.
        for category in RecipeCategory.allCases {
            #expect(!category.title.isEmpty)
            #expect(!category.icon.isEmpty)
        }
    }
}
