import SwiftUI

struct RecipeDetailView: View {

    let recipe: Recipe

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Заголовок
                Text(recipe.title)
                    .font(.largeTitle)
                    .bold()

                Text(recipe.recipeDescription)
                    .foregroundStyle(.secondary)

                // MARK: - Метаданные
                HStack {

                    Label(
                        "\(recipe.cookTimeMinutes) мин",
                        systemImage: "clock"
                    )

                    Spacer()

                    Label(
                        "\(recipe.servings)",
                        systemImage: "person.2"
                    )
                }

                Text(recipe.difficulty.title)

                Divider()

                Text("Ингредиенты")
                    .font(.title2)
                    .bold()

                if recipe.ingredients.isEmpty {

                    Text("Пока нет ингредиентов")
                        .foregroundStyle(.secondary)

                } else {

                    VStack(alignment: .leading, spacing: 8) {

                        ForEach(recipe.ingredients) { ingredient in

                            HStack {

                                Text("• \(ingredient.name)")

                                Spacer()

                                Text("\(formatAmount(ingredient.amount)) \(ingredient.unit.title)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                Text("Шаги приготовления")
                    .font(.title2)
                    .bold()

                Button {

                    // Пока пусто

                } label: {

                    Label("Начать готовить", systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatAmount(_ amount: Double) -> String {

        if amount == floor(amount) {
            return String(Int(amount))
        }

        return String(amount)
    }
}

#Preview {
    RecipeDetailView(
        recipe: Recipe(
            title: "Карбонара",
            recipeDescription: "Тестовый рецепт",
            servings: 2,
            cookTimeMinutes: 25,
            difficulty: .medium,
            ingredients: [
                Ingredient(name: "Спагетти", amount: 200, unit: .gram),
                Ingredient(name: "Яйца", amount: 2, unit: .piece)
            ]
        )
    )
}
