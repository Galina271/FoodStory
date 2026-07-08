import Foundation
import SwiftData

@Model
final class Step {
    var order: Int
    var text: String
    var timerSeconds: Int?

    init(order: Int, text: String, timerSeconds: Int? = nil) {
        self.order = order
        self.text = text
        self.timerSeconds = timerSeconds
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
