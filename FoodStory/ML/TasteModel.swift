//
//  TasteModel.swift
//  FoodStory
//
//  Твоя собственная маленькая обучаемая ИИ-модель — «модель вкуса».
//  Она НЕ нейросеть и НЕ языковая модель: это лёгкая модель, которая учится
//  прямо на телефоне на твоих действиях (что ты добавляешь в избранное и что
//  готовишь) и рекомендует рецепты именно под тебя. Работает офлайн, без
//  интернета и без ключей.
//
//  КАК УСТРОЕНО (три шага):
//   1. Признаки. Каждый рецепт превращаем в набор «признаков»: категория,
//      сложность, время приготовления и ингредиенты. Например:
//      ["cat:dessert", "diff:hard", "time:long", "ing:шоколад", ...].
//   2. Симпатии. Для каждого признака модель хранит число от -1 (не нравится)
//      до +1 (очень нравится). Это и есть «выученные параметры» модели.
//   3. Обучение. Когда ты ставишь лайк рецепту — все его признаки чуть
//      сдвигаются к +1; дизлайк — к -1. Формула одного шага обучения:
//          новая = старая + скорость * (цель - старая)
//      Это классическое «онлайн-обучение»: модель дообучается по одному примеру.
//
//  ОЦЕНКА рецепта = средняя симпатия его признаков (от -1 до +1). Чем выше —
//  тем вероятнее, что блюдо тебе понравится.
//

import Foundation
import Observation

@Observable
final class TasteModel {

    // MARK: - Выученные параметры

    /// Симпатия к каждому признаку, примерно в диапазоне [-1, +1].
    /// Ключ — это признак ("cat:dessert"), значение — насколько он тебе нравится.
    private(set) var affinities: [String: Double] = [:]

    /// Сколько примеров модель уже увидела (для показа «обучена на N примерах»).
    private(set) var trainedCount: Int = 0

    /// Скорость обучения: насколько сильно один пример двигает симпатию.
    /// 0.3 — заметно, но не резко (модель не «забывает» всё от одного клика).
    private let learningRate = 0.3

    // Файл, куда сохраняем модель, чтобы обучение не пропадало между запусками.
    // @ObservationIgnored — за этим полем не нужно «следить» для перерисовки.
    @ObservationIgnored
    private let fileURL: URL

    /// В обычной жизни путь берётся по умолчанию (папка Documents приложения).
    /// В тестах можно передать свой временный файл, чтобы не трогать реальные данные.
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("taste_model.json")
        load()
    }

    // MARK: - Признаки

    /// Превращает рецепт в список признаков (текстовых меток).
    private func features(for recipe: Recipe) -> [String] {
        var result: [String] = []
        result.append("cat:\(recipe.category.rawValue)")
        result.append("diff:\(recipe.difficulty.rawValue)")
        result.append("time:\(timeBucket(recipe.cookingMinutes))")
        for ingredient in recipe.ingredients {
            let name = ingredient.name.lowercased().trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { result.append("ing:\(name)") }
        }
        return result
    }

    /// Делим время на три «корзины», чтобы модель училась на понятных группах.
    private func timeBucket(_ minutes: Int) -> String {
        if minutes <= 15 { return "quick" }
        if minutes <= 40 { return "medium" }
        return "long"
    }

    // MARK: - Оценка (предсказание)

    /// Оценка рецепта от -1 до +1: средняя симпатия его признаков.
    func score(for recipe: Recipe) -> Double {
        let keys = features(for: recipe)
        guard !keys.isEmpty else { return 0 }
        let sum = keys.reduce(0.0) { $0 + (affinities[$1] ?? 0) }
        return sum / Double(keys.count)
    }

    /// Человекочитаемая подпись к оценке — для интерфейса.
    func verdict(for recipe: Recipe) -> String {
        let s = score(for: recipe)
        if s > 0.15 { return "вам понравится" }
        if s < -0.15 { return "возможно, не ваше" }
        return "нейтрально"
    }

    // MARK: - Обучение

    /// Один шаг обучения на одном рецепте.
    /// liked = true  → двигаем признаки к +1 (лайк, готовка);
    /// liked = false → двигаем к -1 (дизлайк, убрали из избранного).
    func train(on recipe: Recipe, liked: Bool) {
        let target = liked ? 1.0 : -1.0
        for key in features(for: recipe) {
            let old = affinities[key] ?? 0
            affinities[key] = old + learningRate * (target - old)
        }
        trainedCount += 1
        save()
    }

    // MARK: - Рекомендации

    /// Рецепты, отсортированные от самых «вкусных» к наименее подходящим.
    func ranked(_ recipes: [Recipe]) -> [Recipe] {
        recipes.sorted { score(for: $0) > score(for: $1) }
    }

    /// Верхние N рекомендаций.
    func recommendations(from recipes: [Recipe], limit: Int = 3) -> [Recipe] {
        Array(ranked(recipes).prefix(limit))
    }

    /// Обучалась ли модель хоть на чём-то (чтобы решать: показывать персональное
    /// или пока случайное).
    var isTrained: Bool { trainedCount > 0 }

    // MARK: - Для экрана «Вкусовой профиль»

    /// Симпатия к каждой категории — чтобы нарисовать полоски предпочтений.
    func categoryAffinities() -> [(category: RecipeCategory, value: Double)] {
        RecipeCategory.allCases
            .map { (category: $0, value: affinities["cat:\($0.rawValue)"] ?? 0) }
            .sorted { $0.value > $1.value }
    }

    /// Любимые ингредиенты (топ по симпатии) — для наглядности.
    func topIngredients(limit: Int = 5) -> [(name: String, value: Double)] {
        affinities
            .filter { $0.key.hasPrefix("ing:") && $0.value > 0 }
            .map { (name: String($0.key.dropFirst(4)), value: $0.value) }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0 }
    }

    /// Полностью забыть обучение (начать с чистого листа).
    func reset() {
        affinities = [:]
        trainedCount = 0
        save()
    }

    // MARK: - Сохранение / загрузка

    // Отдельная Codable-структура: именно её мы пишем в файл.
    private struct SavedState: Codable {
        var affinities: [String: Double]
        var trainedCount: Int
    }

    private func save() {
        let state = SavedState(affinities: affinities, trainedCount: trainedCount)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else {
            return
        }
        affinities = state.affinities
        trainedCount = state.trainedCount
    }
}
