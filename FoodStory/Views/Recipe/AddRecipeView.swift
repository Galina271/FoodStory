import SwiftUI
import SwiftData

struct AddRecipeView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var recipeDescription = ""

    @State private var servings = 1
    @State private var cookTimeMinutes = 30

    @State private var difficulty: Difficulty = .easy

    var body: some View {
        NavigationStack {
            Form {

                Section("Основная информация") {

                    TextField("Название рецепта", text: $title)

                    TextField("Описание", text: $recipeDescription)

                    Stepper(
                        "Порции: \(servings)",
                        value: $servings,
                        in: 1...20
                    )

                    Stepper(
                        "Время: \(cookTimeMinutes) мин",
                        value: $cookTimeMinutes,
                        in: 1...1440
                    )

                    Picker("Сложность", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.title)
                                .tag(difficulty)
                        }
                    }
                }
            }
            .navigationTitle("Новый рецепт")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        saveRecipe()
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }

    private func saveRecipe() {

        let recipe = Recipe(
            title: title,
            recipeDescription: recipeDescription,
            servings: servings,
            cookTimeMinutes: cookTimeMinutes,
            difficulty: difficulty
        )

        modelContext.insert(recipe)

        dismiss()
    }
}

#Preview {
    AddRecipeView()
}
