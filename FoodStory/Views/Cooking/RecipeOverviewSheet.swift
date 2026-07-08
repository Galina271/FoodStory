//
//  RecipeOverviewSheet.swift
//  FoodStory
//
//  «Рецепт целиком» — лист, который можно открыть прямо во время готовки, чтобы
//  быстро свериться со всеми ингредиентами и всеми шагами сразу (а не только с
//  текущим шагом). Открывается по кнопке в режиме готовки.
//
//  Это самостоятельный экран только для чтения: ничего не меняет, просто красиво
//  показывает рецомент. Кнопка «Закрыть» возвращает обратно к готовке.
//

import SwiftUI

struct RecipeOverviewSheet: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metric.padding) {

                    // Фото/заглушка сверху.
                    RecipeImageView(recipe: recipe, iconSize: 48, showsCategoryBadge: true)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))

                    if !recipe.summary.isEmpty {
                        Text(recipe.summary)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Мета: время, порции, сложность.
                    HStack(spacing: Metric.spacing) {
                        metaPill(icon: "clock", text: recipe.cookingTimeText)
                        metaPill(icon: "person.2", text: "\(recipe.servings) порц.")
                        metaPill(icon: recipe.difficulty.icon,
                                 text: recipe.difficulty.title,
                                 color: recipe.difficulty.color)
                    }

                    // Ингредиенты.
                    VStack(alignment: .leading, spacing: Metric.spacing) {
                        Text("Ингредиенты")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(ingredient.displayAmount)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(Metric.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    // Все шаги приготовления.
                    VStack(alignment: .leading, spacing: Metric.spacing) {
                        Text("Приготовление")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(recipe.sortedSteps) { step in
                            HStack(alignment: .top, spacing: Metric.spacing) {
                                Text("\(step.order)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Theme.accent)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.text)
                                        .foregroundStyle(Theme.textPrimary)
                                    if step.hasTimer {
                                        Label(step.timerText, systemImage: "timer")
                                            .font(.caption)
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Metric.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
                .padding(Metric.padding)
            }
            .background(Theme.background)
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func metaPill(icon: String, text: String, color: Color = Theme.accent) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metric.spacing)
        .cardStyle()
    }
}

#Preview {
    RecipeOverviewSheet(recipe: SampleData.recipes()[0])
}
