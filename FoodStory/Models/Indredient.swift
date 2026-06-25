import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID
    var name: String
    var amount: Double
    var unit: IngredientUnit

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        unit: IngredientUnit
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}
