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

    @State private var ingredients: [Ingredient] = []

    @State private var isShowingAddIngredient = false

    var body: some View {

        NavigationStack {

            Form {

                // MARK: - Основная информация

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

                Section("Ингредиенты") {

                    if ingredients.isEmpty {

                        ContentUnavailableView(
                            "Пока нет ингредиентов",
                            systemImage: "carrot"
                        )

                    } else {

                        ForEach(ingredients) { ingredient in

                            HStack {

                                Text(ingredient.name)

                                Spacer()

                                Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.title)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteIngredient)
                    }

                    Button {

                        isShowingAddIngredient = true

                    } label: {

                        Label(
                            "Добавить ингредиент",
                            systemImage: "plus.circle.fill"
                        )
                    }
                }
            }
            .navigationTitle("Новый рецепт")
            .navigationBarTitleDisplayMode(.inline)

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

            .sheet(isPresented: $isShowingAddIngredient) {

                AddIngredientSheet { ingredient in

                    ingredients.append(ingredient)
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
            difficulty: difficulty,
            ingredients: ingredients
        )

        modelContext.insert(recipe)

        dismiss()
    }

    private func deleteIngredient(at offsets: IndexSet) {

        ingredients.remove(atOffsets: offsets)
    }

    private func formatAmount(_ amount: Double) -> String {

        if amount == floor(amount) {
            return String(Int(amount))
        }

        return String(amount)
    }
}

#Preview {
    AddRecipeView()
}
