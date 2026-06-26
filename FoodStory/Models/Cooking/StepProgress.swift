import Foundation
import SwiftData

@Model
final class StepProgress {

    var id: UUID

    var isCompleted: Bool

    var completedAt: Date?

    @Relationship(inverse: \CookingSession.stepProgress)
    var cookingSession: CookingSession?

    @Relationship
    var step: Step?

    init(
        id: UUID = UUID(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        step: Step? = nil
    ) {
        self.id = id
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.step = step
    }
}
