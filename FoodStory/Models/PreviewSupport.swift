//
//  PreviewSupport.swift
//  FoodStory
//
//  Готовый контейнер базы данных С ПРИМЕРАМИ — только для предпросмотра в Xcode.
//  Чтобы в каждом #Preview не повторять одно и то же, описываем здесь один раз
//  и пишем `.modelContainer(previewContainer)`.
//
//  inMemory: true означает «база живёт в памяти и не сохраняется на диск» —
//  идеально для превью: ничего лишнего не остаётся.
//

import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    let container = try! ModelContainer(
        for: Recipe.self, Ingredient.self, Step.self, ShoppingItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for recipe in SampleData.recipes() {
        container.mainContext.insert(recipe)
    }
    return container
}()
