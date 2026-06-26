import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var title: String
    var recipeDescription: String
    var servings: Int
    var cookTimeMinutes: Int
    var difficulty: Difficulty
    var imagePath: String?
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade)
    var steps: [Step]
    
    @Relationship(deleteRule: .cascade)
    var cookingSessions: [CookingSession]

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        recipeDescription: String = "",
        servings: Int,
        cookTimeMinutes: Int,
        difficulty: Difficulty,
        imagePath: String? = nil,
        ingredients: [Ingredient] = [],
        steps: [Step] = [],
        cookingSessions: [CookingSession] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.recipeDescription = recipeDescription
        self.servings = servings
        self.cookTimeMinutes = cookTimeMinutes
        self.difficulty = difficulty
        self.imagePath = imagePath
        self.ingredients = ingredients
        self.steps = steps
        self.cookingSessions = cookingSessions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
