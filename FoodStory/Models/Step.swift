import Foundation
import SwiftData

@Model
final class Step {
    var id: UUID
    var order: Int
    var stepDescription: String
    var imagePath: String?
    var timerSeconds: Int?
    var isCompleted: Bool
    
    @Relationship(inverse: \Recipe.steps)
    var recipe: Recipe?
    
    @Relationship
    var progress: [StepProgress]

    init(
        id: UUID = UUID(),
        order: Int,
        stepDescription: String,
        imagePath: String? = nil,
        timerSeconds: Int? = nil,
        isCompleted: Bool = false,
        progress: [StepProgress] = []
    ) {
        self.id = id
        self.order = order
        self.stepDescription = stepDescription
        self.imagePath = imagePath
        self.timerSeconds = timerSeconds
        self.isCompleted = isCompleted
        self.progress = progress
    }
}
