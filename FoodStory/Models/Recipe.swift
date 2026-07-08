//
//  Recipe.swift
//  FoodStory
//
//  Главная модель — Рецепт. Она связана с ингредиентами и шагами.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var summary: String
    var difficulty: Difficulty
    var category: RecipeCategory = RecipeCategory.other   // тип блюда (для заглушки-картинки и фильтров)
    var cookingMinutes: Int
    var servings: Int              // количество порций
    var isFavorite: Bool           // в избранном ли рецепт
    var createdAt: Date            // когда создан (для сортировки «по дате»)
    var cookedCount: Int = 0       // сколько раз готовили (для «популярного»)
    var rating: Int = 0            // последняя оценка после готовки (0 = не оценено, 1..5)
    var notes: String = ""         // заметка после готовки («получилось / солоновато»)

    // Фото блюда, которое пользователь выбрал из галереи или снял камерой.
    // Храним как «сырые байты» (Data) прямо в базе. Если фото нет (nil) —
    // рисуем красивую заглушку по категории. @Attribute(.externalStorage)
    // подсказывает SwiftData хранить большие данные (фото) в отдельном файле,
    // а не раздувать саму базу — так приложение остаётся быстрым.
    @Attribute(.externalStorage) var imageData: Data?

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade)
    var steps: [Step]

    init(
        title: String,
        summary: String = "",
        difficulty: Difficulty = .easy,
        category: RecipeCategory = .other,
        cookingMinutes: Int = 30,
        servings: Int = 2,
        isFavorite: Bool = false,
        imageData: Data? = nil,
        ingredients: [Ingredient] = [],
        steps: [Step] = []
    ) {
        self.title = title
        self.summary = summary
        self.difficulty = difficulty
        self.category = category
        self.cookingMinutes = cookingMinutes
        self.servings = servings
        self.isFavorite = isFavorite
        self.imageData = imageData
        self.createdAt = Date()
        self.cookedCount = 0
        self.ingredients = ingredients
        self.steps = steps
    }

    var sortedSteps: [Step] {
        steps.sorted { $0.order < $1.order }
    }

    var cookingTimeText: String {
        if cookingMinutes >= 60 {
            let hours = cookingMinutes / 60
            let minutes = cookingMinutes % 60
            return minutes == 0 ? "\(hours) ч" : "\(hours) ч \(minutes) мин"
        }
        return "\(cookingMinutes) мин"
    }
}
