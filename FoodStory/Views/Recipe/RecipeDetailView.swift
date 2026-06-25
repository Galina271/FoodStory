import SwiftUI

struct RecipeDetailView: View {

    let recipe: Recipe

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                Text(recipe.title)
                    .font(.largeTitle)
                    .bold()

                Text(recipe.recipeDescription)
                    .foregroundStyle(.secondary)

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

                Text("Пока нет ингредиентов")

                Divider()

                Text("Шаги приготовления")
                    .font(.title2)
                    .bold()

                Text("Пока нет шагов")
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RecipeDetailView(
        recipe: Recipe(
            title: "Карбонара",
            recipeDescription: "Тестовый рецепт",
            servings: 2,
            cookTimeMinutes: 25,
            difficulty: .medium
        )
    )
}
