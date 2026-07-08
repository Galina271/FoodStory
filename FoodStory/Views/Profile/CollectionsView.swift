//
//  CollectionsView.swift
//  FoodStory
//
//  «Коллекции» — рецепты, сгруппированные для удобного просмотра: сначала
//  избранное, затем по категориям (Завтрак, Горячее, Десерт…). Пустые категории
//  не показываем. Открывается из профиля.
//

import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Query private var recipes: [Recipe]

    private var favorites: [Recipe] {
        recipes.filter { $0.isFavorite }
    }

    // Категории, в которых есть хотя бы один рецепт (в порядке из enum).
    private var usedCategories: [RecipeCategory] {
        RecipeCategory.allCases.filter { category in
            recipes.contains { $0.category == category }
        }
    }

    var body: some View {
        List {
            if !favorites.isEmpty {
                Section {
                    ForEach(favorites) { recipe in
                        recipeRow(recipe)
                    }
                } header: {
                    Label("Избранное", systemImage: "heart.fill")
                        .foregroundStyle(Theme.tomato)
                }
            }

            ForEach(usedCategories) { category in
                Section {
                    ForEach(recipes.filter { $0.category == category }) { recipe in
                        recipeRow(recipe)
                    }
                } header: {
                    Label(category.title, systemImage: category.icon)
                }
            }
        }
        .navigationTitle("Коллекции")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "Пока пусто",
                    systemImage: "folder",
                    description: Text("Создайте рецепты — они появятся здесь по категориям.")
                )
            }
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            HStack(spacing: Metric.spacing) {
                RecipeImageView(recipe: recipe, iconSize: 20)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.smallRadius))
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.title)
                        .foregroundStyle(Theme.textPrimary)
                    Text(recipe.cookingTimeText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CollectionsView() }
        .modelContainer(previewContainer)
}
