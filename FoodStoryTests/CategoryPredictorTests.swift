//
//  CategoryPredictorTests.swift
//  FoodStoryTests
//
//  Проверяем запасной определитель категории по ключевым словам
//  (KeywordCategoryPredictor). Он работает всегда, без Core ML модели,
//  поэтому его поведение должно быть предсказуемым.
//

import Testing
@testable import FoodStory

struct CategoryPredictorTests {

    private let predictor = KeywordCategoryPredictor()

    @Test func detectsSoup() {
        #expect(predictor.predictCategory(title: "Борщ", ingredients: ["свёкла"]) == .soup)
    }

    @Test func detectsDessert() {
        #expect(predictor.predictCategory(title: "Шоколадный торт", ingredients: []) == .dessert)
    }

    @Test func detectsMainByIngredients() {
        #expect(predictor.predictCategory(title: "Ужин", ingredients: ["паста", "бекон"]) == .main)
    }

    @Test func detectsBaking() {
        #expect(predictor.predictCategory(title: "Домашний хлеб", ingredients: ["мука", "дрожжи"]) == .baking)
    }

    @Test func emptyInputReturnsNil() {
        #expect(predictor.predictCategory(title: "", ingredients: []) == nil)
    }

    @Test func unknownDishReturnsNil() {
        #expect(predictor.predictCategory(title: "Загадка", ingredients: ["нечто"]) == nil)
    }
}
