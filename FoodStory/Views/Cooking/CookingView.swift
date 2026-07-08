import SwiftUI
import SwiftData

struct CookingView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss

    // @State здесь, потому что сессию создаём и держим, пока открыт этот экран.
    @State private var session: CookingSession

    // Открыт ли лист «рецепт целиком».
    @State private var showingFullRecipe = false

    // Открыт ли экран оценки после готовки.
    @State private var showingResult = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _session = State(initialValue: CookingSession(recipe: recipe))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Metric.padding) {
                topBar
                progressBar

                Spacer()

                if let step = session.currentStep {
                    stepContent(step)
                } else {
                    Text("В этом рецепте пока нет шагов.")
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()
                navigationButtons
            }
            .padding(Metric.padding)
        }
        // Не давать экрану гаснуть во время готовки.
        // #if os(iOS) — этот код компилируется только под iPhone/iPad,
        // потому что UIApplication есть не на всех платформах (на macOS его нет).
        .onAppear {
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            // Спросим разрешение на уведомления — чтобы таймер оповестил даже в фоне.
            CookingSession.requestNotificationPermission()
        }
        .onDisappear {
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        // Лист с полным рецептом — можно открыть в любой момент готовки.
        .sheet(isPresented: $showingFullRecipe) {
            RecipeOverviewSheet(recipe: recipe)
        }
        // Экран оценки после готовки. Когда он завершится — закрываем режим готовки.
        .sheet(isPresented: $showingResult) {
            CookResultSheet(recipe: recipe) { dismiss() }
        }
    }

    // Верхняя строка: счётчик шагов, кнопка «рецепт целиком» и крестик «закрыть».
    private var topBar: some View {
        HStack(spacing: Metric.spacing) {
            Text("Шаг \(session.currentIndex + 1) из \(session.steps.count)")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            // Показать весь рецепт (ингредиенты + все шаги).
            Button {
                showingFullRecipe = true
            } label: {
                Label("Рецепт", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
            }
            Button {
                session.stopTimer()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // Полоска прогресса.
    private var progressBar: some View {
        ProgressView(value: session.progress)
            .tint(Theme.accent)
    }

    // Содержимое текущего шага: текст, галочка «готово», таймер.
    private func stepContent(_ step: Step) -> some View {
        VStack(spacing: Metric.padding) {
            Text(step.text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal)

            // Кнопка «выполнено».
            Button {
                session.toggleCompleted()
            } label: {
                Label(
                    session.isCurrentCompleted ? "Выполнено" : "Отметить выполненным",
                    systemImage: session.isCurrentCompleted ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(session.isCurrentCompleted ? Theme.green : Theme.textSecondary)
            }

            // Блок таймера показываем только если у шага он есть.
            if step.hasTimer {
                timerBlock
            }
        }
    }

    // Таймер: большие цифры + кнопка «старт/стоп».
    private var timerBlock: some View {
        VStack(spacing: Metric.spacing) {
            Text(session.isTimerRunning ? session.remainingText : (session.currentStep?.timerText ?? ""))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)

            Button {
                if session.isTimerRunning {
                    session.stopTimer()
                } else {
                    session.startTimer()
                }
            } label: {
                Label(
                    session.isTimerRunning ? "Стоп" : "Запустить таймер",
                    systemImage: session.isTimerRunning ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // Кнопки «Назад» / «Далее» (или «Готово» на последнем шаге).
    private var navigationButtons: some View {
        HStack(spacing: Metric.spacing) {
            Button {
                session.goBack()
            } label: {
                Label("Назад", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.chip)
                    .foregroundStyle(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
            }
            .disabled(session.currentIndex == 0)
            .opacity(session.currentIndex == 0 ? 0.5 : 1)

            if session.isLastStep {
                Button {
                    session.stopTimer()
                    showingResult = true   // спросим оценку, затем закроем готовку
                } label: {
                    Label("Готово", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
                }
            } else {
                Button {
                    session.goNext()
                } label: {
                    Label("Далее", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
                }
            }
        }
    }

}

#Preview {
    CookingView(recipe: SampleData.recipes()[0])
        .environment(TasteModel())
}
