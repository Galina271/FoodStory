//
//  TasteModelTests.swift
//  FoodStoryTests
//
//  Проверяем обучаемую «модель вкуса»: что обучение двигает оценки в нужную
//  сторону, рекомендации сортируются правильно, сброс всё обнуляет, а обучение
//  сохраняется на диск и загружается обратно.
//

import Testing
import Foundation
@testable import FoodStory

struct TasteModelTests {

    // Каждому тесту — свой временный файл, чтобы тесты не мешали друг другу
    // и не трогали реальные данные приложения.
    private func makeModel() -> TasteModel {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("taste_test_\(UUID().uuidString).json")
        return TasteModel(fileURL: url)
    }

    private func dessert() -> Recipe {
        Recipe(title: "Шоколадный торт", category: .dessert,
               ingredients: [Ingredient(name: "шоколад", amount: 100, unit: .gram)])
    }

    private func soup() -> Recipe {
        Recipe(title: "Борщ", category: .soup,
               ingredients: [Ingredient(name: "свёкла", amount: 2, unit: .piece)])
    }

    @Test func untrainedModelScoresZero() {
        let model = makeModel()
        #expect(model.score(for: dessert()) == 0)
        #expect(model.isTrained == false)
        #expect(model.trainedCount == 0)
    }

    @Test func likeIncreasesScore() {
        let model = makeModel()
        let cake = dessert()
        let before = model.score(for: cake)
        model.train(on: cake, liked: true)
        #expect(model.score(for: cake) > before)
        #expect(model.isTrained == true)
        #expect(model.trainedCount == 1)
    }

    @Test func dislikeDecreasesScore() {
        let model = makeModel()
        let cake = dessert()
        model.train(on: cake, liked: false)
        #expect(model.score(for: cake) < 0)
    }

    @Test func likedCategoryOutranksOther() {
        let model = makeModel()
        model.train(on: dessert(), liked: true)
        // После лайка десерта другой десерт должен цениться выше супа.
        let anotherDessert = Recipe(title: "Брауни", category: .dessert,
                                    ingredients: [Ingredient(name: "какао", amount: 50, unit: .gram)])
        #expect(model.score(for: anotherDessert) > model.score(for: soup()))
    }

    @Test func recommendationsAreSortedByScore() {
        let model = makeModel()
        model.train(on: dessert(), liked: true)
        model.train(on: soup(), liked: false)
        let recs = model.recommendations(from: [soup(), dessert()], limit: 2)
        #expect(recs.first?.category == .dessert)   // любимое — первым
    }

    @Test func resetClearsEverything() {
        let model = makeModel()
        model.train(on: dessert(), liked: true)
        model.reset()
        #expect(model.trainedCount == 0)
        #expect(model.isTrained == false)
        #expect(model.score(for: dessert()) == 0)
    }

    @Test func trainingPersistsAcrossInstances() {
        // Обучаем одну модель, затем создаём новую с тем же файлом —
        // она должна «вспомнить» обучение.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("taste_persist_\(UUID().uuidString).json")
        let modelA = TasteModel(fileURL: url)
        modelA.train(on: dessert(), liked: true)
        let savedScore = modelA.score(for: dessert())

        let modelB = TasteModel(fileURL: url)
        #expect(modelB.trainedCount == 1)
        #expect(abs(modelB.score(for: dessert()) - savedScore) < 0.0001)

        try? FileManager.default.removeItem(at: url)
    }
}
