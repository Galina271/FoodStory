import Foundation
import SwiftData

@Model
final class Step {
    var order: Int
    var text: String
    var timerSeconds: Int?

    // Что нужно подготовить ЗАРАНЕЕ для этого шага (например: «достать масло»,
    // «нарезать лук»). Все такие заметки собираются в блок «Подготовка» сверху
    // карточки рецепта. Значение по умолчанию "" — чтобы старые рецепты в базе
    // мигрировали автоматически без потери данных.
    var prep: String = ""

    init(order: Int, text: String, timerSeconds: Int? = nil, prep: String = "") {
        self.order = order
        self.text = text
        self.timerSeconds = timerSeconds
        self.prep = prep
    }

    var hasTimer: Bool {
        if let timerSeconds, timerSeconds > 0 { return true }
        return false
    }
    
    var timerText: String {
        guard let timerSeconds else { return "" }
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
