//
//  CookingSession.swift
//  FoodStory
//
//  «Сессия готовки» — это объект, который помнит, на каком шаге мы сейчас находимся,
//  какие шаги уже отмечены выполненными и сколько секунд осталось на таймере.
//
//  В отличие от Recipe/Ingredient/Step это НЕ @Model: сессию мы не сохраняем в базу,
//  она живёт только пока открыт экран готовки. Для этого подходит @Observable —
//  это значит «когда внутри что-то меняется, экран автоматически перерисовывается».
//

import Foundation
import Observation
import UserNotifications   // локальные уведомления (работают, даже если приложение свернуто)
import AudioToolbox        // системный звук
#if canImport(UIKit)
import UIKit               // вибрация-отклик
#endif

@Observable
final class CookingSession {
    let recipe: Recipe
    let steps: [Step]

    var currentIndex: Int = 0           // индекс текущего шага (с нуля)
    var completedSteps: Set<Int> = []   // номера выполненных шагов
    var remainingSeconds: Int = 0       // сколько осталось на таймере
    var isTimerRunning: Bool = false    // идёт ли отсчёт

    // timer держим отдельно, чтобы уметь его останавливать
    @ObservationIgnored private var timer: Timer?

    // Идентификатор запланированного уведомления — по нему его можно отменить.
    @ObservationIgnored private let notificationID = UUID().uuidString

    init(recipe: Recipe) {
        self.recipe = recipe
        self.steps = recipe.sortedSteps
    }

    // MARK: - Навигация по шагам

    var currentStep: Step? {
        guard steps.indices.contains(currentIndex) else { return nil }
        return steps[currentIndex]
    }

    var isLastStep: Bool {
        currentIndex >= steps.count - 1
    }

    /// Доля прогресса от 0 до 1 — для полоски прогресса вверху экрана.
    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(steps.count)
    }

    func goNext() {
        stopTimer()
        if currentIndex < steps.count - 1 {
            currentIndex += 1
        }
    }

    func goBack() {
        stopTimer()
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    func toggleCompleted() {
        if completedSteps.contains(currentIndex) {
            completedSteps.remove(currentIndex)
        } else {
            completedSteps.insert(currentIndex)
        }
    }

    var isCurrentCompleted: Bool {
        completedSteps.contains(currentIndex)
    }

    // MARK: - Таймер

    func startTimer() {
        guard let seconds = currentStep?.timerSeconds, seconds > 0 else { return }
        remainingSeconds = seconds
        isTimerRunning = true
        timer?.invalidate()
        // Планируем уведомление на момент окончания — оно сработает, даже если
        // приложение свёрнуто (тогда обычный Timer «засыпает»).
        scheduleNotification(after: seconds)
        // Каждую секунду уменьшаем счётчик на 1.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.timerFinished()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        cancelNotification()   // таймер остановлен вручную — уведомление не нужно
    }

    // Таймер доиграл до конца, когда приложение открыто: звук + вибрация.
    private func timerFinished() {
        stopTimer()   // остановит и отменит запланированное уведомление (звук дадим сами)
        playAlert()
    }

    private func playAlert() {
        AudioServicesPlaySystemSound(1005)   // короткий системный звук
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    // MARK: - Локальные уведомления

    /// Спросить разрешение на уведомления (вызываем при входе в режим готовки).
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(after seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Таймер готов ⏰"
        content.body = currentStep.map { "«\(recipe.title)» — \($0.text)" } ?? "Пора к следующему шагу!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    /// Таймер в формате "04:35".
    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
