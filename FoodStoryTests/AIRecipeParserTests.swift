//
//  AIRecipeParserTests.swift
//  FoodStoryTests
//
//  Проверяем разбор текста рецепта от нейросети в структуру Recipe:
//  название, ингредиенты (с количеством), шаги (без номеров).
//

import Testing
@testable import FoodStory

struct AIRecipeParserTests {

    private let sample = """
    **Омлет с сыром и помидорами**

    **Ингредиенты:**
    * яйца — 3 штуки;
    * сыр — 50 г;
    * помидоры — 1 штука;
    * соль, перец — по вкусу;

    **Пошаговые шаги:**
    1. Взбейте яйца в глубокой миске.
    2. Добавьте тёртый сыр.
    3. Жарьте 5–7 минут.
    """

    @Test func parsesTitleIngredientsAndSteps() {
        let recipe = AIRecipeParser.recipe(from: sample)
        #expect(recipe.title == "Омлет с сыром и помидорами")
        #expect(recipe.ingredients.count == 4)
        #expect(recipe.steps.count == 3)
    }

    @Test func parsesAmountAndUnit() {
        let recipe = AIRecipeParser.recipe(from: sample)
        let eggs = recipe.ingredients.first { $0.name == "яйца" }
        #expect(eggs != nil)
        #expect(eggs?.amount == 3)
        #expect(eggs?.unit == .piece)

        let cheese = recipe.ingredients.first { $0.name == "сыр" }
        #expect(cheese?.amount == 50)
        #expect(cheese?.unit == .gram)
    }

    @Test func stepsAreNumberedAndClean() {
        let recipe = AIRecipeParser.recipe(from: sample)
        #expect(recipe.steps.first?.order == 1)
        #expect(recipe.steps.first?.text == "Взбейте яйца в глубокой миске.")
    }

    @Test func fallbackKeepsTextWhenUnstructured() {
        // Без разделов — весь текст уходит в описание, ничего не теряется.
        let recipe = AIRecipeParser.recipe(from: "Просто идея без структуры")
        #expect(recipe.summary.contains("Просто идея"))
    }
}
