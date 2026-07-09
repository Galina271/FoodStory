//
//  LocalRecipeAssistant.swift
//  FoodStory
//
//  Рабочий офлайн-помощник по рецептам. Он НЕ использует интернет и ключи —
//  вместо этого умно подбирает из ТВОИХ рецептов лучшие варианты под запрос:
//   • совпадение с продуктами, которые есть под рукой;
//   • твой вкусовой профиль (модель вкуса);
//   • простые пожелания из текста: «быстро», «без мяса», категория блюда.
//
//  Возвращает список подсказок с понятной причиной, почему предложено именно это.
//  (Генерацию совсем новых рецептов через Claude оставили на потом — задел в
//   RecipeSuggesting/ClaudeRecipeSuggester.)
//

import Foundation

/// Одна подсказка помощника.
struct AssistantSuggestion: Identifiable {
    let id = UUID()
    let recipe: Recipe?    // конкретный рецепт (если подобрали из имеющихся)
    let title: String
    let reason: String     // почему предложено
}

enum LocalRecipeAssistant {

    /// Главная функция: по продуктам и пожеланию вернуть до `limit` подсказок.
    static func suggest(products: [String],
                        note: String,
                        recipes: [Recipe],
                        taste: TasteModel,
                        limit: Int = 4) -> [AssistantSuggestion] {

        let loweredProducts = products
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let noteLower = note.lowercased()

        // Разбираем пожелание.
        let wantQuick = noteLower.contains("быстр")
        let vegetarian = noteLower.contains("без мяс") || noteLower.contains("вегетар") || noteLower.contains("постн")
        let desiredCategory = detectCategory(in: noteLower)

        // Если рецептов совсем нет — даём общий совет.
        guard !recipes.isEmpty else {
            return [fallback(products: loweredProducts)]
        }

        // 1. Отбираем кандидатов (жёстко — только вегетарианство и явную категорию).
        var candidates = recipes
        if vegetarian {
            candidates = candidates.filter { isVegetarian($0) }
        }
        if let category = desiredCategory, candidates.contains(where: { $0.category == category }) {
            candidates = candidates.filter { $0.category == category }
        }
        if candidates.isEmpty { candidates = recipes }   // не смогли — не оставляем пусто

        // 2. Считаем оценку каждому кандидату.
        let scored = candidates.map { recipe -> (recipe: Recipe, score: Double, matches: Int) in
            let matches = matchCount(recipe, products: loweredProducts)
            var score = Double(matches) * 2.0 + taste.score(for: recipe)
            if wantQuick { score += recipe.cookingMinutes <= 20 ? 1.0 : -0.3 }
            return (recipe, score, matches)
        }
        .sorted { $0.score > $1.score }

        // 3. Собираем подсказки с причинами.
        let top = scored.prefix(limit).map { item in
            AssistantSuggestion(
                recipe: item.recipe,
                title: item.recipe.title,
                reason: reason(for: item.recipe, matches: item.matches,
                               taste: taste, wantQuick: wantQuick, desiredCategory: desiredCategory)
            )
        }
        return top.isEmpty ? [fallback(products: loweredProducts)] : Array(top)
    }

    // MARK: - Вспомогательные

    // Сколько продуктов пользователя встречается в ингредиентах рецепта.
    private static func matchCount(_ recipe: Recipe, products: [String]) -> Int {
        guard !products.isEmpty else { return 0 }
        return recipe.ingredients.filter { ingredient in
            let name = ingredient.name.lowercased()
            return products.contains { name.contains($0) }
        }.count
    }

    // Есть ли в рецепте мясо/рыба (для «без мяса»).
    private static func isVegetarian(_ recipe: Recipe) -> Bool {
        let meatWords = ["мясо", "куриц", "говядин", "свинин", "фарш", "бекон",
                         "колбас", "ветчин", "индейк", "рыб", "тунец", "лосос", "креветк"]
        return !recipe.ingredients.contains { ingredient in
            let name = ingredient.name.lowercased()
            return meatWords.contains { name.contains($0) }
        }
    }

    // Определяем желаемую категорию по словам в пожелании.
    private static func detectCategory(in note: String) -> RecipeCategory? {
        let map: [(words: [String], category: RecipeCategory)] = [
            (["завтрак"], .breakfast),
            (["суп", "борщ", "бульон"], .soup),
            (["салат"], .salad),
            (["десерт", "сладк", "торт", "пирожн"], .dessert),
            (["выпечк", "пирог", "хлеб", "булочк"], .baking),
            (["напиток", "смузи", "коктейль", "компот"], .drink),
            (["обед", "ужин", "горяч", "второе", "основн"], .main),
        ]
        for entry in map where entry.words.contains(where: { note.contains($0) }) {
            return entry.category
        }
        return nil
    }

    // Человекочитаемая причина, почему рецепт предложен.
    private static func reason(for recipe: Recipe, matches: Int, taste: TasteModel,
                               wantQuick: Bool, desiredCategory: RecipeCategory?) -> String {
        var parts: [String] = []
        if matches > 0 {
            parts.append("совпадений: \(matches) из \(recipe.ingredients.count)")
        }
        if taste.score(for: recipe) > 0.15 {
            parts.append("похоже на ваш вкус")
        }
        if wantQuick && recipe.cookingMinutes <= 20 {
            parts.append("быстро — \(recipe.cookingTimeText)")
        }
        if let category = desiredCategory, recipe.category == category {
            parts.append(category.title.lowercased())
        }
        if parts.isEmpty {
            parts.append("\(recipe.category.title.lowercased()) · \(recipe.cookingTimeText)")
        }
        // Первая буква — заглавная.
        let text = parts.joined(separator: " · ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    // Запасной общий совет, если рецептов нет или ничего не подошло.
    private static func fallback(products: [String]) -> AssistantSuggestion {
        let productsText = products.isEmpty ? "того, что есть под рукой" : products.joined(separator: ", ")
        return AssistantSuggestion(
            recipe: nil,
            title: "Быстрая идея",
            reason: "Из \(productsText) можно сделать простое блюдо: обжарьте основное на среднем огне, добавьте специи по вкусу и подавайте горячим. Добавьте больше своих рецептов — и подсказки станут точнее."
        )
    }
}
