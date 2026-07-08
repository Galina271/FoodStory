//
//  SearchView.swift
//  FoodStory
//
//  Поиск рецептов по названию и по ингредиентам.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Query private var recipes: [Recipe]
    @State private var searchText = ""

    // Отфильтрованные рецепты. Ищем И в названии, И среди ингредиентов.
    private var results: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return recipes }

        return recipes.filter { recipe in
            let inTitle = recipe.title.lowercased().contains(query)
            let inIngredients = recipe.ingredients.contains {
                $0.name.lowercased().contains(query)
            }
            return inTitle || inIngredients
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if results.isEmpty {
                    ContentUnavailableView(
                        "Ничего не найдено",
                        systemImage: "magnifyingglass",
                        description: Text("Попробуйте другое название или ингредиент.")
                    )
                } else {
                    List(results) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(recipe.cookingTimeText + " · " + recipe.difficulty.title)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .listRowBackground(Theme.card)
                    }
                    .scrollContentBackground(.hidden)   // прячем стандартный серый фон списка
                }
            }
            .navigationTitle("Поиск")
            // Встроенная строка поиска SwiftUI.
            .searchable(text: $searchText, prompt: "Название или ингредиент")
        }
        .tint(Theme.accent)
    }
}

#Preview {
    SearchView()
        .modelContainer(previewContainer)
}
