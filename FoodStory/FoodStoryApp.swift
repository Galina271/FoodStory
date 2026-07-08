//
//  FoodStoryApp.swift
//  FoodStory
//
//  Это «точка входа» — с этого файла приложение начинает работу.
//  Значок @main говорит системе: «запускай отсюда».
//

import SwiftUI
import SwiftData

@main
struct FoodStoryApp: App {

    // Создаём «контейнер» базы данных — он хранит все наши модели.
    // Перечисляем, какие @Model-типы будут сохраняться.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Recipe.self, Ingredient.self, Step.self, ShoppingItem.self)
        } catch {
            // Если базу создать не удалось — приложению дальше работать нельзя.
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // При запуске проверяем: если рецептов ещё нет —
                    // добавляем тестовые, чтобы экран не был пустым.
                    await seedIfNeeded()
                }
        }
        // Передаём контейнер всему приложению, чтобы любой экран мог читать/писать данные.
        .modelContainer(container)
    }

    /// Заполняем базу примерами только при самом первом запуске.
    @MainActor
    private func seedIfNeeded() async {
        let context = container.mainContext
        // Считаем, сколько рецептов уже в базе.
        let descriptor = FetchDescriptor<Recipe>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }   // уже есть данные — ничего не делаем

        for recipe in SampleData.recipes() {
            context.insert(recipe)
        }
        try? context.save()
    }
}
