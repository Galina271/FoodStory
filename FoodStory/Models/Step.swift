import Foundation
import SwiftData

@Model
final class Step {
    var id: UUID
    var order: Int
    var stepDescription: String
    var imagePath: String?
    var timerSeconds: Int?

    init(
        id: UUID = UUID(),
        order: Int,
        stepDescription: String,
        imagePath: String? = nil,
        timerSeconds: Int? = nil
    ) {
        self.id = id
        self.order = order
        self.stepDescription = stepDescription
        self.imagePath = imagePath
        self.timerSeconds = timerSeconds
    }
}
