
import Foundation
import Observation

@Observable
final class TasteModel {

    private(set) var affinities: [String: Double] = [:]
    private(set) var trainedCount: Int = 0
    private let learningRate = 0.3

    @ObservationIgnored
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("taste_model.json")
        load()
    }

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

    private func timeBucket(_ minutes: Int) -> String {
        if minutes <= 15 { return "quick" }
        if minutes <= 40 { return "medium" }
        return "long"
    }

    func score(for recipe: Recipe) -> Double {
        let keys = features(for: recipe)
        guard !keys.isEmpty else { return 0 }
        let sum = keys.reduce(0.0) { $0 + (affinities[$1] ?? 0) }
        return sum / Double(keys.count)
    }

    func verdict(for recipe: Recipe) -> String {
        let s = score(for: recipe)
        if s > 0.15 { return "вам понравится" }
        if s < -0.15 { return "возможно, не ваше" }
        return "нейтрально"
    }

    func train(on recipe: Recipe, liked: Bool) {
        let target = liked ? 1.0 : -1.0
        for key in features(for: recipe) {
            let old = affinities[key] ?? 0
            affinities[key] = old + learningRate * (target - old)
        }
        trainedCount += 1
        save()
    }

    func ranked(_ recipes: [Recipe]) -> [Recipe] {
        recipes.sorted { score(for: $0) > score(for: $1) }
    }

    func recommendations(from recipes: [Recipe], limit: Int = 3) -> [Recipe] {
        Array(ranked(recipes).prefix(limit))
    }

    var isTrained: Bool { trainedCount > 0 }

    func categoryAffinities() -> [(category: RecipeCategory, value: Double)] {
        RecipeCategory.allCases
            .map { (category: $0, value: affinities["cat:\($0.rawValue)"] ?? 0) }
            .sorted { $0.value > $1.value }
    }

    func topIngredients(limit: Int = 5) -> [(name: String, value: Double)] {
        affinities
            .filter { $0.key.hasPrefix("ing:") && $0.value > 0 }
            .map { (name: String($0.key.dropFirst(4)), value: $0.value) }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0 }
    }

    func reset() {
        affinities = [:]
        trainedCount = 0
        save()
    }

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
