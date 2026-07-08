//
//  CategoryPredicting.swift
//  FoodStory
//
//  «Определитель категории» блюда по названию и ингредиентам.
//
//  Как и с AI-помощником, экран не знает, КТО определяет категорию — он общается
//  через протокол CategoryPredicting. Есть две реализации:
//    • CoreMLCategoryPredictor — настоящая Core ML модель (обучена в Create ML);
//    • KeywordCategoryPredictor — простой запасной вариант на ключевых словах,
//      если модель почему-то не загрузилась.
//  Фабрика CategoryPredictorFactory сама выбирает лучшее из доступного.
//

import Foundation

/// Общий интерфейс: по названию и ингредиентам вернуть категорию (или nil).
protocol CategoryPredicting {
    func predictCategory(title: String, ingredients: [String]) -> RecipeCategory?
}

/// Фабрика: берём Core ML модель, если она есть в приложении; иначе — ключевые слова.
enum CategoryPredictorFactory {
    static func make() -> CategoryPredicting {
        CoreMLCategoryPredictor() ?? KeywordCategoryPredictor()
    }
}

/// Запасной вариант без машинного обучения — по простым ключевым словам.
/// Он гарантирует, что функция работает всегда, даже без Core ML модели.
struct KeywordCategoryPredictor: CategoryPredicting {

    // Для каждой категории — набор слов-подсказок.
    private let keywords: [(RecipeCategory, [String])] = [
        (.soup,      ["суп", "борщ", "бульон", "харчо", "солянка", "крем-суп"]),
        (.salad,     ["салат", "цезарь", "оливье", "винегрет", "греческий"]),
        (.dessert,   ["торт", "десерт", "чизкейк", "тирамису", "брауни", "мороженое", "фондан", "крем"]),
        (.baking,    ["хлеб", "пирог", "булочк", "кекс", "печенье", "пицца", "тесто", "круассан", "фокачча"]),
        (.drink,     ["смузи", "коктейль", "лимонад", "компот", "морс", "какао", "латте", "глинтвейн", "напиток"]),
        (.breakfast, ["омлет", "овсянк", "блин", "яичниц", "сырники", "каша", "гранола", "завтрак", "тост"]),
        (.main,      ["паста", "плов", "котлет", "стейк", "ризотто", "лазанья", "гуляш", "жаркое"]),
    ]

    func predictCategory(title: String, ingredients: [String]) -> RecipeCategory? {
        let text = ([title] + ingredients).joined(separator: " ").lowercased()
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        for (category, words) in keywords {
            if words.contains(where: { text.contains($0) }) {
                return category
            }
        }
        return nil   // ничего не подошло — пусть пользователь выберет сам
    }
}
