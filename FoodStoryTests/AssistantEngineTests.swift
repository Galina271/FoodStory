//
//  AssistantEngineTests.swift
//  FoodStoryTests
//
//  Проверяем офлайн-помощника: подбор по продуктам, исключение мяса
//  и фильтр по категории. Логика чистая, поэтому легко тестируется.
//

import Testing
import Foundation
@testable import FoodStory

struct AssistantEngineTests {

    // Свежая (необученная) модель вкуса на временном файле.
    private func freshTaste() -> TasteModel {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("assist_\(UUID().uuidString).json")
        return TasteModel(fileURL: url)
    }

    @Test func productMatchSurfacesRelevantRecipe() {
        let recipes = SampleData.recipes()   // Карбонара, Овсянка, Фондан
        let result = LocalRecipeAssistant.suggest(
            products: ["яйца"], note: "", recipes: recipes, taste: freshTaste()
        )
        // Первым должен идти рецепт, где яйца действительно есть.
        let firstIngredients = result.first?.recipe?.ingredients.map { $0.name.lowercased() } ?? []
        #expect(firstIngredients.contains { $0.contains("яйца") })
    }

    @Test func vegetarianExcludesMeat() {
        let recipes = SampleData.recipes()
        let result = LocalRecipeAssistant.suggest(
            products: [], note: "без мяса", recipes: recipes, taste: freshTaste()
        )
        // Карбонара с беконом не должна попасть в подсказки.
        #expect(!result.contains { $0.recipe?.title == "Паста Карбонара" })
    }

    @Test func categoryFilterKeepsOnlyThatCategory() {
        let recipes = SampleData.recipes()
        let result = LocalRecipeAssistant.suggest(
            products: [], note: "хочу десерт", recipes: recipes, taste: freshTaste()
        )
        let withRecipe = result.compactMap { $0.recipe }
        #expect(!withRecipe.isEmpty)
        #expect(withRecipe.allSatisfy { $0.category == .dessert })
    }

    @Test func noRecipesGivesFallbackIdea() {
        let result = LocalRecipeAssistant.suggest(
            products: ["рис"], note: "", recipes: [], taste: freshTaste()
        )
        #expect(result.count == 1)
        #expect(result.first?.recipe == nil)   // общий совет, а не конкретный рецепт
    }
}
