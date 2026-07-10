//
//  RecipeCardView.swift
//  FoodStory
//
//  Карточка одного рецепта. Один раз описываем, как она выглядит, —
//  и переиспользуем в списке, на главной, в результатах поиска.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Фото рецепта (или красивая заглушка по категории) с бейджем категории.
            RecipeImageView(recipe: recipe, iconSize: 42, showsCategoryBadge: true)
                .frame(height: 150)
                // Сердечко избранного в углу, если рецепт отмечен.
                .overlay(alignment: .topTrailing) {
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.35), in: Circle())
                            .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                // Метаданные: время + сложность (с иконкой).
                HStack(spacing: 12) {
                    Label(recipe.cookingTimeText, systemImage: "clock")
                        .foregroundStyle(Theme.textSecondary)
                    Label(recipe.difficulty.title, systemImage: recipe.difficulty.icon)
                        .foregroundStyle(recipe.difficulty.color)
                }
                .font(.caption)
            }
            .padding(Metric.padding)
        }
        .cardStyle()   // наш модификатор из AppTheme: белый фон + скругление + тень
    }
}

#Preview {
    // Создаём один рецепт прямо в превью, чтобы посмотреть карточку.
    RecipeCardView(recipe: SampleData.recipes()[0])
        .padding()
        .background(Theme.background)
}
