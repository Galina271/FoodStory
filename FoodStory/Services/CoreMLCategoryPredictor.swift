//
//  CoreMLCategoryPredictor.swift
//  FoodStory
//
//  Настоящая Core ML модель, которая по тексту рецепта угадывает категорию.
//  Модель обучена заранее в Create ML (см. MLTrainer/TrainCategoryModel.swift) и
//  лежит в приложении как RecipeCategoryClassifier.mlmodel — Xcode компилирует её
//  при сборке. Здесь мы её загружаем и спрашиваем предсказание.
//
//  Загружаем через NLModel из фреймворка NaturalLanguage — он создан как раз для
//  таких текстовых классификаторов и избавляет нас от ручной возни с признаками.
//
//  init? возвращает nil, если модель не найдена/не загрузилась — тогда фабрика
//  сама переключится на запасной KeywordCategoryPredictor, и приложение не сломается.
//

import Foundation
import NaturalLanguage

struct CoreMLCategoryPredictor: CategoryPredicting {
    private let model: NLModel

    init?() {
        // Ищем СКОМПИЛИРОВАННУЮ модель (.mlmodelc) внутри приложения.
        guard let url = Bundle.main.url(forResource: "RecipeCategoryClassifier", withExtension: "mlmodelc"),
              let loaded = try? NLModel(contentsOf: url) else {
            return nil
        }
        self.model = loaded
    }

    func predictCategory(title: String, ingredients: [String]) -> RecipeCategory? {
        let text = ([title] + ingredients).joined(separator: " ").lowercased()
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty,
              let label = model.predictedLabel(for: text) else {
            return nil
        }
        // Модель возвращает строку вроде "dessert" — превращаем её в RecipeCategory.
        return RecipeCategory(rawValue: label)
    }
}
