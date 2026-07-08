//
//  CookResultSheet.swift
//  FoodStory
//
//  Экран после готовки: «Как получилось?». Пользователь ставит оценку (звёзды)
//  и при желании оставляет заметку. Оценка сохраняется в рецепт и заодно кормит
//  модель вкуса (высокая оценка = блюдо понравилось).
//
//  onDone вызывается в конце — им родительский экран готовки закрывает себя.
//

import SwiftUI
import SwiftData

struct CookResultSheet: View {
    let recipe: Recipe
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(TasteModel.self) private var taste

    @State private var rating = 0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metric.padding) {

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.green)
                        .padding(.top)

                    Text("Готово! Как получилось?")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)

                    // Звёзды 1..5.
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title)
                                .foregroundStyle(star <= rating ? Theme.accent : Theme.textSecondary)
                                .onTapGesture { rating = star }
                        }
                    }

                    // Заметка.
                    TextField("Заметка (например: «в следующий раз меньше соли»)",
                              text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(10)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))

                    Button {
                        finish()
                    } label: {
                        Text("Сохранить")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
                    }
                }
                .padding(Metric.padding)
            }
            .background(Theme.background)
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Пропустить") { finish() }
                }
            }
        }
    }

    // Сохраняем результат готовки и обучаем модель вкуса.
    private func finish() {
        recipe.cookedCount += 1
        if rating > 0 { recipe.rating = rating }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { recipe.notes = trimmed }
        try? context.save()

        // Без оценки считаем, что блюдо понравилось (её всё-таки приготовили).
        // С оценкой: 4–5 звёзд — лайк, 1–2 — дизлайк, 3 — не трогаем модель.
        if rating == 0 || rating >= 4 {
            taste.train(on: recipe, liked: true)
        } else if rating <= 2 {
            taste.train(on: recipe, liked: false)
        }

        dismiss()
        onDone()   // закрываем и сам экран готовки
    }
}

#Preview {
    CookResultSheet(recipe: SampleData.recipes()[0]) { }
        .environment(TasteModel())
}
