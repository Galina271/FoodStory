import Foundation
import SwiftData

@Model
final class CookingSession {

    var id: UUID

    var startedAt: Date

    var finishedAt: Date?

    var status: CookingSessionStatus

    @Relationship(deleteRule: .cascade)
    var stepProgress: [StepProgress]
    
    @Relationship(inverse: \Recipe.cookingSessions)
    var recipe: Recipe?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        status: CookingSessionStatus = .inProgress,
        stepProgress: [StepProgress] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.status = status
        self.stepProgress = stepProgress
    }
}
